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
            name: "WiiULib",
            path: ".",
            exclude: ["WiiULibTests", "Package.swift"]
        ),
        .testTarget(
            name: "WiiULibTests",
            dependencies: ["WiiULib"],
            path: "WiiULibTests"
        )
    ]
)
