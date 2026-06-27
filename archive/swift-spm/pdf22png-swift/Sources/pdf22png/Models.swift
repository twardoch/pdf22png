import Foundation
import CoreGraphics

// MARK: - Scale Specification

struct ScaleSpecification {
    var scaleFactor: CGFloat = 1.0
    var maxWidth: CGFloat = 0
    var maxHeight: CGFloat = 0
    var dpi: CGFloat = 144  // Default DPI
    var isPercentage: Bool = true
    var isDPI: Bool = false
    var hasWidth: Bool = false
    var hasHeight: Bool = false
}

// MARK: - Processing Options

struct ProcessingOptions {
    var scale = ScaleSpecification()
    var pageNumber: Int = 1
    var inputPath: String?
    var outputPath: String?
    var outputDirectory: String?
    var batchMode = false
    var transparentBackground = false
    var pngQuality = 6
    var verbose = false
    var includeText = false
    var pageRange: String?
    var dryRun = false
    var namingPattern: String?
    var forceOverwrite = false
}

// MARK: - Comprehensive Error System

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
    case memoryPressure = 16
    case resourceExhaustion = 17
    case pathInjection = 18
    case insecureOperation = 19
    case signalInterruption = 20
    
    var errorDescription: String? {
        switch self {
        case .success:
            return "Success"
        case .generalError:
            return "General error occurred"
        case .invalidArgs:
            return "Invalid command line arguments provided"
        case .fileNotFound:
            return "Input file not found or inaccessible"
        case .fileRead:
            return "Failed to read input file - check permissions and file integrity"
        case .fileWrite:
            return "Failed to write output file - check disk space and permissions"
        case .noInput:
            return "No input data received from file or stdin"
        case .invalidPDF:
            return "Invalid PDF document - file may be corrupted or not a valid PDF"
        case .encryptedPDF:
            return "PDF document is encrypted (password-protected PDFs not supported)"
        case .emptyPDF:
            return "PDF document has no pages to convert"
        case .pageNotFound:
            return "Requested page does not exist in the document"
        case .renderFailed:
            return "Failed to render PDF page to image"
        case .memory:
            return "Memory allocation failed - insufficient system memory"
        case .outputDir:
            return "Failed to create output directory"
        case .invalidScale:
            return "Invalid scale specification format"
        case .batchFailed:
            return "Batch processing operation failed"
        case .memoryPressure:
            return "System under memory pressure - operation may fail"
        case .resourceExhaustion:
            return "System resources exhausted - reduce complexity or batch size"
        case .pathInjection:
            return "Potentially unsafe file path detected"
        case .insecureOperation:
            return "Insecure operation blocked for safety"
        case .signalInterruption:
            return "Operation interrupted by system signal"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .success:
            return nil
        case .generalError:
            return "Try running with --verbose flag for more detailed error information."
        case .invalidArgs:
            return "Check command syntax with --help flag and verify all arguments are correct."
        case .fileNotFound:
            return "Verify the file path is correct and the file exists. Use absolute paths to avoid confusion."
        case .fileRead:
            return "Check file permissions with 'ls -la'. Ensure you have read access to the file."
        case .fileWrite:
            return "Check available disk space with 'df -h' and verify write permissions to the output directory."
        case .noInput:
            return "Provide a valid PDF file path or pipe PDF data to stdin."
        case .invalidPDF:
            return "Try opening the PDF in Preview to verify it's readable. Use a different PDF if corrupted."
        case .encryptedPDF:
            return "Remove password protection using Preview, pdftk, or qpdf before conversion."
        case .emptyPDF:
            return "Verify the PDF contains pages by opening it in a PDF viewer."
        case .pageNotFound:
            return "Check the page number is valid (pages start at 1) and within document bounds."
        case .renderFailed:
            return "Try reducing scale factor or DPI. Check if PDF page has complex graphics."
        case .memory:
            return "Close other applications to free memory, or try processing fewer pages at once."
        case .outputDir:
            return "Check parent directory exists and you have write permissions to create directories."
        case .invalidScale:
            return "Use formats like '150%', '2.0', '800x600', or '300dpi'. See --help for examples."
        case .batchFailed:
            return "Some pages may have processed successfully. Check output directory for partial results."
        case .memoryPressure:
            return "Close other applications, reduce batch size, or use a smaller scale factor."
        case .resourceExhaustion:
            return "Reduce PDF complexity, scale factor, or process pages in smaller batches."
        case .pathInjection:
            return "Use safe file paths without special characters or path traversal sequences."
        case .insecureOperation:
            return "Operation blocked for security. Contact support if this is unexpected."
        case .signalInterruption:
            return "Operation was safely interrupted. Partial results may be available."
        }
    }
    
    var troubleshootingContext: String {
        switch self {
        case .invalidScale:
            return "scale format"
        case .encryptedPDF:
            return "pdf encrypted password"
        case .emptyPDF:
            return "pdf empty no pages"
        case .pageNotFound:
            return "page range"
        case .memory, .memoryPressure:
            return "memory allocation"
        case .fileNotFound, .fileRead:
            return "file access"
        case .fileWrite, .outputDir:
            return "file write"
        default:
            return "general"
        }
    }
}

// MARK: - Comprehensive Troubleshooting System

let troubleshootingHints: [String: String] = [
    "scale format": """
        Valid scale formats:
        - Percentage: 150% (1.5x scale)
        - Factor: 2.0 (2x scale) 
        - Fixed width: 800x (800px wide, height auto)
        - Fixed height: x600 (600px high, width auto)
        - Fit within: 800x600 (fit within 800x600 box)
        - DPI: 300dpi (dots per inch)
        Examples: -s 150%, -s 2.0, -s 1024x768, -r 300dpi
        """,
    
    "pdf encrypted password": """
        This PDF is password-protected. pdf22png does not currently support encrypted PDFs.
        
        Solutions:
        1. Remove password in Preview: File → Export As → PDF (uncheck Encrypt)
        2. Use qpdf: qpdf --decrypt --password=YOUR_PASSWORD input.pdf output.pdf
        3. Use pdftk: pdftk input.pdf input_pw YOUR_PASSWORD output output.pdf
        """,
    
    "pdf empty no pages": """
        The PDF document appears to be empty, corrupted, or has no renderable pages.
        
        Troubleshooting:
        1. Open the PDF in Preview.app to verify it's readable
        2. Check file size - very small files may be empty
        3. Try a different PDF to verify the tool works
        4. Check if PDF was created properly by the source application
        """,
    
    "page range": """
        Valid page range formats:
        - Single page: 5
        - Range: 1-10  
        - Multiple ranges: 1,3,5-10
        - All pages: use -a/--all flag
        
        Notes:
        - Page numbers start at 1
        - Invalid ranges are ignored
        - Use --verbose to see which pages are processed
        """,
    
    "memory allocation": """
        System running low on memory for image processing.
        
        Solutions:
        1. Close other applications to free RAM
        2. Use smaller scale factor: -s 50% instead of -s 200%
        3. Process fewer pages at once in batch mode
        4. Use lower DPI: -r 150dpi instead of -r 600dpi
        5. Monitor memory with Activity Monitor
        """,
    
    "file access": """
        Cannot access the specified file.
        
        Common causes:
        1. File doesn't exist - check path with 'ls -la'
        2. No read permissions - check with 'ls -la' and use 'chmod +r file'
        3. File in use by another application
        4. Network drive not mounted or accessible
        5. Typo in file path - use tab completion
        """,
    
    "file write": """
        Cannot write to the specified location.
        
        Check:
        1. Disk space: df -h
        2. Write permissions: ls -la parent_directory
        3. Directory exists: mkdir -p /path/to/directory
        4. File not locked by another application
        5. Valid filename (no special characters)
        """,
    
    "general": """
        For additional help:
        1. Run with --verbose flag for detailed information
        2. Check --help for usage examples
        3. Verify system requirements (macOS 10.15+)
        4. Try with a simpler PDF first
        5. Check Console.app for system-level errors
        """
]

// MARK: - Error Reporting Functions

func reportPDF22PNGError(_ error: PDF22PNGError, context: String? = nil) {
    print("Error: \(error.errorDescription ?? "Unknown error")")
    
    if let suggestion = error.recoverySuggestion {
        print("Suggestion: \(suggestion)")
    }
    
    if let hint = troubleshootingHints[error.troubleshootingContext] {
        print("\nTroubleshooting:")
        print(hint)
    }
    
    if let ctx = context {
        print("\nContext: \(ctx)")
    }
}

func reportErrorWithHint(_ message: String, context: String) {
    print("Error: \(message)")
    if let hint = troubleshootingHints[context] {
        print("\nTroubleshooting:")
        print(hint)
    }
}