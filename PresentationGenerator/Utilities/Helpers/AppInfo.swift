//
//  AppInfo.swift
//  PresentationGenerator
//
//  App information and metadata
//

import Foundation

struct AppInfo {
    /// App version number
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    /// App build number
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    /// Full version string (e.g., "1.0.0 (1)")
    static var fullVersion: String {
        "\(version) (\(build))"
    }
    
    /// App name
    static var name: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "PresentationGenerator"
    }
    
    /// Bundle identifier
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.catholic.presentationgenerator"
    }
    
    /// Copyright year
    static var copyrightYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    /// Copyright notice
    static var copyright: String {
        "© \(copyrightYear) Catholic Creations. All rights reserved."
    }
    
    /// Minimum system version
    static var minimumSystemVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "LSMinimumSystemVersion") as? String ?? "13.0"
    }
}
