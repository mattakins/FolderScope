import Foundation

final class FolderNode: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    var children: [FolderNode] = []
    var files: Int = 0
    var fileList: [(name: String, size: Int64)] = []
    var total: Int = 0
    var colorIndex: Int = 0

    // Solarized accent palette (R, G, B)
    static let solarizedAccents: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
        (0.149, 0.545, 0.824),  // blue    #268bd2
        (0.165, 0.631, 0.596),  // cyan    #2aa198
        (0.522, 0.600, 0.0),    // green   #859900
        (0.710, 0.537, 0.0),    // yellow  #b58900
        (0.796, 0.294, 0.086),  // orange  #cb4b16
        (0.863, 0.196, 0.184),  // red     #dc322f
        (0.827, 0.212, 0.510),  // magenta #d33682
        (0.424, 0.443, 0.769),  // violet  #6c71c4
    ]

    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }

    /// Recursively compute total item counts (files + all descendant items)
    func computeTotals() {
        var sum = files
        for child in children {
            child.computeTotals()
            sum += child.total
        }
        total = sum
    }

    /// Assign colors: top-level children cycle through Solarized accents, children inherit parent
    func assignHues() {
        for (i, child) in children.enumerated() {
            child.colorIndex = i % FolderNode.solarizedAccents.count
            child.propagateColor()
        }
    }

    private func propagateColor() {
        for child in children {
            child.colorIndex = colorIndex
            child.propagateColor()
        }
    }

    /// Check if target node exists anywhere in this subtree
    func subtreeContains(_ target: FolderNode) -> Bool {
        if self === target { return true }
        for child in children {
            if child.subtreeContains(target) { return true }
        }
        return false
    }

    /// Collect all descendants flattened with relative paths, sorted by total desc
    func flattenedDescendants(prefix: String = "") -> [(path: String, node: FolderNode)] {
        var result: [(path: String, node: FolderNode)] = []
        for child in children {
            let childPath = prefix.isEmpty ? child.name : prefix + "/" + child.name
            result.append((childPath, child))
            result.append(contentsOf: child.flattenedDescendants(prefix: childPath))
        }
        return result
    }
}
