//
//  LocalizationHelper.swift
//  PresentationGenerator
//
//  Helper for localization management
//

import Foundation
import SwiftUI

/// Helper class for localization
enum LocalizationHelper {
    
    // MARK: - Language Support
    
    enum SupportedLanguage: String, CaseIterable {
        case english = "en"
        case italian = "it"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .italian: return "Italiano"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇬🇧"
            case .italian: return "🇮🇹"
            }
        }
    }
    
    // MARK: - Current Language
    
    private static let languageKey = "app.selectedLanguage"
    
    static var currentLanguage: SupportedLanguage {
        get {
            guard let languageCode = UserDefaults.standard.string(forKey: languageKey),
                  let language = SupportedLanguage(rawValue: languageCode) else {
                // Default to system language if supported, otherwise Italian
                let systemLanguage = Locale.current.language.languageCode?.identifier ?? "it"
                return SupportedLanguage(rawValue: systemLanguage) ?? .italian
            }
            return language
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            UserDefaults.standard.synchronize()
            
            // Post notification for language change
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    // MARK: - Localized Strings
    
    /// Get localized string for key
    static func string(for key: String, _ args: CVarArg...) -> String {
        // Get bundle for current language
        guard let bundlePath = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            return NSLocalizedString(key, comment: "")
        }
        
        let format = NSLocalizedString(key, bundle: bundle, comment: "")
        
        if args.isEmpty {
            return format
        } else {
            return String(format: format, arguments: args)
        }
    }
    
    /// Get localized string using SwiftUI LocalizedStringKey
    static func localizedKey(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }
}

// MARK: - String Extension

extension String {
    /// Convenience method to get localized string
    var localized: String {
        LocalizationHelper.string(for: self)
    }
    
    /// Localized with arguments
    func localized(_ args: CVarArg...) -> String {
        LocalizationHelper.string(for: self, args)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - SwiftUI View Extension

extension View {
    /// Refresh view when language changes
    func refreshOnLanguageChange() -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            // Force view refresh by updating a state variable
            // SwiftUI will automatically re-render
        }
    }
}
