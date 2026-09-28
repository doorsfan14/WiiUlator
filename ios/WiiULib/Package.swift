// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WiiULib",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WiiULib",
            targets: ["WiiULib"]
        )
    ],
    targets: [
        .target(
            name: "WiiULib"
        ),
        .testTarget(
            name: "WiiULibTests",
            dependencies: ["WiiULib"]
        )
    ]
)
