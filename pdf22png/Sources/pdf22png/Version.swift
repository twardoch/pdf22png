// this_file: pdf22png/Sources/pdf22png/Version.swift
// Auto-generated version file - DO NOT EDIT
// Generated at: 2025-07-17 16:24:52 UTC

import Foundation

public struct Version {
    public static let version = "2.4.0-dev.2+2bf0d36"
    public static let build = "2bf0d36"
    public static let isRelease = false
    
    // Semantic version components
    public static let semanticVersion: String = {
        // Remove pre-release and build metadata for semantic version
        let components = version.components(separatedBy: "-")
        return components.first ?? version
    }()
    
    // Full version string for display
    public static let fullVersion: String = {
        if isRelease {
            return version
        } else {
            return "\(version) (\(build))"
        }
    }()
    
    // Short version for command line tools
    public static let shortVersion: String = {
        return semanticVersion
    }()
    
    // Build timestamp
    public static let buildDate = "2025-07-17 16:24:52 UTC"
}
