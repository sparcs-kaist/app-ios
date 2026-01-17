// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuddyDomain",
    defaultLocalization: "en-GB",
    platforms: [.iOS(.v26), .watchOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BuddyDomain",
            targets: ["BuddyDomain"]
        ),
    ],
    dependencies: [
      .package(url: "https://github.com/mxcl/Version.git", .upToNextMajor(from: "2.2.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BuddyDomain",
            dependencies: [
              .product(name: "Version", package: "Version")
            ]
        ),
        .testTarget(
            name: "BuddyDomainTests",
            dependencies: ["BuddyDomain"]
        ),
    ]
)
