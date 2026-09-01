// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "BuddyFeedCore",
  products: [
    .library(name: "BuddyFeedCore", targets: ["BuddyFeedCore"])
  ],
  targets: [
    .target(name: "BuddyFeedCore"),
    .testTarget(name: "BuddyFeedCoreTests", dependencies: ["BuddyFeedCore"])
  ]
)
