//
//  BuddyIntentsPackage.swift
//  BuddyIntents
//

import AppIntents

/// Exposes this module's intents and entities to the app's App Intents metadata.
///
/// Unlike other modules, strings here use the main bundle: App Intents resolves
/// intent and dialog text from the app's `Localizable.xcstrings`, so they live there.
/// User-facing errors come from `BuddyDomain`, which localises them itself.
public struct BuddyIntentsPackage: AppIntentsPackage {}
