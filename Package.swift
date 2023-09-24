// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZLImageEditor",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "ZLImageEditor",
            targets: ["ZLImageEditor"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/Tech-Birds-Company/SnapKit", .branchItem("develop")
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ZLImageEditor",
            dependencies: [
                .product(name: "SnapKit", package: "SnapKit")
            ],
            path: "Sources",
            exclude: ["Info.plist"],
            resources: [
                .process("ZLImageEditor.bundle")
            ])
    ]
)
