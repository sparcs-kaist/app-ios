// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "BuddyWebCore",
  dependencies: [
    .package(path: "../../shared/BuddyFeedCore"),
    .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", .upToNextMinor(from: "0.58.0"))
  ],
  targets: [
    .executableTarget(
      name: "BuddyWebCore",
      dependencies: ["BuddyFeedCore", "JavaScriptKit"],
      swiftSettings: [
        .enableExperimentalFeature("Extern")
      ],
      plugins: [
        .plugin(name: "BridgeJS", package: "JavaScriptKit")
      ]
    )
  ]
)
