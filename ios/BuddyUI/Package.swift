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
			name: "BuddyUpcomingClassWidgetUI",
			targets: ["BuddyUpcomingClassWidgetUI"]
		),
		.library(
			name: "BuddyTimetableWidgetUI",
			targets: ["BuddyTimetableWidgetUI"]
		),
		.library(
			name: "BuddyDDayWidgetUI",
			targets: ["BuddyDDayWidgetUI"]
		),
		.library(
			name: "TimetableUI",
			targets: ["TimetableUI"]
		),
		.library(
			name: "BuddySharedUI",
			targets: ["BuddySharedUI"]
		),
	],
	dependencies: [
		.package(path: "../BuddyDomain"),
		.package(url: "https://github.com/efremidze/Haptica.git", .upToNextMajor(from: "4.0.1")),
	],
	targets: [
		.target(
			name: "BuddyUpcomingClassWidgetUI",
			dependencies: [
				"BuddyDomain",
			]
		),
		.target(
			name: "BuddyDDayWidgetUI",
			dependencies: [
				"BuddyDomain",
				"BuddySharedUI"
			]
		),
		.target(
			name: "BuddyTimetableWidgetUI",
			dependencies: [
				"TimetableUI",
				"BuddyDomain",
				"Haptica",
			]
		),
		.target(
			name: "TimetableUI",
			dependencies: [
				"BuddyDomain",
				"Haptica",
			]
		),
		.target(
			name: "BuddySharedUI",
			dependencies: [
				"BuddyDomain",
			]
		),
		.testTarget(
			name: "BuddyUITests",
			dependencies: ["BuddyUpcomingClassWidgetUI", "BuddyTimetableWidgetUI"]
		),
  ]
)

