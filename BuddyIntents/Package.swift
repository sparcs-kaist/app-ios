// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuddyIntents",
    defaultLocalization: "en-GB",
    platforms: [.iOS(.v26)],
    products: [
        // Siri, Shortcuts and Spotlight integration. Linked by the app only.
        .library(
            name: "BuddyIntents",
            targets: ["BuddyIntents"]
        ),
    ],
    dependencies: [
      .package(path: "../BuddyDomain"),
      .package(path: "../BuddyData"),
      .package(url: "https://github.com/hmlongco/Factory.git", .upToNextMajor(from: "2.5.3")),
    ],
    targets: [
        .target(
            name: "BuddyIntents",
            dependencies: [
              "BuddyDomain",
              .product(name: "BuddyDataCore", package: "BuddyData"),
              .product(name: "Factory", package: "Factory"),
            ]
        ),
    ]
)
