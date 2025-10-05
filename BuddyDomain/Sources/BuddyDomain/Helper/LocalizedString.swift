//
//  LocalizedString.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import Foundation

public struct LocalizedString: CustomLocalizedStringResourceConvertible, Hashable, Sendable {
    private let translations: [String: String]
    
    public init(_ translations: [String: String]) {
        self.translations = translations
    }
    
    public func localized(for languageCode: String? = nil) -> String {
        // Use the provided languageCode or default to the device's current locale.
        let localeLanguageCode = languageCode ?? Locale.current.language.languageCode?.identifier ?? "ko"
        return translations[localeLanguageCode] ?? translations["ko"] ?? "Untitled"
    }
  
    public func contains(_ query: String) -> Bool {
        let result = !translations.values.filter { $0.contains(query) }.isEmpty
        return result
    }
    
    // Conforming to CustomLocalizedStringResourceConvertible
    public var localizedStringResource: LocalizedStringResource {
        return LocalizedStringResource(stringLiteral: localized())
    }
}


