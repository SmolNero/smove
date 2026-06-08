// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "smove",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "smove", targets: ["smove"])
    ],
    targets: [
        .executableTarget(name: "smove", path: "Sources/smove")
    ]
)
