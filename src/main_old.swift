#!/usr/bin/env swift

import Foundation
import CoreGraphics
import Quartz
import ImageIO
import PDFKit
import UniformTypeIdentifiers

// MARK: - Memory Management System

class MemoryManager {
    static let shared = MemoryManager()
    private init() {}
    
    // System memory thresholds (in bytes)
    private let lowMemoryThreshold: UInt64 = 512 * 1024 * 1024    // 512MB
    private let criticalMemoryThreshold: UInt64 = 256 * 1024 * 1024 // 256MB
    private let maxMemoryUsage: UInt64 = 2 * 1024 * 1024 * 1024    // 2GB
    
    func getSystemMemoryInfo() -> (total: UInt64, available: UInt64, used: UInt64) {
        var size = MemoryLayout<vm_size_t>.size
        var physicalMemory: vm_size_t = 0
        sysctlbyname("hw.memsize", &physicalMemory, &size, nil, 0)
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        let used = UInt64(kr == KERN_SUCCESS ? info.resident_size : 0)
        let total = UInt64(physicalMemory)
        let available = total > used ? total - used : 0
        
        return (total: total, available: available, used: used)
    }
    
    func isMemoryPressureHigh() -> Bool {
        let memInfo = getSystemMemoryInfo()
        return memInfo.available < lowMemoryThreshold
    }
    
    func isMemoryPressureCritical() -> Bool {
        let memInfo = getSystemMemoryInfo()
        return memInfo.available < criticalMemoryThreshold
    }
    
    func estimateMemoryRequirement(pageRect: CGRect, scaleFactor: CGFloat, transparentBackground: Bool) -> UInt64 {
        let scaledWidth = pageRect.width * scaleFactor
        let scaledHeight = pageRect.height * scaleFactor
        let pixelCount = scaledWidth * scaledHeight
        
        // 4 bytes per pixel (RGBA), plus overhead
        let baseMemory = UInt64(pixelCount * 4)
        
        // Add overhead for Core Graphics contexts and intermediate buffers
        let overhead = baseMemory / 4
        
        // Transparent backgrounds require more memory
        let transparencyMultiplier: CGFloat = transparentBackground ? 1.5 : 1.0
        
        return UInt64(CGFloat(baseMemory + overhead) * transparencyMultiplier)
    }
    
    func canAllocateMemory(_ requiredMemory: UInt64, verbose: Bool) -> Bool {
        let memInfo = getSystemMemoryInfo()
        let canAllocate = memInfo.available > requiredMemory + criticalMemoryThreshold
        
        if verbose {
            let availableMB = memInfo.available / (1024 * 1024)
            let requiredMB = requiredMemory / (1024 * 1024)
            logMessage(true, "Memory check: Available \(availableMB)MB, Required \(requiredMB)MB")
        }
        
        return canAllocate
    }
    
    func calculateOptimalBatchSize(totalPages: Int, pageRect: CGRect, scaleFactor: CGFloat, verbose: Bool) -> Int {
        let memoryPerPage = estimateMemoryRequirement(pageRect: pageRect, scaleFactor: scaleFactor, transparentBackground: false)
        let memInfo = getSystemMemoryInfo()
        let availableForBatch = memInfo.available / 2 // Use only half of available memory
        
        let optimalBatchSize = max(1, min(totalPages, Int(availableForBatch / memoryPerPage)))
        
        if verbose {
            let batchMemoryMB = (UInt64(optimalBatchSize) * memoryPerPage) / (1024 * 1024)
            logMessage(true, "Optimal batch size: \(optimalBatchSize) pages (\(batchMemoryMB)MB estimated)")
        }
        
        return optimalBatchSize
    }
    
    func logMemoryStatus(verbose: Bool) {
        if !verbose { return }
        
        let memInfo = getSystemMemoryInfo()
        let totalGB = Double(memInfo.total) / (1024 * 1024 * 1024)
        let availableMB = memInfo.available / (1024 * 1024)
        let usedMB = memInfo.used / (1024 * 1024)
        
        logMessage(true, String(format: "Memory status: %.1fGB total, %lluMB used, %lluMB available", 
                              totalGB, usedMB, availableMB))
        
        if isMemoryPressureCritical() {
            print("⚠️  Critical memory pressure detected!")
        } else if isMemoryPressureHigh() {
            print("⚠️  High memory pressure detected")
        }
    }
    
    func checkMemoryPressureDuringBatch(verbose: Bool) throws {
        if isMemoryPressureCritical() {
            throw PDF22PNGError.memory
        }
        
        if isMemoryPressureHigh() && verbose {
            print("⚠️  High memory pressure - consider reducing batch size")
        }
    }
}

// MARK: - Resource Management System

class ResourceManager {
    static let shared = ResourceManager()
    private init() {}
    
    private var tempFiles: Set<String> = []
    private var fileHandles: Set<ObjectIdentifier> = []
    private let resourceQueue = DispatchQueue(label: "resource.management", qos: .utility)
    
    func registerTempFile(_ path: String) {
        resourceQueue.sync {
            _ = tempFiles.insert(path)
        }
    }
    
    func unregisterTempFile(_ path: String) {
        resourceQueue.sync {
            _ = tempFiles.remove(path)
        }
    }
    
    func registerFileHandle(_ handle: FileHandle) {
        resourceQueue.sync {
            _ = fileHandles.insert(ObjectIdentifier(handle))
        }
    }
    
    func unregisterFileHandle(_ handle: FileHandle) {
        resourceQueue.sync {
            _ = fileHandles.remove(ObjectIdentifier(handle))
        }
    }
    
    func cleanupAllResources() {
        resourceQueue.sync {
            // Clean up temporary files
            for tempFile in tempFiles {
                do {
                    if FileManager.default.fileExists(atPath: tempFile) {
                        try FileManager.default.removeItem(atPath: tempFile)
                    }
                } catch {
                    // Ignore cleanup errors
                }
            }
            tempFiles.removeAll()
            
            // Clear file handle tracking
            fileHandles.removeAll()
        }
    }
    
    func createSecureTempFile(prefix: String = "pdf22png", suffix: String = ".tmp") -> String? {
        let tempDir = NSTemporaryDirectory()
        let tempFileName = "\(prefix)_\(UUID().uuidString)\(suffix)"
        let tempPath = (tempDir as NSString).appendingPathComponent(tempFileName)
        
        // Create the file with secure permissions (600)
        let success = FileManager.default.createFile(atPath: tempPath, contents: nil, attributes: [
            .posixPermissions: 0o600
        ])
        
        if success {
            registerTempFile(tempPath)
            return tempPath
        }
        
        return nil
    }
}

// MARK: - Input Validation System

class InputValidator {
    static let maxFileSize: UInt64 = 500 * 1024 * 1024 // 500MB
    static let maxPageNumber: Int = 10000
    static let maxTotalPages: Int = 5000
    static let maxPathLength: Int = 1024
    
    static func validateFilePath(_ path: String, allowCreate: Bool = false) throws -> String {
        // Check path length
        guard path.count <= maxPathLength else {
            throw PDF22PNGError.invalidArgs
        }
        
        // Prevent path traversal attacks
        let normalizedPath = (path as NSString).standardizingPath
        guard !normalizedPath.contains("../") && !normalizedPath.contains("..\\") else {
            throw PDF22PNGError.invalidArgs
        }
        
        // Check for null bytes and other dangerous characters
        guard !path.contains("\0") && !path.contains("\n") && !path.contains("\r") else {
            throw PDF22PNGError.invalidArgs
        }
        
        if !allowCreate {
            // For input files, check existence and size
            guard FileManager.default.fileExists(atPath: normalizedPath) else {
                throw PDF22PNGError.fileNotFound
            }
            
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: normalizedPath)
                if let fileSize = attributes[.size] as? UInt64, fileSize > maxFileSize {
                    throw PDF22PNGError.invalidArgs
                }
            } catch {
                throw PDF22PNGError.fileRead
            }
        }
        
        return normalizedPath
    }
    
    static func validateOutputDirectory(_ path: String) throws -> String {
        let normalizedPath = try validateFilePath(path, allowCreate: true)
        
        // Check if parent directory exists and is writable
        let parentDir = (normalizedPath as NSString).deletingLastPathComponent
        guard FileManager.default.fileExists(atPath: parentDir) else {
            throw PDF22PNGError.outputDir
        }
        
        guard FileManager.default.isWritableFile(atPath: parentDir) else {
            throw PDF22PNGError.fileWrite
        }
        
        return normalizedPath
    }
    
    static func validatePageNumber(_ page: Int, totalPages: Int) throws {
        guard page >= 1 && page <= totalPages else {
            throw PDF22PNGError.pageNotFound
        }
        
        guard page <= maxPageNumber else {
            throw PDF22PNGError.invalidArgs
        }
    }
    
    static func validatePageRange(_ range: String, totalPages: Int) throws {
        // Basic validation of page range format
        let validChars = CharacterSet(charactersIn: "0123456789,-")
        guard range.rangeOfCharacter(from: validChars.inverted) == nil else {
            throw PDF22PNGError.invalidArgs
        }
        
        // Check for reasonable range limits
        let components = range.components(separatedBy: CharacterSet(charactersIn: ",-"))
        for component in components {
            if let pageNum = Int(component.trimmingCharacters(in: .whitespaces)) {
                try validatePageNumber(pageNum, totalPages: totalPages)
            }
        }
    }
    
    static func validateScale(_ scale: String) throws {
        guard scale.count <= 20 else { // Reasonable limit for scale specification
            throw PDF22PNGError.invalidScale
        }
        
        // Check for basic format validity
        let validChars = CharacterSet(charactersIn: "0123456789.%xdpi")
        guard scale.rangeOfCharacter(from: validChars.inverted) == nil else {
            throw PDF22PNGError.invalidScale
        }
    }
    
    static func validateQuality(_ quality: Int) throws {
        guard quality >= 0 && quality <= 9 else {
            throw PDF22PNGError.invalidArgs
        }
    }
    
    static func validateNamingPattern(_ pattern: String) throws {
        guard pattern.count <= 200 else { // Reasonable pattern length
            throw PDF22PNGError.invalidArgs
        }
        
        // Check for potentially dangerous pattern elements
        guard !pattern.contains("../") && !pattern.contains("..\\") && !pattern.contains("\0") else {
            throw PDF22PNGError.invalidArgs
        }
    }
}

// MARK: - Enhanced Signal Handling

var shouldTerminate = false
private var cleanupHandlers: [() -> Void] = []
private let signalQueue = DispatchQueue(label: "signal.handling", qos: .utility)

func installSignalHandlers() {
    // Handle SIGINT (Ctrl+C)
    signal(SIGINT) { _ in
        handleGracefulShutdown(signal: "SIGINT")
    }
    
    // Handle SIGTERM (termination request)
    signal(SIGTERM) { _ in
        handleGracefulShutdown(signal: "SIGTERM")
    }
    
    // Handle SIGHUP (hangup)
    signal(SIGHUP) { _ in
        handleGracefulShutdown(signal: "SIGHUP")
    }
}

private func handleGracefulShutdown(signal: String) {
    shouldTerminate = true
    
    fputs("\n📡 Received \(signal), initiating graceful shutdown...\n", stderr)
    fflush(stderr)
    
    // Perform cleanup on a separate queue to avoid deadlocks
    signalQueue.async {
        performCleanup()
        
        // Give a brief moment for current operations to finish
        usleep(100_000) // 100ms
        
        fputs("✅ Cleanup complete. Exiting.\n", stderr)
        fflush(stderr)
        exit(1)
    }
}

private func performCleanup() {
    // Execute registered cleanup handlers
    for handler in cleanupHandlers {
        handler()
    }
    cleanupHandlers.removeAll()
    
    // Clean up resources
    ResourceManager.shared.cleanupAllResources()
}

func registerCleanupHandler(_ handler: @escaping () -> Void) {
    cleanupHandlers.append(handler)
}

func checkInterruption() throws {
    if shouldTerminate {
        throw PDF22PNGError.signalInterruption
    }
}

// MARK: - Progress Reporter

class ProgressReporter {
    private let totalPages: Int
    private var startTime: Date
    private var processedPages: Int = 0
    private var successfulPages: Int = 0
    private var failedPages: Int = 0
    private var lastReportTime: Date
    private let reportInterval: TimeInterval = 1.0 // Report at most once per second
    private let verbose: Bool
    
    init(totalPages: Int, verbose: Bool = false) {
        self.totalPages = totalPages
        self.verbose = verbose
        self.startTime = Date()
        self.lastReportTime = Date()
    }
    
    func reportPageStart(pageNumber: Int) {
        if verbose {
            print("Processing page \(pageNumber)/\(totalPages)...")
        }
    }
    
    func reportPageComplete(pageNumber: Int, success: Bool, outputFile: String? = nil) {
        processedPages += 1
        if success {
            successfulPages += 1
            if let outputFile = outputFile, !verbose {
                // For non-verbose mode, show successful outputs
                print("✓ Page \(pageNumber) → \(outputFile)")
            }
        } else {
            failedPages += 1
            print("✗ Page \(pageNumber) failed")
        }
        
        // Report progress if enough time has passed or we're at a milestone
        let now = Date()
        let shouldReportTime = now.timeIntervalSince(lastReportTime) >= reportInterval
        let shouldReportMilestone = processedPages % 10 == 0 || processedPages == totalPages
        
        if shouldReportTime || shouldReportMilestone {
            reportProgress()
            lastReportTime = now
        }
    }
    
    func reportChunkStart(chunkNumber: Int, totalChunks: Int, pagesInChunk: Int) {
        if verbose {
            print("\n📦 Processing chunk \(chunkNumber)/\(totalChunks) (\(pagesInChunk) pages)")
        }
    }
    
    private func reportProgress() {
        let percentage = (processedPages * 100) / totalPages
        let elapsed = Date().timeIntervalSince(startTime)
        let pagesPerSecond = elapsed > 0 ? Double(processedPages) / elapsed : 0
        let estimatedTotal = pagesPerSecond > 0 ? Double(totalPages) / pagesPerSecond : 0
        let estimatedRemaining = max(0, estimatedTotal - elapsed)
        
        var progressBar = "["
        let barWidth = 30
        let filledWidth = (barWidth * processedPages) / totalPages
        progressBar += String(repeating: "■", count: filledWidth)
        progressBar += String(repeating: "□", count: barWidth - filledWidth)
        progressBar += "]"
        
        print("\n📊 Progress: \(progressBar) \(percentage)%")
        print("   Processed: \(processedPages)/\(totalPages) pages (✓ \(successfulPages), ✗ \(failedPages))")
        
        if pagesPerSecond > 0 {
            print("   Speed: \(String(format: "%.1f", pagesPerSecond)) pages/sec")
            print("   Time: \(formatDuration(elapsed)) elapsed, ~\(formatDuration(estimatedRemaining)) remaining")
        }
        
        // Memory status in verbose mode
        if verbose {
            let memInfo = MemoryManager.shared.getSystemMemoryInfo()
            let usedGB = Double(memInfo.used) / (1024 * 1024 * 1024)
            let availableGB = Double(memInfo.available) / (1024 * 1024 * 1024)
            print("   Memory: \(String(format: "%.1f", usedGB))GB used, \(String(format: "%.1f", availableGB))GB available")
        }
    }
    
    func reportBatchComplete() {
        let elapsed = Date().timeIntervalSince(startTime)
        let pagesPerSecond = elapsed > 0 ? Double(processedPages) / elapsed : 0
        
        print("\n✅ Batch processing complete!")
        print("   Total: \(processedPages) pages processed in \(formatDuration(elapsed))")
        print("   Results: ✓ \(successfulPages) successful, ✗ \(failedPages) failed")
        if pagesPerSecond > 0 {
            print("   Average speed: \(String(format: "%.1f", pagesPerSecond)) pages/sec")
        }
    }
    
    func reportInterrupted() {
        print("\n⚠️  Processing interrupted!")
        print("   Completed: \(processedPages)/\(totalPages) pages")
        print("   Results: ✓ \(successfulPages) successful, ✗ \(failedPages) failed")
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Command Line Argument Parser

struct CommandLineOptions {
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
}

func printHelp() {
    print("""
Usage: pdf22png [OPTIONS] <input.pdf> [output.png]
Converts PDF documents to PNG images.

Options:
  -p, --page <spec>       Page(s) to convert. Single page, range, or comma-separated.
                          Examples: 1 | 1-5 | 1,3,5-10 (default: 1)
                          In batch mode, only specified pages are converted.
  -a, --all               Convert all pages. If -d is not given, uses input filename as prefix.
                          Output files named <prefix>-<page_num>.png.
  -r, --resolution <dpi>  Set output DPI (e.g., 150dpi). Overrides -s if both used with numbers.
  -s, --scale <spec>      Scaling specification (default: 100% or 1.0).
                            NNN%: percentage (e.g., 150%)
                            N.N:  scale factor (e.g., 1.5)
                            WxH:  fit to WxH pixels (e.g., 800x600)
                            Wx:   fit to width W pixels (e.g., 1024x)
                            xH:   fit to height H pixels (e.g., x768)
  -t, --transparent       Preserve transparency (default: white background).
  -q, --quality <n>       PNG compression quality (0-9, default: 6). Currently informational.
  -o, --output <path>     Output PNG file or prefix for batch mode.
                          If '-', output to stdout (single page mode only).
  -d, --directory <dir>   Output directory for batch mode (converts all pages).
                          If used, -o specifies filename prefix inside this directory.
  -v, --verbose           Verbose output.
  -n, --name              Include extracted text in output filename (batch mode only).
  -P, --pattern <pat>     Custom naming pattern for batch mode. Placeholders:
                          {basename} - Input filename without extension
                          {page} - Page number (auto-padded)
                          {page:03d} - Page with custom padding
                          {text} - Extracted text (requires -n)
                          {date} - Current date (YYYYMMDD)
                          {time} - Current time (HHMMSS)
                          {total} - Total page count
                          Example: '{basename}_p{page:04d}_of_{total}'
  -D, --dry-run           Preview operations without writing files.
  -f, --force             Force overwrite existing files without prompting.
  -h, --help              Show this help message and exit.
  --version               Show version information and exit.

Arguments:
  <input.pdf>             Input PDF file. If '-', reads from stdin.
  [output.png]            Output PNG file. Required if not using -o or -d.
                          If input is stdin and output is not specified, output goes to stdout.
                          In batch mode (-a or -d), this is used as a prefix if -o is not set.

Examples:
  pdf22png document.pdf page1.png              # Convert first page
  pdf22png -p 5 document.pdf page5.png         # Convert page 5
  pdf22png -a document.pdf                     # Convert all pages (document-001.png, ...)
  pdf22png -r 300 document.pdf hi-res.png      # High resolution
  pdf22png -s 150% document.pdf large.png      # 1.5x scale
  pdf22png -d output/ document.pdf             # All pages to output/ directory
  pdf22png -t document.pdf transparent.png     # Preserve transparency
  cat document.pdf | pdf22png - output.png     # From stdin
""")
}

func printVersion() {
    let version = "2.0.0-standalone"
    print("pdf22png \(version)")
    print("Swift standalone implementation")
}

func parseCommandLine() -> CommandLineOptions {
    var options = CommandLineOptions()
    let args = Array(CommandLine.arguments.dropFirst())
    var i = 0
    
    while i < args.count {
        let arg = args[i]
        
        switch arg {
        case "-h", "--help":
            options.showHelp = true
            return options
            
        case "--version":
            options.showVersion = true
            return options
            
        case "-p", "--page":
            guard i + 1 < args.count else {
                print("Error: --page requires a value")
                exit(2)
            }
            options.page = args[i + 1]
            i += 1
            
        case "-a", "--all":
            options.allPages = true
            
        case "-r", "--resolution":
            guard i + 1 < args.count else {
                print("Error: --resolution requires a value")
                exit(2)
            }
            options.resolution = args[i + 1]
            i += 1
            
        case "-s", "--scale":
            guard i + 1 < args.count else {
                print("Error: --scale requires a value")
                exit(2)
            }
            options.scale = args[i + 1]
            i += 1
            
        case "-t", "--transparent":
            options.transparent = true
            
        case "-q", "--quality":
            guard i + 1 < args.count else {
                print("Error: --quality requires a value")
                exit(2)
            }
            guard let quality = Int(args[i + 1]), quality >= 0 && quality <= 9 else {
                print("Error: quality must be between 0 and 9")
                exit(2)
            }
            options.quality = quality
            i += 1
            
        case "-o", "--output":
            guard i + 1 < args.count else {
                print("Error: --output requires a value")
                exit(2)
            }
            options.outputPath = args[i + 1]
            i += 1
            
        case "-d", "--directory":
            guard i + 1 < args.count else {
                print("Error: --directory requires a value")
                exit(2)
            }
            options.directory = args[i + 1]
            i += 1
            
        case "-v", "--verbose":
            options.verbose = true
            
        case "-n", "--name":
            options.includeText = true
            
        case "-P", "--pattern":
            guard i + 1 < args.count else {
                print("Error: --pattern requires a value")
                exit(2)
            }
            options.namingPattern = args[i + 1]
            i += 1
            
        case "-D", "--dry-run":
            options.dryRun = true
            
        case "-f", "--force":
            options.forceOverwrite = true
            
        default:
            if arg.hasPrefix("-") {
                print("Error: Unknown option: \(arg)")
                print("Use --help for usage information")
                exit(2)
            } else {
                // Positional arguments
                if options.inputFile == nil {
                    options.inputFile = arg
                } else if options.outputFile == nil {
                    options.outputFile = arg
                } else {
                    print("Error: Too many arguments")
                    exit(2)
                }
            }
        }
        i += 1
    }
    
    return options
}

// MARK: - Error Handling

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
}

func reportPDF22PNGError(_ error: PDF22PNGError, context: String? = nil) {
    print("❌ Error: \(error.errorDescription ?? "Unknown error")")
    
    if let ctx = context {
        print("📍 Context: \(ctx)")
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

// MARK: - Utility Functions

func logMessage(_ verbose: Bool, _ message: String) {
    if verbose {
        print("LOG: \(message)")
    }
}

// MARK: - Scale Specification

struct ScaleSpecification {
    var scaleFactor: CGFloat = 1.0
    var maxWidth: CGFloat = 0
    var maxHeight: CGFloat = 0
    var dpi: CGFloat = 144
    var isPercentage: Bool = true
    var isDPI: Bool = false
    var hasWidth: Bool = false
    var hasHeight: Bool = false
}

func parseScaleSpecification(_ scaleStr: String) -> ScaleSpecification? {
    var spec = ScaleSpecification()
    let trimmed = scaleStr.trimmingCharacters(in: .whitespaces)
    
    if trimmed.hasSuffix("%") {
        let percentStr = String(trimmed.dropLast())
        guard let percent = Double(percentStr), percent > 0 else { return nil }
        spec.scaleFactor = CGFloat(percent / 100.0)
        spec.isPercentage = true
        return spec
    }
    
    if trimmed.hasSuffix("dpi") {
        let dpiStr = String(trimmed.dropLast(3))
        guard let dpi = Double(dpiStr), dpi > 0 else { return nil }
        spec.dpi = CGFloat(dpi)
        spec.scaleFactor = CGFloat(dpi / 72.0)
        spec.isDPI = true
        return spec
    }
    
    if trimmed.contains("x") {
        let parts = trimmed.components(separatedBy: "x")
        guard parts.count == 2 else { return nil }
        
        let widthStr = parts[0]
        let heightStr = parts[1]
        
        if !widthStr.isEmpty {
            guard let width = Double(widthStr), width > 0 else { return nil }
            spec.maxWidth = CGFloat(width)
            spec.hasWidth = true
        }
        
        if !heightStr.isEmpty {
            guard let height = Double(heightStr), height > 0 else { return nil }
            spec.maxHeight = CGFloat(height)
            spec.hasHeight = true
        }
        
        if !spec.hasWidth && !spec.hasHeight {
            return nil
        }
        
        spec.isPercentage = false
        return spec
    }
    
    guard let factor = Double(trimmed), factor > 0 else { return nil }
    spec.scaleFactor = CGFloat(factor)
    spec.isPercentage = false
    return spec
}

func calculateScaleFactor(scale: ScaleSpecification, pageRect: CGRect) -> CGFloat {
    if scale.hasWidth || scale.hasHeight {
        let pageWidth = pageRect.width
        let pageHeight = pageRect.height
        
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        
        if scale.hasWidth {
            scaleX = scale.maxWidth / pageWidth
        }
        
        if scale.hasHeight {
            scaleY = scale.maxHeight / pageHeight
        }
        
        if scale.hasWidth && scale.hasHeight {
            return min(scaleX, scaleY)
        } else {
            return scale.hasWidth ? scaleX : scaleY
        }
    }
    
    return scale.scaleFactor
}

// MARK: - PDF Processing

func readPDFData(_ inputPath: String?, verbose: Bool) -> Data? {
    if let path = inputPath, path != "-" {
        logMessage(verbose, "Reading PDF from file: \(path)")
        return FileManager.default.contents(atPath: path)
    } else {
        logMessage(verbose, "Reading PDF from stdin")
        let stdin = FileHandle.standardInput
        return stdin.readDataToEndOfFile()
    }
}

func createPDFDocument(from data: Data) -> PDFDocument? {
    return PDFDocument(data: data)
}

func renderPDFPageToImage(page: PDFPage, scaleFactor: CGFloat, transparentBackground: Bool, verbose: Bool) -> CGImage? {
    let pageRect = page.bounds(for: .mediaBox)
    let scaledWidth = Int(pageRect.width * scaleFactor)
    let scaledHeight = Int(pageRect.height * scaleFactor)
    
    logMessage(verbose, "Rendering page at \(scaledWidth)x\(scaledHeight) (scale: \(scaleFactor))")
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: CGBitmapInfo = transparentBackground ? 
        [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)] :
        [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)]
    
    guard let context = CGContext(
        data: nil,
        width: scaledWidth,
        height: scaledHeight,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        return nil
    }
    
    context.scaleBy(x: scaleFactor, y: scaleFactor)
    
    if !transparentBackground {
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: pageRect.width, height: pageRect.height))
    }
    
    page.draw(with: .mediaBox, to: context)
    
    return context.makeImage()
}

func writeImageToFile(image: CGImage, path: String, quality: Int, verbose: Bool, dryRun: Bool, forceOverwrite: Bool) -> Bool {
    if dryRun {
        let width = image.width
        let height = image.height
        print("[DRY-RUN] Would write \(width)x\(height) PNG to: \(path)")
        return true
    }
    
    // Check if file exists and handle overwrite
    if FileManager.default.fileExists(atPath: path) && !forceOverwrite {
        print("File \(path) already exists. Use --force to overwrite.")
        return false
    }
    
    let url = URL(fileURLWithPath: path)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        return false
    }
    
    let options: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: CGFloat(quality) / 9.0
    ]
    
    CGImageDestinationAddImage(destination, image, options as CFDictionary)
    let success = CGImageDestinationFinalize(destination)
    
    if success {
        logMessage(verbose, "Successfully wrote PNG to: \(path)")
    }
    
    return success
}

func writeImageToStdout(image: CGImage, quality: Int, verbose: Bool) -> Bool {
    logMessage(verbose, "Writing PNG to stdout")
    
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
        return false
    }
    
    let options: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: CGFloat(quality) / 9.0
    ]
    
    CGImageDestinationAddImage(destination, image, options as CFDictionary)
    guard CGImageDestinationFinalize(destination) else {
        return false
    }
    
    let stdout = FileHandle.standardOutput
    stdout.write(data as Data)
    return true
}

// MARK: - Processing Functions

func processSinglePage(options: CommandLineOptions, pdfDocument: PDFDocument) throws -> Bool {
    let pageNumber = Int(options.page) ?? 1
    
    // Check for interruption
    try checkInterruption()
    
    logMessage(options.verbose, "Processing single page: \(pageNumber)")
    
    guard pageNumber >= 1 && pageNumber <= pdfDocument.pageCount else {
        throw PDF22PNGError.pageNotFound
    }
    
    guard let pdfPage = pdfDocument.page(at: pageNumber - 1) else {
        throw PDF22PNGError.renderFailed
    }
    
    guard let scaleSpec = parseScaleSpecification(options.resolution ?? options.scale) else {
        throw PDF22PNGError.invalidScale
    }
    
    let pageRect = pdfPage.bounds(for: .mediaBox)
    let scaleFactor = calculateScaleFactor(scale: scaleSpec, pageRect: pageRect)
    
    logMessage(options.verbose, "Calculated scale factor: \(scaleFactor)")
    
    // Check memory requirements before processing
    let memoryRequired = MemoryManager.shared.estimateMemoryRequirement(
        pageRect: pageRect, 
        scaleFactor: scaleFactor, 
        transparentBackground: options.transparent
    )
    
    if !MemoryManager.shared.canAllocateMemory(memoryRequired, verbose: options.verbose) {
        print("Warning: Insufficient memory for processing this page at current scale. Consider reducing scale factor.")
        // Continue anyway - user may want to try despite the warning
    }
    
    // Check for memory pressure before rendering
    try MemoryManager.shared.checkMemoryPressureDuringBatch(verbose: options.verbose)
    
    guard let image = renderPDFPageToImage(
        page: pdfPage,
        scaleFactor: scaleFactor,
        transparentBackground: options.transparent,
        verbose: options.verbose
    ) else {
        throw PDF22PNGError.renderFailed
    }
    
    // Check for interruption after rendering
    try checkInterruption()
    
    if let outputPath = options.outputPath, outputPath == "-" {
        if options.dryRun {
            print("[DRY-RUN] Would write \(image.width)x\(image.height) PNG to stdout")
            return true
        } else {
            return writeImageToStdout(image: image, quality: options.quality, verbose: options.verbose)
        }
    } else if let outputPath = options.outputPath ?? options.outputFile {
        return writeImageToFile(
            image: image,
            path: outputPath,
            quality: options.quality,
            verbose: options.verbose,
            dryRun: options.dryRun,
            forceOverwrite: options.forceOverwrite
        )
    } else {
        throw PDF22PNGError.invalidArgs
    }
}

func processBatchMode(options: CommandLineOptions, pdfDocument: PDFDocument) throws -> Bool {
    let totalPages = pdfDocument.pageCount
    let outputDir = options.directory ?? "."
    
    logMessage(options.verbose, "Processing in batch mode. Output directory: \(outputDir)")
    
    // Check for interruption
    try checkInterruption()
    
    // Create output directory
    if !options.dryRun {
        do {
            try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw PDF22PNGError.outputDir
        }
    }
    
    // Determine output prefix
    let inputBasename = (options.inputFile != nil && options.inputFile != "-") ? 
        URL(fileURLWithPath: options.inputFile!).deletingPathExtension().lastPathComponent : "output"
    let prefix = options.outputPath ?? inputBasename
    
    logMessage(options.verbose, "Using output prefix: \(prefix)")
    
    // Memory-based batch optimization
    guard let firstPage = pdfDocument.page(at: 0) else {
        throw PDF22PNGError.renderFailed
    }
    
    let pageRect = firstPage.bounds(for: .mediaBox)
    guard let scaleSpec = parseScaleSpecification(options.resolution ?? options.scale) else {
        throw PDF22PNGError.invalidScale
    }
    
    let scaleFactor = calculateScaleFactor(scale: scaleSpec, pageRect: pageRect)
    
    // Calculate optimal batch size based on memory
    let optimalBatchSize = MemoryManager.shared.calculateOptimalBatchSize(
        totalPages: totalPages,
        pageRect: pageRect,
        scaleFactor: scaleFactor,
        verbose: options.verbose
    )
    
    // Initialize progress reporter
    let progressReporter = ProgressReporter(totalPages: totalPages, verbose: options.verbose)
    
    if !options.dryRun {
        print("🚀 Starting batch conversion of \(totalPages) pages...")
        if options.verbose {
            print("   Output directory: \(outputDir)")
            print("   Output prefix: \(prefix)")
            print("   Batch size: \(optimalBatchSize) pages/chunk")
        }
    }
    
    // Process pages in memory-optimized chunks
    let chunks = stride(from: 1, through: totalPages, by: optimalBatchSize).map { start in
        Array(start..<min(start + optimalBatchSize, totalPages + 1))
    }
    
    for (chunkIndex, chunk) in chunks.enumerated() {
        // Check for interruption before each chunk
        try checkInterruption()
        
        // Check memory pressure before each chunk
        try MemoryManager.shared.checkMemoryPressureDuringBatch(verbose: options.verbose)
        
        progressReporter.reportChunkStart(chunkNumber: chunkIndex + 1, totalChunks: chunks.count, pagesInChunk: chunk.count)
        
        // Register cleanup for this chunk
        registerCleanupHandler {
            logMessage(options.verbose, "Cleaning up chunk \(chunkIndex + 1) resources...")
        }
        
        for pageNum in chunk {
            // Check for interruption for each page
            try checkInterruption()
            
            progressReporter.reportPageStart(pageNumber: pageNum)
            
            guard let pdfPage = pdfDocument.page(at: pageNum - 1) else {
                progressReporter.reportPageComplete(pageNumber: pageNum, success: false)
                continue
            }
            
            let pageRect = pdfPage.bounds(for: .mediaBox)
            let scaleFactor = calculateScaleFactor(scale: scaleSpec, pageRect: pageRect)
            
            // Check memory before each page in the chunk
            let memoryRequired = MemoryManager.shared.estimateMemoryRequirement(
                pageRect: pageRect,
                scaleFactor: scaleFactor,
                transparentBackground: options.transparent
            )
            
            if !MemoryManager.shared.canAllocateMemory(memoryRequired, verbose: false) {
                logMessage(options.verbose, "Warning: Insufficient memory for page \(pageNum), continuing anyway...")
            }
            
            guard let image = renderPDFPageToImage(
                page: pdfPage,
                scaleFactor: scaleFactor,
                transparentBackground: options.transparent,
                verbose: options.verbose
            ) else {
                progressReporter.reportPageComplete(pageNumber: pageNum, success: false)
                continue
            }
            
            let filename = String(format: "%@-%03d.png", prefix, pageNum)
            let outputPath = (outputDir as NSString).appendingPathComponent(filename)
            
            if options.dryRun {
                print("[DRY-RUN] Would create: \(filename) (\(image.width)x\(image.height) pixels)")
                progressReporter.reportPageComplete(pageNumber: pageNum, success: true, outputFile: filename)
            } else {
                let success = writeImageToFile(
                    image: image,
                    path: outputPath,
                    quality: options.quality,
                    verbose: options.verbose,
                    dryRun: options.dryRun,
                    forceOverwrite: options.forceOverwrite
                )
                progressReporter.reportPageComplete(pageNumber: pageNum, success: success, outputFile: success ? filename : nil)
            }
        }
        
        // Log memory status after each chunk in verbose mode
        if options.verbose && chunks.count > 1 {
            MemoryManager.shared.logMemoryStatus(verbose: true)
        }
        
        // Break if terminated
        if shouldTerminate {
            progressReporter.reportInterrupted()
            break
        }
    }
    
    // Final status report
    if options.dryRun {
        print("\n[DRY-RUN] Would convert \(totalPages) pages to PNG files")
    } else if !shouldTerminate {
        progressReporter.reportBatchComplete()
    }
    
    return true
}

// MARK: - Main Function

func main() -> Int32 {
    let options = parseCommandLine()
    
    if options.showHelp {
        printHelp()
        return 0
    }
    
    if options.showVersion {
        printVersion()
        return 0
    }
    
    // Install signal handlers for graceful shutdown
    installSignalHandlers()
    
    guard let inputFile = options.inputFile else {
        print("Error: Input PDF file required")
        print("Use --help for usage information")
        return 2
    }
    
    // Validate input arguments with comprehensive checks
    do {
        // Validate quality parameter
        try InputValidator.validateQuality(options.quality)
        
        // Validate scale specification
        try InputValidator.validateScale(options.resolution ?? options.scale)
        
        // Validate input file path (if not stdin)
        if inputFile != "-" {
            _ = try InputValidator.validateFilePath(inputFile, allowCreate: false)
        }
        
        // Validate output paths
        if let outputPath = options.outputPath, outputPath != "-" {
            _ = try InputValidator.validateFilePath(outputPath, allowCreate: true)
        }
        
        if let outputFile = options.outputFile, outputFile != "-" {
            _ = try InputValidator.validateFilePath(outputFile, allowCreate: true)
        }
        
        if let directory = options.directory {
            _ = try InputValidator.validateOutputDirectory(directory)
        }
        
        // Validate naming pattern if provided
        if let pattern = options.namingPattern {
            try InputValidator.validateNamingPattern(pattern)
        }
        
    } catch let error as PDF22PNGError {
        reportPDF22PNGError(error, context: "Input validation failed")
        return Int32(error.rawValue)
    } catch {
        print("Error: Input validation failed - \(error.localizedDescription)")
        return 2
    }
    
    logMessage(options.verbose, "Starting pdf22png processing")
    
    // Check initial memory status
    MemoryManager.shared.logMemoryStatus(verbose: options.verbose)
    
    // Register cleanup handler for this session
    registerCleanupHandler {
        logMessage(options.verbose, "Cleaning up resources on exit")
    }
    
    guard let pdfData = readPDFData(inputFile, verbose: options.verbose) else {
        print("Error: Failed to read PDF data")
        return 4
    }
    
    guard let pdfDocument = createPDFDocument(from: pdfData) else {
        print("Error: Invalid PDF document")
        return 7
    }
    
    if pdfDocument.isEncrypted {
        print("Error: PDF document is encrypted")
        return 8
    }
    
    let pageCount = pdfDocument.pageCount
    if pageCount == 0 {
        print("Error: PDF document has no pages")
        return 9
    }
    
    // Validate PDF complexity limits
    guard pageCount <= InputValidator.maxTotalPages else {
        print("Error: PDF has too many pages (\(pageCount)). Maximum allowed: \(InputValidator.maxTotalPages)")
        return Int32(PDF22PNGError.invalidArgs.rawValue)
    }
    
    logMessage(options.verbose, "PDF loaded: \(pageCount) pages")
    
    // Check if we should validate page ranges now that we know the total count
    if !options.allPages {
        do {
            if let pageNum = Int(options.page) {
                try InputValidator.validatePageNumber(pageNum, totalPages: pageCount)
            } else {
                try InputValidator.validatePageRange(options.page, totalPages: pageCount)
            }
        } catch let error as PDF22PNGError {
            reportPDF22PNGError(error, context: "Page validation failed")
            return Int32(error.rawValue)
        } catch {
            print("Error: Page validation failed - \(error.localizedDescription)")
            return 10
        }
    }
    
    let success: Bool
    do {
        if options.allPages || options.directory != nil {
            success = try processBatchMode(options: options, pdfDocument: pdfDocument)
        } else {
            success = try processSinglePage(options: options, pdfDocument: pdfDocument)
        }
    } catch let error as PDF22PNGError {
        reportPDF22PNGError(error, context: "Processing failed")
        return Int32(error.rawValue)
    } catch {
        print("Error: Processing failed - \(error.localizedDescription)")
        return 1
    }
    
    // Final cleanup
    performCleanup()
    
    return success ? 0 : 1
}

// Entry point
exit(main())