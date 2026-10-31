// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FolderScope",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FolderScope", targets: ["FolderScope"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FolderScope",
            dependencies: [],
            path: "FolderScope"
        )
    ]
)
