import SwiftUI

struct BreadcrumbBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            // Back button
            Button(action: { appState.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(appState.navStack.isEmpty ? Color(red: 0.345, green: 0.431, blue: 0.459) : Color(red: 0.165, green: 0.631, blue: 0.596))
            }
            .buttonStyle(.plain)
            .disabled(appState.navStack.isEmpty || appState.isAnimating)

            // Breadcrumb segments
            let items = appState.breadcrumbItems
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                if idx > 0 {
                    Text("›")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.345, green: 0.431, blue: 0.459))
                }

                if idx == items.count - 1 {
                    // Current (non-clickable)
                    Text(item.name)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.933, green: 0.910, blue: 0.835))
                        .lineLimit(1)
                } else {
                    // Clickable ancestor
                    Button(action: { appState.navigateTo(stackIndex: item.index) }) {
                        Text(item.name)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.165, green: 0.631, blue: 0.596))
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }

            Spacer()

            // Actions
            Button(action: { appState.rescan() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.165, green: 0.631, blue: 0.596))
            }
            .buttonStyle(.plain)
            .help("Rescan (Cmd+R)")

            Button(action: { appState.openFolderPanel() }) {
                Image(systemName: "folder")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.165, green: 0.631, blue: 0.596))
            }
            .buttonStyle(.plain)
            .help("Open Folder (Cmd+O)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.027, green: 0.212, blue: 0.259))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color(red: 0.345, green: 0.431, blue: 0.459).opacity(0.3))
        }
    }
}
