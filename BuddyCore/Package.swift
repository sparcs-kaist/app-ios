// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BuddyCore",
  defaultLocalization: "en-GB",
  platforms: [.iOS(.v26), .watchOS(.v26)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "BuddyCore",
      targets: ["BuddyCore"]
    ),
    .library(
      name: "BuddyCoreNetworking",
      targets: ["BuddyCoreNetworking"]
    ),
    .library(
      name: "BuddyCoreAuth",
      targets: ["BuddyCoreAuth"]
    ),
  ],
  dependencies: [
    .package(path: "../BuddyDomain"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0")),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "BuddyCore",
      dependencies: [
        "BuddyCoreNetworking",
        "BuddyCoreAuth",
        "BuddyDomain"
      ]
    ),
    .target(
      name: "BuddyCoreNetworking",
      dependencies: [
        "BuddyDomain",
        "Alamofire",
      ]
    ),
    .target(
      name: "BuddyCoreAuth",
      dependencies: [
        "BuddyDomain",
        "BuddyCoreNetworking"
      ]
    ),
    .testTarget(
      name: "BuddyCoreTests",
      dependencies: ["BuddyCore"]
    ),
  ],
  swiftLanguageModes: [.v6]
)

