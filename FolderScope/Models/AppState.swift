import Foundation
import AppKit
import Combine

enum ScanState {
    case empty
    case scanning(itemCount: Int)
    case loaded
}

@MainActor
class AppState: ObservableObject {
    // Scan state
    @Published var scanState: ScanState = .empty
    @Published var rootNode: FolderNode?
    @Published var rootURL: URL?

    // Navigation
    @Published var currentNode: FolderNode?
    @Published var navStack: [FolderNode] = []
    @Published var forwardStack: [FolderNode] = []

    // Interaction
    @Published var hoveredNode: FolderNode?
    @Published var hoveredIsFiles: Bool = false
    @Published var hoveredSegment: SunburstSegment?
    @Published var threshold: Int = 1000

    // Zoom & Pan
    @Published var zoom: CGFloat = 1.0
    @Published var panOffset: CGSize = .zero
    private let zoomSnapThreshold: CGFloat = 0.04
    private let zoomMin: CGFloat = 0.3
    private let zoomMax: CGFloat = 4.0

    func applyZoom(delta: CGFloat) {
        let newZoom = min(max(zoom * delta, zoomMin), zoomMax)
        // Snap to 100% when close
        if abs(newZoom - 1.0) < zoomSnapThreshold {
            zoom = 1.0
        } else {
            zoom = newZoom
        }
    }

    func resetZoom() {
        zoom = 1.0
        panOffset = .zero
    }

    // Animation
    @Published var animProgress: CGFloat = 1.0
    @Published var isAnimating: Bool = false
    private var animTimer: Timer?
    private var animStartTime: Date = .now
    private var animDirection: String = "in"
    private var animCallback: (() -> Void)?
    private let animDuration: TimeInterval = 0.42

    // Sidebar
    @Published var activeTab: String = "top10"
    @Published var showSidebar: Bool = true

    // Stored segments for hit testing (set by canvas after drawing)
    var segments: [SunburstSegment] = []

    let scanner = DirectoryScanner()

    init() {
        restoreLastFolder()
    }

    // MARK: - Folder Selection

    func openFolderPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to visualize"

        if panel.runModal() == .OK, let url = panel.url {
            scanFolder(url)
        }
    }

    func scanFolder(_ url: URL) {
        rootURL = url
        scanState = .scanning(itemCount: 0)
        navStack = []
        forwardStack = []
        hoveredNode = nil
        hoveredSegment = nil
        segments = []
        saveLastFolder(url)

        // Update window title
        if let window = NSApp.windows.first {
            window.title = "FolderScope — \(url.lastPathComponent)"
        }

        Task {
            let node = await scanner.scan(url: url) { count in
                Task { @MainActor in
                    self.scanState = .scanning(itemCount: count)
                }
            }
            node.computeTotals()
            node.assignHues()
            self.rootNode = node
            self.currentNode = node
            self.scanState = .loaded
            self.animateTransition(direction: "in")
        }
    }

    func rescan() {
        guard let url = rootURL else { return }
        scanFolder(url)
    }

    // MARK: - Navigation

    func drillInto(_ node: FolderNode) {
        guard !isAnimating else { return }
        guard !node.children.isEmpty else { return }
        guard let current = currentNode else { return }

        navStack.append(current)
        forwardStack = []
        switchTo(node)
    }

    func navigateBack() {
        guard !isAnimating else { return }
        guard let prev = navStack.popLast() else { return }
        guard let current = currentNode else { return }

        forwardStack.append(current)
        switchTo(prev)
    }

    func navigateForward() {
        guard !isAnimating else { return }
        guard let next = forwardStack.popLast() else { return }
        guard let current = currentNode else { return }

        navStack.append(current)
        switchTo(next)
    }

    func navigateTo(stackIndex: Int) {
        guard !isAnimating else { return }
        let all = navStack + [currentNode!]
        guard stackIndex < all.count - 1 else { return }

        let target = all[stackIndex]
        navStack = Array(all.prefix(stackIndex))
        forwardStack = []
        switchTo(target)
    }

    private func switchTo(_ node: FolderNode) {
        currentNode = node
        node.assignHues()
        hoveredNode = nil
        hoveredSegment = nil
        segments = []
        animateTransition(direction: "in")
    }

    var breadcrumbItems: [(name: String, index: Int)] {
        guard let current = currentNode else { return [] }
        var items: [(String, Int)] = []
        for (i, node) in navStack.enumerated() {
            items.append((node.name, i))
        }
        items.append((current.name, navStack.count))
        return items
    }

    // MARK: - Animation

    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        return 1 - pow(1 - t, 3)
    }

    func animateTransition(direction: String, callback: (() -> Void)? = nil) {
        animTimer?.invalidate()
        isAnimating = true
        animDirection = direction
        animProgress = 0
        animStartTime = .now
        animCallback = callback

        animTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickAnimation()
            }
        }
    }

    private func tickAnimation() {
        let elapsed = Date.now.timeIntervalSince(animStartTime)
        let raw = min(CGFloat(elapsed / animDuration), 1.0)
        animProgress = easeOutCubic(raw)

        if raw >= 1.0 {
            animTimer?.invalidate()
            animTimer = nil
            animProgress = 1.0
            isAnimating = false
            let cb = animCallback
            animCallback = nil
            cb?()
        }
    }

    // MARK: - Persistence

    private func saveLastFolder(_ url: URL) {
        do {
            let bookmark = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: "lastFolderBookmark")
        } catch {
            UserDefaults.standard.set(url.path, forKey: "lastFolderPath")
        }
    }

    private func restoreLastFolder() {
        if let bookmarkData = UserDefaults.standard.data(forKey: "lastFolderBookmark") {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                scanFolder(url)
                return
            }
        }

        if let path = UserDefaults.standard.string(forKey: "lastFolderPath") {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                scanFolder(url)
            }
        }
    }
}
