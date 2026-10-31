import SwiftUI
import UniformTypeIdentifiers

struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(red: 0.165, green: 0.631, blue: 0.596))

            Text("Select a folder to visualize")
                .font(.title2)
                .foregroundColor(Color(red: 0.933, green: 0.910, blue: 0.835))

            Text("See how items are distributed across your folder structure")
                .font(.subheadline)
                .foregroundColor(Color(red: 0.396, green: 0.482, blue: 0.514))

            Button(action: { appState.openFolderPanel() }) {
                Label("Open Folder", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.863, green: 0.196, blue: 0.184))

            Text("or drag a folder here")
                .font(.caption)
                .foregroundColor(Color(red: 0.345, green: 0.431, blue: 0.459))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.0, green: 0.169, blue: 0.212))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color(red: 0.165, green: 0.631, blue: 0.596) : .clear,
                    style: StrokeStyle(lineWidth: 3, dash: [8])
                )
                .padding(20)
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
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
