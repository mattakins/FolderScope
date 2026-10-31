import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            HStack(spacing: 0) {
                tabButton(title: "Top 10", tab: "top10")
                tabButton(title: "Contents", tab: "contents")
            }
            .background(Color(red: 0.027, green: 0.212, blue: 0.259))
            .overlay(alignment: .bottom) {
                Divider().overlay(Color(red: 0.345, green: 0.431, blue: 0.459).opacity(0.3))
            }

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if appState.activeTab == "top10" {
                        topTenList
                    } else {
                        contentsList
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 280)
        .background(Color(red: 0.027, green: 0.212, blue: 0.259))
    }

    private func tabButton(title: String, tab: String) -> some View {
        Button(action: { appState.activeTab = tab }) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundColor(appState.activeTab == tab ? Color(red: 0.165, green: 0.631, blue: 0.596) : Color(red: 0.345, green: 0.431, blue: 0.459))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    if appState.activeTab == tab {
                        Rectangle()
                            .fill(Color(red: 0.165, green: 0.631, blue: 0.596))
                            .frame(height: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top 10

    @ViewBuilder
    private var topTenList: some View {
        if let node = appState.currentNode {
            let flat = node.flattenedDescendants().sorted { $0.node.total > $1.node.total }.prefix(10)
            ForEach(Array(flat.enumerated()), id: \.offset) { _, item in
                sidebarRow(name: item.path, count: item.node.total, isFile: false) {
                    appState.drillInto(item.node)
                }
            }
        }
    }

    // MARK: - Contents

    @ViewBuilder
    private var contentsList: some View {
        if let node = appState.currentNode {
            // Subfolders
            let folders = node.children.filter { $0.total > 0 }.sorted { $0.total > $1.total }
            if !folders.isEmpty {
                sectionLabel("Subfolders (\(folders.count))")
                ForEach(folders) { folder in
                    sidebarRow(name: folder.name, count: folder.total, isFile: false) {
                        appState.drillInto(folder)
                    }
                }
            }

            // Empty folders
            let emptyFolders = node.children.filter { $0.total == 0 }
            if !emptyFolders.isEmpty {
                sectionLabel("Empty folders (\(emptyFolders.count))")
                ForEach(emptyFolders) { folder in
                    sidebarRow(name: folder.name, count: 0, isFile: true, action: nil)
                }
            }

            // Files
            if !node.fileList.isEmpty {
                sectionLabel("Files (\(node.fileList.count))")
                ForEach(Array(node.fileList.enumerated()), id: \.offset) { _, file in
                    fileRow(name: file.name, size: file.size)
                }
            }

            if folders.isEmpty && node.fileList.isEmpty && emptyFolders.isEmpty {
                Text("Empty folder")
                    .foregroundColor(Color(red: 0.345, green: 0.431, blue: 0.459))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .textCase(.uppercase)
            .tracking(1)
            .foregroundColor(Color(red: 0.345, green: 0.431, blue: 0.459))
            .padding(.top, 12)
            .padding(.bottom, 4)
            .overlay(alignment: .bottom) {
                Divider().overlay(Color(red: 0.345, green: 0.431, blue: 0.459).opacity(0.3))
            }
    }

    private func sidebarRow(name: String, count: Int, isFile: Bool, action: (() -> Void)?) -> some View {
        Button(action: { action?() }) {
            HStack {
                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(isFile ? Color(red: 0.514, green: 0.580, blue: 0.588) : Color(red: 0.576, green: 0.631, blue: 0.631))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(isFile && count == 0 ? "0" : "\(count.formatted()) items")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isFile ? Color(red: 0.165, green: 0.631, blue: 0.596) : Color(red: 0.796, green: 0.294, blue: 0.086))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .onHover { hovering in
            if action != nil {
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
    }

    private func fileRow(name: String, size: Int64) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.514, green: 0.580, blue: 0.588))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text(formatSize(size))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.165, green: 0.631, blue: 0.596))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    private func formatSize(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        if bytes < 1024 * 1024 * 1024 { return String(format: "%.1f MB", Double(bytes) / (1024 * 1024)) }
        return String(format: "%.1f GB", Double(bytes) / (1024 * 1024 * 1024))
    }
}
