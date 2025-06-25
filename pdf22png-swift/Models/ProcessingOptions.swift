import Foundation

// MARK: - Processing Options

struct ProcessingOptions {
    var inputFile: String?
    var outputFile: String?
    var page: String = "1"
    var allPages: Bool = false
    var resolution: String?
    var scale: String = "100%"
    var transparent: Bool = false
    var quality: Int = 6
    var outputPath: String?
    var directory: String?
    var verbose: Bool = false
    var includeText: Bool = false
    var namingPattern: String?
    var dryRun: Bool = false
    var forceOverwrite: Bool = false
    var showHelp: Bool = false
    var showVersion: Bool = false
    
    // Computed properties
    var effectiveScale: String {
        return resolution ?? scale
    }
    
    var effectiveOutputDirectory: String {
        return directory ?? "."
    }
    
    var isBatchMode: Bool {
        return allPages
    }
    
    var isStdoutMode: Bool {
        return outputPath == "-" || outputFile == "-"
    }
    
    var isStdinMode: Bool {
        return inputFile == "-" || inputFile == nil
    }
}