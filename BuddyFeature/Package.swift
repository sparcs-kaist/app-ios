// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuddyFeature",
    defaultLocalization: "en-GB",
    platforms: [.iOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BuddyFeatureTimetable",
            targets: ["BuddyFeatureTimetable"]
        ),
        .library(name: "BuddyFeatureFeed", targets: ["BuddyFeatureFeed"]),
        .library(name: "BuddyFeaturePost", targets: ["BuddyFeaturePost"]),
        .library(name: "BuddyFeatureTaxi", targets: ["BuddyFeatureTaxi"]),
        .library(name: "BuddyFeatureSettings", targets: ["BuddyFeatureSettings"]),
        .library(name: "BuddyFeatureShared", targets: ["BuddyFeatureShared"])
    ],
    dependencies: [
      .package(path: "../BuddyDomain"),
      .package(url: "https://github.com/efremidze/Haptica.git", .upToNextMajor(from: "4.0.1")),
      .package(url: "https://github.com/kean/Nuke.git", .upToNextMajor(from: "12.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BuddyFeatureTimetable",
            dependencies: [
              "BuddyDomain",
              "Haptica",
              "BuddyFeatureShared"
            ]
        ),
        .target(
          name: "BuddyFeatureFeed",
          dependencies: [
            "BuddyDomain",
            "BuddyFeatureShared",
            "BuddyFeatureSettings"
          ]
        ),
        .target(
          name: "BuddyFeatureSettings",
          dependencies: [
            "BuddyDomain",
            "Haptica",
            "BuddyFeatureShared"
          ]
        ),
        .target(
          name: "BuddyFeaturePost",
          dependencies: [
            "BuddyDomain",
            "BuddyFeatureShared",
            .product(name: "Nuke", package: "Nuke"),
            .product(name: "NukeUI", package: "Nuke"),
          ]
        ),
        .target(
          name: "BuddyFeatureTaxi",
          dependencies: [
            "BuddyDomain",
            "BuddyFeatureShared",
            "Haptica",
            .product(name: "Nuke", package: "Nuke"),
            .product(name: "NukeUI", package: "Nuke"),
          ]
        ),
        .target(
          name: "BuddyFeatureShared",
          dependencies: [
            "Haptica",
            "BuddyDomain"
          ]
        ),
        .testTarget(
            name: "BuddyFeatureTests",
            dependencies: ["BuddyFeatureTimetable"]
        ),
    ]
)
