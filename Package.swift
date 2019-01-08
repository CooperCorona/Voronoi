// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Voronoi",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Voronoi",
            targets: ["Voronoi"]),
    ],
    dependencies: [
	.package(url: "https://github.com/CooperCorona/CoronaMath.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Voronoi",
            dependencies: ["CoronaMath"]),
        .testTarget(
            name: "VoronoiTests",
            dependencies: ["Voronoi"]),
    ]
)
