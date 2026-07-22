// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Reddift",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "reddift", targets: ["reddift"])
    ],
    targets: [
        .target(
            name: "HTMLSpecialCharacters"
        ),
        .target(
            name: "MiniKeychain"
        ),
        .target(
            name: "reddift",
            dependencies: [
                "HTMLSpecialCharacters",
                "MiniKeychain"
            ]
        )
    ]
)
