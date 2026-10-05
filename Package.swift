// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DevSpace",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "DevSpace", targets: ["DevSpace"])],
    targets: [.executableTarget(name: "DevSpace")]
)
