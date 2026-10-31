import SwiftUI

@main
struct FolderScopeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Folder…") {
                    NotificationCenter.default.post(name: .openFolder, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Rescan") {
                    NotificationCenter.default.post(name: .rescan, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Zoom In") {
                    NotificationCenter.default.post(name: .zoomIn, object: nil)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    NotificationCenter.default.post(name: .zoomOut, object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Zoom") {
                    NotificationCenter.default.post(name: .resetZoom, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button("Navigate Back") {
                    NotificationCenter.default.post(name: .navigateBack, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Navigate Forward") {
                    NotificationCenter.default.post(name: .navigateForward, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension Notification.Name {
    static let openFolder = Notification.Name("openFolder")
    static let rescan = Notification.Name("rescan")
    static let navigateBack = Notification.Name("navigateBack")
    static let navigateForward = Notification.Name("navigateForward")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let resetZoom = Notification.Name("resetZoom")
}
