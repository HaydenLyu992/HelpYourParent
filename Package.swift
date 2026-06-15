// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HelpYourParent",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "HelpYourParent",
            targets: ["HelpYourParent"]
        )
    ],
    targets: [
        .executableTarget(
            name: "HelpYourParent",
            path: ".",
            exclude: [
                ".claude",
                ".git",
                ".idea",
                "help-your-parent-server",
                "UIDesign.html",
                "CLAUDE.md",
                "README.md",
                "LICENSE",
                ".gitignore",
                ".DS_Store"
            ]
        )
    ]
)
