import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        VStack(spacing: 0) {
            switch appState.scanState {
            case .empty:
                EmptyStateView()

            case .scanning(let itemCount):
                ScanningView(itemCount: itemCount)

            case .loaded:
                // Breadcrumb bar
                BreadcrumbBar()

                // Main area: sunburst + sidebar
                HSplitView {
                    SunburstCanvasView()
                        .frame(minWidth: 500)

                    if appState.showSidebar {
                        SidebarView()
                    }
                }

                // Status bar
                StatusBar()
            }
        }
        .background(Color(red: 0.0, green: 0.169, blue: 0.212))
        .environmentObject(appState)
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFolder)) { _ in
            appState.openFolderPanel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .rescan)) { _ in
            appState.rescan()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateBack)) { _ in
            appState.navigateBack()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateForward)) { _ in
            appState.navigateForward()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            appState.applyZoom(delta: 1.25)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            appState.applyZoom(delta: 0.8)
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetZoom)) { _ in
            appState.resetZoom()
        }
        .onKeyPress(.escape) {
            appState.navigateBack()
            return .handled
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                  isDir.boolValue else { return }
            Task { @MainActor in
                appState.scanFolder(url)
            }
        }
        return true
    }
}
