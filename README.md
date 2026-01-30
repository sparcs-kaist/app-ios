# Buddy 

A comprehensive campus life companion app for KAIST students, integrating timetables, discussion boards, social feeds, and taxi coordination.

[![App Store](https://img.shields.io/badge/App_Store-0D96F6?style=flat&logo=app-store&logoColor=white)](https://apps.apple.com/app/id6749929416)
[![Platform](https://img.shields.io/badge/platform-iOS%20|%20watchOS-lightgrey)](/)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## Features

- **Timetable** - Class schedule management with OTL integration
- **Boards** - Campus discussion boards via Ara integration
- **Feed** - Social feed with posts and comments
- **Taxi** - Ride-sharing coordination with real-time chat
- **Search** - Unified search across timetable, posts, and taxi rooms
- **Widgets** - Lock screen and home screen widgets for quick access
- **Watch App** - watchOS companion with complications
- **Siri Shortcuts** - Voice command and automation integration for quick actions

## Requirements

- iOS 26.0+
- watchOS 26.0+
- Xcode 26.0+
- Swift 6.2+

## Architecture

The project follows **Clean Architecture** with a modular Swift Package Manager structure:

```
app-ios/
├── soap/                    # Main iOS app target
├── BuddyDomain/             # Domain layer (entities, use cases, repositories)
├── BuddyData/               # Platform-agnostic data layer
├── BuddyDataiOS/            # iOS-specific data implementations
├── BuddyFeature/            # Feature modules
│   ├── BuddyFeatureTimetable
│   ├── BuddyFeatureFeed
│   ├── BuddyFeaturePost
│   ├── BuddyFeatureTaxi
│   ├── BuddyFeatureSearch
│   ├── BuddyFeatureSettings
│   └── BuddyFeatureShared
├── BuddyUI/                 # Widget UI components
├── BuddyAppIntents/         # Siri Shortcuts integration
├── BuddyiOSWidget/          # iOS widget extension
├── BuddyWatchWidget/        # watchOS widget extension
└── WatchBuddy Watch App/    # watchOS companion app
```

### Design Patterns

- **Repository Pattern** - Abstracted data access via protocols
- **Dependency Injection** - Using Factory for IoC container
- **MVVM** - ViewModels with SwiftUI and Observation framework

## Dependencies

| Package | Purpose |
|---------|---------|
| [Factory](https://github.com/hmlongco/Factory) | Dependency injection |
| [Moya](https://github.com/Moya/Moya) | Network abstraction |
| [Alamofire](https://github.com/Alamofire/Alamofire) | HTTP networking |
| [Socket.IO](https://github.com/socketio/socket.io-client-swift) | Real-time chat |
| [Nuke](https://github.com/kean/Nuke) | Image loading |
| [KeychainSwift](https://github.com/evgenyneu/keychain-swift) | Secure storage |
| [Firebase](https://github.com/firebase/firebase-ios-sdk) | Crashlytics & Push notifications |

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/sparcs-kaist/app-ios.git
   cd app-ios
   ```

2. Open the project in Xcode:
   ```bash
   open soap.xcodeproj
   ```

3. Resolve Swift Package dependencies (Xcode will do this automatically)

4. Build and run the `soap` scheme

## Configuration

### Firebase Setup

Add your `GoogleService-Info.plist` to the `soap/` directory for Firebase services.

### Authentication

The app uses SPARCS SSO for authentication. Contact the SPARCS team for API access.

## Localization

The app supports:
- English (default)
- Korean

Localization files are managed using `Localizable.xcstrings`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright 2025 SPARCS
