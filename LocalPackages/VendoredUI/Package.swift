// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VendoredUI",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "SubtleVolume", targets: ["SubtleVolume"]),
        .library(name: "TGPControls", targets: ["TGPControls"]),
        .library(name: "MTColorDistance", targets: ["MTColorDistance"])
    ],
    targets: [
        .target(name: "SubtleVolume"),
        .target(name: "TGPControls"),
        .target(name: "MTColorDistance")
    ]
)
