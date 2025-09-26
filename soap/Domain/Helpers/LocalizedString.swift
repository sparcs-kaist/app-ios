//
//  LocalizedString.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import Foundation

struct LocalizedString: CustomLocalizedStringResourceConvertible, Hashable {
    private let translations: [String: String]
    
    init(_ translations: [String: String]) {
        self.translations = translations
    }
    
    func localized(for languageCode: String? = nil) -> String {
        // Use the provided languageCode or default to the device's current locale.
        let localeLanguageCode = languageCode ?? Locale.current.language.languageCode?.identifier ?? "ko"
        return translations[localeLanguageCode] ?? translations["ko"] ?? "Untitled"
    }
    
    // Conforming to CustomLocalizedStringResourceConvertible
    var localizedStringResource: LocalizedStringResource {
        return LocalizedStringResource(stringLiteral: localized())
    }
}


