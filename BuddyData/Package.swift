// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuddyData",
    platforms: [.iOS(.v26), .watchOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BuddyDataCore",
            targets: ["BuddyDataCore"]
        ),
        .library(name: "BuddyDataiOS", targets: ["BuddyDataiOS"]),
        .library(name: "BuddyDataMocks", targets: ["BuddyDataMocks"])
    ],
    dependencies: [
      .package(path: "../BuddyDomain"),
      .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
      .package(url: "https://github.com/socketio/socket.io-client-swift", .upToNextMinor(from: "16.1.1")),
      .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "24.0.0"),
      .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0"))
    ],
    targets: [
        .target(
            name: "BuddyDataCore",
            dependencies: [
              "BuddyDomain",
              "Moya",
              "Alamofire",
              .product(name: "KeychainSwift", package: "keychain-swift"),
            ]
        ),
        .target(name: "BuddyDataiOS", dependencies: [
          "BuddyDataCore",
          .product(name: "SocketIO", package: "socket.io-client-swift"),
        ]),
        .target(name: "BuddyDataMocks", dependencies: [
          "BuddyDataCore"
        ]),
        .testTarget(
            name: "BuddyDataTests",
            dependencies: ["BuddyDataCore"]
        ),
    ]
)
