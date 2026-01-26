// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuddyDataiOS",
    defaultLocalization: "en-GB",
    platforms: [.iOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BuddyDataiOS",
            targets: ["BuddyDataiOS"]
        ),
    ],
    dependencies: [
      .package(path: "../BuddyData"),
      .package(
        url: "https://github.com/firebase/firebase-ios-sdk.git",
        .upToNextMajor(from: "12.3.0")
      ),
      .package(url: "https://github.com/socketio/socket.io-client-swift", .upToNextMinor(from: "16.1.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BuddyDataiOS",
            dependencies: [
              .product(name: "BuddyDataCore", package: "BuddyData"),
              .product(name: "SocketIO", package: "socket.io-client-swift"),
              .product(
                name: "FirebaseCrashlytics",
                package: "firebase-ios-sdk"
              ),
            ]
        ),
        .testTarget(
            name: "BuddyDataiOSTests",
            dependencies: ["BuddyDataiOS"]
        ),
    ]
)
