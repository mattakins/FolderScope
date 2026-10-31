import Foundation

actor DirectoryScanner {
    private let maxDepth = 6
    private let fm = FileManager.default

    func scan(url: URL, progress: @Sendable @escaping (Int) -> Void) async -> FolderNode {
        var itemCount = 0
        let root = scanDirectory(url: url, depth: 0, itemCount: &itemCount, progress: progress)
        return root
    }

    private func scanDirectory(
        url: URL,
        depth: Int,
        itemCount: inout Int,
        progress: @Sendable @escaping (Int) -> Void
    ) -> FolderNode {
        let node = FolderNode(name: url.lastPathComponent, url: url)

        guard depth < maxDepth else { return node }

        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .isHiddenKey]

        var childDirs: [URL] = []
        var fileCount = 0
        var fileEntries: [(name: String, size: Int64)] = []

        if let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            for childURL in contents {
                guard let values = try? childURL.resourceValues(forKeys: Set(keys)) else { continue }

                if values.isDirectory == true {
                    childDirs.append(childURL)
                } else {
                    fileCount += 1
                    let size = Int64(values.fileSize ?? 0)
                    fileEntries.append((childURL.lastPathComponent, size))

                    itemCount += 1
                    if itemCount % 500 == 0 {
                        let count = itemCount
                        progress(count)
                    }
                }
            }
        }

        node.files = fileCount
        node.fileList = fileEntries.sorted { $0.size > $1.size }

        // Recurse into child directories
        for childDir in childDirs.sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }) {
            let child = scanDirectory(url: childDir, depth: depth + 1, itemCount: &itemCount, progress: progress)
            node.children.append(child)
        }

        return node
    }
}
