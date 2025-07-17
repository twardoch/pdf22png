#!/usr/bin/env swift

// Generate Swift version file from git tag information
// Usage: swift generate-version.swift [output-path]

import Foundation

// Get version information from git
func getVersionInfo() -> (version: String, build: String, isRelease: Bool) {
    let versionScript = "./scripts/version.sh"
    
    // Get full version
    let fullVersion = runCommand("\(versionScript) get")
    
    // Get short version  
    let shortVersion = runCommand("\(versionScript) get --short")
    
    // Check if it's a release (exact tag match)
    let isRelease = runCommand("\(versionScript) check") == "true"
    
    // Get build info (commit hash)
    let buildInfo = runCommand("git rev-parse --short HEAD")
    
    return (version: fullVersion, build: buildInfo, isRelease: isRelease)
}

// Run shell command and return output
func runCommand(_ command: String) -> String {
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", command]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    process.launch()
    process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

// Generate Swift version file
func generateVersionFile(outputPath: String) {
    let versionInfo = getVersionInfo()
    
    let content = """
// this_file: \(outputPath)
// Auto-generated version file - DO NOT EDIT
// Generated at: \(Date())

import Foundation

public struct Version {
    public static let version = "\(versionInfo.version)"
    public static let build = "\(versionInfo.build)"
    public static let isRelease = \(versionInfo.isRelease)
    
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
            return "\\(version) (\\(build))"
        }
    }()
    
    // Short version for command line tools
    public static let shortVersion: String = {
        return semanticVersion
    }()
    
    // Build timestamp
    public static let buildDate = "\(Date())"
}
"""
    
    // Write to file
    do {
        try content.write(toFile: outputPath, atomically: true, encoding: .utf8)
        print("Generated version file: \(outputPath)")
    } catch {
        print("Error writing version file: \(error)")
        exit(1)
    }
}

// Main execution
func main() {
    let args = CommandLine.arguments
    let outputPath = args.count > 1 ? args[1] : "Sources/pdf22png/Version.swift"
    
    // Change to project root directory
    let currentDir = FileManager.default.currentDirectoryPath
    if currentDir.hasSuffix("scripts") {
        FileManager.default.changeCurrentDirectoryPath("..")
    }
    
    generateVersionFile(outputPath: outputPath)
}

main()