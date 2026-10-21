//
//  ModelLanguageSettings.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 20/10/2026.
//

import Foundation

/// The language on-device summaries are written in when forced from Debug
/// Settings, overriding the device's language. The simulator's model loads
/// English-only assets and writes English whatever it is asked, so this is for
/// trying languages on a device.
public enum ModelLanguageSettings {
  /// The `UserDefaults.standard` key, shared by the reader and Debug Settings'
  /// `@AppStorage`. Holds a language code, or nothing to follow the device.
  public static let forcedLanguageKey = "debug.forcedModelLanguage"

  /// The languages Debug Settings offers: the ones Buddy is localised into.
  public static let languageCodes = ["en", "ko"]

  /// The forced language's code, or `nil` to follow the device.
  public static var forcedLanguageCode: String? {
    guard let code = UserDefaults.standard.string(forKey: forcedLanguageKey), !code.isEmpty else { return nil }
    return code
  }
}
