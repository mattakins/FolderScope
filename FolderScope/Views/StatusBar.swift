import SwiftUI

struct StatusBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            // Hovered item info
            if let node = appState.hoveredNode {
                HStack(spacing: 8) {
                    Image(systemName: appState.hoveredIsFiles ? "doc.fill" : "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.165, green: 0.631, blue: 0.596))

                    Text(node.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.933, green: 0.910, blue: 0.835))
                        .lineLimit(1)

                    if !appState.hoveredIsFiles {
                        Text("•")
                            .foregroundColor(Color(red: 0.345, green: 0.431, blue: 0.459))
                        Text("\(node.total.formatted()) items")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.514, green: 0.580, blue: 0.588))
                        Text("•")
                            .foregroundColor(Color(red: 0.345, green: 0.431, blue: 0.459))
                        Text("\(node.children.count) subfolders")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.514, green: 0.580, blue: 0.588))
                        Text("•")
                            .foregroundColor(Color(red: 0.345, green: 0.431, blue: 0.459))
                        Text("\(node.files) files")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.514, green: 0.580, blue: 0.588))
                    }
                }
            } else if let node = appState.currentNode {
                Text(node.name)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.396, green: 0.482, blue: 0.514))
                Text("•")
                    .foregroundColor(Color(white: 0.25))
                Text("\(node.total.formatted()) total items")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.396, green: 0.482, blue: 0.514))
            }

            Spacer()

            // Zoom indicator
            if appState.zoom != 1.0 {
                Button(action: { appState.resetZoom() }) {
                    Text("\(Int(appState.zoom * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.165, green: 0.631, blue: 0.596))
                }
                .buttonStyle(.plain)
                .help("Reset to 100% (Cmd+0)")
            }

            // Threshold slider
            HStack(spacing: 8) {
                Text("Threshold:")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.396, green: 0.482, blue: 0.514))

                Slider(value: Binding(
                    get: { Double(appState.threshold) },
                    set: { appState.threshold = Int($0) }
                ), in: 0...5000, step: 50)
                .frame(width: 150)
                .tint(Color(red: 0.796, green: 0.294, blue: 0.086))

                Text("\(appState.threshold.formatted())")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.796, green: 0.294, blue: 0.086))
                    .monospacedDigit()
                    .frame(minWidth: 40, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(red: 0.027, green: 0.212, blue: 0.259))
        .overlay(alignment: .top) {
            Divider().overlay(Color(red: 0.345, green: 0.431, blue: 0.459).opacity(0.3))
        }
    }
}
