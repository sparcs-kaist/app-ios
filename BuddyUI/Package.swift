// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BuddyUI",
  defaultLocalization: "en-GB",
  platforms: [.iOS(.v26), .watchOS(.v26)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "BuddyAccessoryUI",
      targets: ["BuddyAccessoryUI"]
    ),
  ],
  dependencies: [
    .package(path: "../BuddyDomain")
  ],
  targets: [
    .target(
      name: "BuddyAccessoryUI",
      dependencies: [
        "BuddyDomain",
      ]
    ),
    .testTarget(
      name: "BuddyUITests",
      dependencies: ["BuddyAccessoryUI"]
    ),
  ]
)
