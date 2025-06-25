import Foundation

// MARK: - Error Types

enum PDF22PNGError: Int, Error, LocalizedError {
    case success = 0
    case generalError = 1
    case invalidArgs = 2
    case fileNotFound = 3
    case fileRead = 4
    case fileWrite = 5
    case noInput = 6
    case invalidPDF = 7
    case encryptedPDF = 8
    case emptyPDF = 9
    case pageNotFound = 10
    case renderFailed = 11
    case memory = 12
    case outputDir = 13
    case invalidScale = 14
    case batchFailed = 15
    case signalInterruption = 16
    
    var errorDescription: String? {
        switch self {
        case .success: return "Success"
        case .generalError: return "General error occurred"
        case .invalidArgs: return "Invalid command line arguments"
        case .fileNotFound: return "Input file not found"
        case .fileRead: return "Failed to read input file"
        case .fileWrite: return "Failed to write output file"
        case .noInput: return "No input data received"
        case .invalidPDF: return "Invalid PDF document"
        case .encryptedPDF: return "PDF document is encrypted"
        case .emptyPDF: return "PDF document has no pages"
        case .pageNotFound: return "Requested page does not exist"
        case .renderFailed: return "Failed to render PDF page"
        case .memory: return "Memory allocation failed"
        case .outputDir: return "Failed to create output directory"
        case .invalidScale: return "Invalid scale specification"
        case .batchFailed: return "Batch processing failed"
        case .signalInterruption: return "Operation interrupted by system signal"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidArgs:
            return "Check command syntax with --help flag. Verify all arguments are correct and use absolute paths."
        case .fileNotFound, .fileRead:
            return "Verify the file path is correct, the file exists, and you have read permissions."
        case .fileWrite:
            return "Check available disk space and write permissions to the output directory."
        case .invalidScale:
            return "Use valid formats: 150%, 2.0, 800x600, or 300dpi."
        case .pageNotFound:
            return "PDF pages start at 1. Use --verbose to see total page count."
        case .memory:
            return "Close other applications, use smaller scale factor, or process fewer pages at once."
        case .encryptedPDF:
            return "Remove password protection using Preview or qpdf command-line tool."
        default:
            return "Run with --verbose flag for detailed information. Check --help for usage examples."
        }
    }
}

struct ErrorReporter {
    static func reportError(_ error: PDF22PNGError, context: String? = nil) {
        print("❌ Error: \(error.errorDescription ?? "Unknown error")")
        
        if let ctx = context {
            print("📍 Context: \(ctx)")
        }
        
        if let suggestion = error.recoverySuggestion {
            print("\n💡 Help: \(suggestion)")
        }
        
        // Provide specific troubleshooting based on error type
        switch error {
        case .invalidArgs:
            print("\n💡 Input Validation Help:")
            print("   • Check command syntax with --help flag")
            print("   • Verify all arguments are correct")
            print("   • Use absolute paths to avoid confusion")
            
        case .fileNotFound:
            print("\n💡 File Access Help:")
            print("   • Verify the file path is correct and the file exists")
            print("   • Use absolute paths to avoid confusion")
            print("   • Check file permissions with 'ls -la'")
            
        case .fileRead:
            print("\n💡 File Access Help:")
            print("   • Check file permissions with 'ls -la'")
            print("   • Ensure you have read access to the file")
            print("   • Verify file is not corrupted")
            
        case .fileWrite:
            print("\n💡 File Write Help:")
            print("   • Check available disk space with 'df -h'")
            print("   • Verify write permissions to output directory")
            print("   • Try a different output location")
            
        case .invalidScale:
            print("\n💡 Scale Format Help:")
            print("   • Valid formats: 150%, 2.0, 800x600, 300dpi")
            print("   • Percentage: append % (e.g., 150%)")
            print("   • Factor: decimal number (e.g., 1.5)")
            print("   • Dimensions: WIDTHxHEIGHT (e.g., 1024x768)")
            
        case .pageNotFound:
            print("\n💡 Page Range Help:")
            print("   • PDF pages start at 1, not 0")
            print("   • Use --verbose to see total page count")
            print("   • Valid formats: 5 (single), 1-10 (range)")
            
        case .memory:
            print("\n💡 Memory Help:")
            print("   • Close other applications to free RAM")
            print("   • Use smaller scale factor: --scale 50%")
            print("   • Process fewer pages at once")
            
        case .encryptedPDF:
            print("\n💡 Encrypted PDF Help:")
            print("   • Remove password protection:")
            print("     - In Preview: File → Export As → PDF (uncheck Encrypt)")
            print("     - Command line: qpdf --decrypt --password=PASSWORD input.pdf output.pdf")
            
        default:
            print("\n💡 General Help:")
            print("   • Run with --verbose flag for detailed information")
            print("   • Check --help for usage examples")
            print("   • Try with a simpler PDF first")
        }
    }
}