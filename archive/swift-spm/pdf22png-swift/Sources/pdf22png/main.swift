import Foundation
import ArgumentParser
import CoreGraphics
import Quartz
import ImageIO

@main
struct PDF22PNG: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf22png",
        abstract: "Convert PDF documents to PNG images",
        version: "2.0.0"
    )
    
    @Option(name: [.short, .long], help: "Page(s) to convert. Single page, range, or comma-separated")
    var page: String = "1"
    
    @Flag(name: [.short, .long], help: "Convert all pages")
    var all = false
    
    @Option(name: [.short, .long], help: "Set output DPI")
    var resolution: String?
    
    @Option(name: [.short, .long], help: "Scaling specification")
    var scale: String = "100%"
    
    @Flag(name: [.short, .long], help: "Preserve transparency")
    var transparent = false
    
    @Option(name: [.short, .long], help: "PNG compression quality (0-9)")
    var quality: Int = 6
    
    @Option(name: [.short, .long], help: "Output PNG file or prefix for batch mode")
    var output: String?
    
    @Option(name: [.short, .long], help: "Output directory for batch mode")
    var directory: String?
    
    @Flag(name: [.short, .long], help: "Verbose output")
    var verbose = false
    
    @Flag(name: [.short, .customLong("name", withSingleDash: false)], help: "Include extracted text in output filename")
    var includeText = false
    
    @Option(name: [.customShort("P"), .customLong("pattern", withSingleDash: false)], help: "Custom naming pattern for batch mode")
    var namingPattern: String?
    
    @Flag(name: [.customShort("D"), .customLong("dry-run", withSingleDash: false)], help: "Preview operations without writing files")
    var dryRun = false
    
    @Flag(name: [.short, .long], help: "Force overwrite existing files without prompting")
    var force = false
    
    @Argument(help: "Input PDF file. Use '-' for stdin")
    var input: String
    
    @Argument(help: "Output PNG file (single page mode) or prefix (batch mode)")
    var outputFile: String?
    
    mutating func run() throws {
        // Configure options from parsed arguments
        var options = ProcessingOptions()
        
        // Validate and set quality first
        try InputValidator.validateQuality(quality)
        options.pngQuality = quality
        
        // Handle resolution vs scale precedence with validation
        if let resolutionStr = resolution {
            let dpiStr = resolutionStr.hasSuffix("dpi") ? resolutionStr : resolutionStr + "dpi"
            try InputValidator.validateScale(dpiStr)
            if let scaleSpec = parseScaleSpecification(dpiStr) {
                options.scale = scaleSpec
            } else {
                throw ValidationError("Invalid resolution specification: \(resolutionStr)")
            }
        } else {
            try InputValidator.validateScale(scale)
            if let scaleSpec = parseScaleSpecification(scale) {
                options.scale = scaleSpec
            } else {
                throw ValidationError("Invalid scale specification: \(scale)")
            }
        }
        
        // Set batch mode
        options.batchMode = all || directory != nil
        
        // Handle page specification with validation
        if !all {
            options.pageRange = page
            if let pageNum = Int(page) {
                // Note: Full validation will happen after PDF is loaded and we know total pages
                guard pageNum >= 1 && pageNum <= InputValidator.maxPageNumber else {
                    throw ValidationError("Invalid page number: \(page). Must be between 1 and \(InputValidator.maxPageNumber).")
                }
                options.pageNumber = pageNum
            }
        }
        
        // Validate naming pattern if provided
        if let pattern = namingPattern {
            try InputValidator.validateNamingPattern(pattern)
        }
        
        // Set other options
        options.transparentBackground = transparent
        options.verbose = verbose
        options.includeText = includeText
        options.namingPattern = namingPattern
        options.dryRun = dryRun
        options.forceOverwrite = force
        
        // Handle input/output paths with validation
        if input != "-" {
            // Validate input file path
            let validatedInput = try InputValidator.validateFilePath(input, allowCreate: false)
            options.inputPath = validatedInput
        } else {
            options.inputPath = nil // stdin
        }
        
        // Determine and validate output path
        if let explicitOutput = output {
            if explicitOutput != "-" {
                let validatedOutput = try InputValidator.validateFilePath(explicitOutput, allowCreate: true)
                options.outputPath = validatedOutput
            } else {
                options.outputPath = "-" // stdout
            }
        } else if let fileArg = outputFile {
            if fileArg != "-" {
                let validatedOutput = try InputValidator.validateFilePath(fileArg, allowCreate: true)
                options.outputPath = validatedOutput
            } else {
                options.outputPath = "-" // stdout
            }
        } else if options.inputPath == nil && !options.batchMode {
            // stdin to stdout for single page
            options.outputPath = "-"
        } else if !options.batchMode && options.inputPath != nil {
            throw ValidationError("Output PNG file required when input is a file and not in batch mode.")
        }
        
        // Set and validate output directory
        if let dir = directory {
            let validatedDir = try InputValidator.validateOutputDirectory(dir)
            options.outputDirectory = validatedDir
            options.batchMode = true
        } else if options.batchMode {
            options.outputDirectory = "."
        }
        
        // Validate batch mode constraints
        if options.batchMode && options.outputPath == "-" {
            throw ValidationError("Cannot output to stdout in batch mode.")
        }
        
        // Install signal handlers
        installSignalHandlers()
        
        // Load PDF
        logMessage(options.verbose, "Starting pdf22png tool.")
        
        // Check initial memory status
        MemoryManager.logMemoryStatus(verbose: options.verbose)
        
        if !options.verbose {
            print("📄 Loading PDF...", terminator: "")
            fflush(stdout)
        }
        
        guard let pdfData = readPDFData(options.inputPath, verbose: options.verbose) else {
            if !options.verbose {
                print("\r❌ Loading PDF failed    ")
            }
            throw RuntimeError("Failed to read PDF data")
        }
        
        if !options.verbose {
            print("\r✅ PDF loaded successfully")
        }
        
        guard let pdfDocument = createPDFDocument(from: pdfData) else {
            throw RuntimeError("Failed to create PDF document. Ensure the input is a valid PDF.")
        }
        
        // Validate PDF
        if pdfDocument.isEncrypted {
            throw RuntimeError("PDF document is encrypted. Password-protected PDFs are not currently supported.")
        }
        
        let pageCount = pdfDocument.numberOfPages
        if pageCount == 0 {
            throw RuntimeError("PDF document has no pages.")
        }
        
        // Validate PDF complexity limits
        guard pageCount <= InputValidator.maxTotalPages else {
            throw RuntimeError("PDF has too many pages (\(pageCount)). Maximum allowed: \(InputValidator.maxTotalPages)")
        }
        
        logMessage(options.verbose, "PDF document loaded successfully. Total pages: \(pageCount)")
        
        // Analyze PDF complexity to prevent resource exhaustion
        let complexityInfo: PDFComplexityInfo
        do {
            complexityInfo = try PDFComplexityAnalyzer.analyzePDFComplexity(pdfDocument, verbose: options.verbose)
        } catch {
            reportPDF22PNGError(error as? PDF22PNGError ?? PDF22PNGError.resourceExhaustion)
            throw error
        }
        
        // Adjust scale factor based on complexity if needed
        let requestedScale = calculateScaleFactor(scale: options.scale, pageRect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let recommendedScale = PDFComplexityAnalyzer.getRecommendedScale(for: complexityInfo, requestedScale: requestedScale)
        
        if recommendedScale < requestedScale {
            logMessage(options.verbose, "⚠️  Scale factor reduced from \(requestedScale) to \(recommendedScale) due to PDF complexity")
            print("Warning: Scale factor reduced to \(recommendedScale) due to high PDF complexity. Use --force to override.")
            
            if !options.forceOverwrite {
                // Adjust the scale in options
                if options.scale.isPercentage {
                    options.scale.scaleFactor = recommendedScale
                } else if options.scale.isDPI {
                    options.scale.dpi = recommendedScale * 72.0
                } else {
                    options.scale.scaleFactor = recommendedScale
                }
            }
        }
        
        // Now validate page specifications with actual page count
        if let pageRange = options.pageRange, !options.batchMode {
            try InputValidator.validatePageRange(pageRange, totalPages: pageCount)
        }
        
        // Validate specific page number if not in batch mode
        if !options.batchMode {
            try InputValidator.validatePageNumber(options.pageNumber, totalPages: pageCount)
        }
        
        // Process
        let success: Bool
        if options.batchMode {
            success = try processBatchMode(pdfDocument: pdfDocument, options: &options)
        } else {
            success = try processSinglePage(pdfDocument: pdfDocument, options: &options)
        }
        
        if !success {
            throw ExitCode.failure
        }
        
        logMessage(options.verbose, "Processing finished successfully.")
    }
    
    /// Enhanced error handling with context
    func validate() throws {
        do {
            try run()
        } catch let error as ValidationError {
            reportEnhancedError(error, context: "Input validation failed")
            throw ExitCode.failure
        } catch let error as PDF22PNGError {
            reportPDF22PNGError(error)
            throw ExitCode.failure
        } catch {
            reportEnhancedError(error, context: "Processing failed")
            throw ExitCode.failure
        }
    }
}

// MARK: - Error Types

enum ValidationError: LocalizedError {
    case message(String)
    
    init(_ message: String) {
        self = .message(message)
    }
    
    var errorDescription: String? {
        switch self {
        case .message(let msg):
            return msg
        }
    }
}

enum RuntimeError: LocalizedError {
    case message(String)
    
    init(_ message: String) {
        self = .message(message)
    }
    
    var errorDescription: String? {
        switch self {
        case .message(let msg):
            return msg
        }
    }
}

// MARK: - Enhanced Signal Handling

var shouldTerminate = false
private var cleanupHandlers: [() -> Void] = []
private let cleanupQueue = DispatchQueue(label: "cleanup", qos: .utility)

// Resource management
private var activeFileHandles: Set<FileHandle> = []
private var tempFiles: Set<String> = []
private var activeContexts: Set<ObjectIdentifier> = []

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
    cleanupQueue.async {
        performCleanup()
        
        // Give a brief moment for current operations to finish
        usleep(100_000) // 100ms
        
        fputs("✅ Cleanup complete. Exiting.\n", stderr)
        fflush(stderr)
        
        // Force exit if cleanup takes too long
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            fputs("⚠️  Force exiting due to timeout.\n", stderr)
            fflush(stderr)
            _exit(1)
        }
    }
}

private func performCleanup() {
    // Execute registered cleanup handlers
    for handler in cleanupHandlers {
        handler()
    }
    
    // Close file handles
    for handle in activeFileHandles {
        do {
            try handle.close()
        } catch {
            // Ignore errors during cleanup
        }
    }
    activeFileHandles.removeAll()
    
    // Remove temporary files
    let fileManager = FileManager.default
    for tempFile in tempFiles {
        do {
            if fileManager.fileExists(atPath: tempFile) {
                try fileManager.removeItem(atPath: tempFile)
            }
        } catch {
            // Ignore errors during cleanup
        }
    }
    tempFiles.removeAll()
    
    // Clear other resources
    activeContexts.removeAll()
    cleanupHandlers.removeAll()
}

// MARK: - Resource Registration Functions

func registerFileHandle(_ handle: FileHandle) {
    activeFileHandles.insert(handle)
}

func unregisterFileHandle(_ handle: FileHandle) {
    activeFileHandles.remove(handle)
}

func registerTempFile(_ path: String) {
    tempFiles.insert(path)
}

func unregisterTempFile(_ path: String) {
    tempFiles.remove(path)
}

func registerContext<T: AnyObject>(_ context: T) {
    activeContexts.insert(ObjectIdentifier(context))
}

func unregisterContext<T: AnyObject>(_ context: T) {
    activeContexts.remove(ObjectIdentifier(context))
}

func registerCleanupHandler(_ handler: @escaping () -> Void) {
    cleanupHandlers.append(handler)
}

// MARK: - Safe Resource Wrapper

class SafeResource<T> {
    private let resource: T
    private let cleanup: (T) -> Void
    private var isReleased = false
    private let lock = NSLock()
    
    init(_ resource: T, cleanup: @escaping (T) -> Void) {
        self.resource = resource
        self.cleanup = cleanup
        
        // Register for automatic cleanup on signal
        registerCleanupHandler { [weak self] in
            self?.release()
        }
    }
    
    func use<R>(_ block: (T) throws -> R) rethrows -> R? {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isReleased && !shouldTerminate else {
            return nil
        }
        
        return try block(resource)
    }
    
    func release() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isReleased else { return }
        
        isReleased = true
        cleanup(resource)
    }
    
    deinit {
        release()
    }
}

// MARK: - Interruption-Safe Operations

func performWithCleanup<T>(
    operation: () throws -> T,
    cleanup: @escaping () -> Void
) throws -> T {
    registerCleanupHandler(cleanup)
    
    defer {
        // Remove this specific cleanup handler
        cleanupHandlers.removeAll { handler in
            // This is a simplified removal - in production you'd want a more precise way
            // to identify and remove specific handlers
            cleanup()
            return true
        }
    }
    
    if shouldTerminate {
        throw PDF22PNGError.signalInterruption
    }
    
    return try operation()
}

func checkInterruption() throws {
    if shouldTerminate {
        throw PDF22PNGError.signalInterruption
    }
}

// MARK: - Processing Functions

func processSinglePage(pdfDocument: PDFDocument, options: inout ProcessingOptions) throws -> Bool {
    logMessage(options.verbose, "Processing single page: \(options.pageNumber)")
    
    if !options.verbose {
        print("🔄 Processing page \(options.pageNumber)...", terminator: "")
        fflush(stdout)
    }
    
    guard options.pageNumber >= 1 && options.pageNumber <= pdfDocument.numberOfPages else {
        if !options.verbose {
            print("\r❌ Page \(options.pageNumber) not found    ")
        }
        print("Error: Page \(options.pageNumber) does not exist (document has \(pdfDocument.numberOfPages) pages).")
        return false
    }
    
    guard let pdfPage = pdfDocument.page(at: options.pageNumber - 1) else {
        print("Error: Failed to get page \(options.pageNumber).")
        return false
    }
    
    let pageRect = pdfPage.bounds(for: .mediaBox)
    let scaleFactor = calculateScaleFactor(scale: options.scale, pageRect: pageRect)
    logMessage(options.verbose, "Calculated scale factor for page \(options.pageNumber): \(scaleFactor)")
    
    // Check memory requirements for single page processing
    let memoryRequired = MemoryManager.estimateMemoryRequirement(pageRect: pageRect, scaleFactor: scaleFactor, transparentBackground: options.transparentBackground)
    
    if !MemoryManager.canAllocateMemory(memoryRequired, verbose: options.verbose) {
        print("Warning: Insufficient memory for processing this page at current scale. Consider reducing scale factor.")
        // Continue anyway - user may want to try despite the warning
    }
    
    guard let image = renderPDFPageToImage(
        page: pdfPage,
        scaleFactor: scaleFactor,
        transparentBackground: options.transparentBackground,
        verbose: options.verbose
    ) else {
        print("Error: Failed to render PDF page \(options.pageNumber).")
        return false
    }
    
    let success: Bool
    if let outputPath = options.outputPath, outputPath == "-" {
        if options.dryRun {
            let width = image.width
            let height = image.height
            if !options.verbose {
                print("\r✅ Page \(options.pageNumber) processed successfully")
            }
            print("[DRY-RUN] Would write PNG to stdout")
            print("          Page: \(options.pageNumber), Dimensions: \(width)x\(height)")
            success = true
        } else {
            logMessage(options.verbose, "Writing image to stdout.")
            success = writeImageToStdout(image: image, quality: options.pngQuality, verbose: options.verbose)
            if !options.verbose {
                print(success ? "\r✅ Page \(options.pageNumber) written to stdout" : "\r❌ Failed to write page \(options.pageNumber)")
            }
        }
    } else if let outputPath = options.outputPath {
        logMessage(options.verbose, "Writing image to file: \(outputPath)")
        success = writeImageToFile(
            image: image,
            path: outputPath,
            quality: options.pngQuality,
            verbose: options.verbose,
            dryRun: options.dryRun,
            forceOverwrite: options.forceOverwrite
        )
        if !options.verbose {
            print(success ? "\r✅ Page \(options.pageNumber) saved to \(outputPath)" : "\r❌ Failed to save page \(options.pageNumber)")
        }
    } else {
        if !options.verbose {
            print("\r❌ No output path specified")
        }
        print("Error: Output path not specified for single page mode.")
        success = false
    }
    
    return success
}

func processBatchMode(pdfDocument: PDFDocument, options: inout ProcessingOptions) throws -> Bool {
    logMessage(options.verbose, "Processing in batch mode. Output directory: \(options.outputDirectory ?? ".")")
    
    let outputDir = options.outputDirectory ?? "."
    
    if options.dryRun {
        print("[DRY-RUN] Would create directory: \(outputDir)")
    } else {
        do {
            try FileManager.default.createDirectory(
                atPath: outputDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("Error: Failed to create output directory '\(outputDir)': \(error.localizedDescription)")
            return false
        }
    }
    
    let totalPageCount = pdfDocument.numberOfPages
    let prefix = getOutputPrefix(options: options)
    logMessage(options.verbose, "Using output prefix: \(prefix)")
    
    // Determine pages to process
    let pagesToProcess: [Int]
    if let pageRange = options.pageRange, !options.batchMode || pageRange != "1" {
        // Validate page range before parsing
        do {
            try InputValidator.validatePageRange(pageRange, totalPages: totalPageCount)
        } catch {
            print("Error: \(error.localizedDescription)")
            return false
        }
        
        guard let pages = parsePageRange(pageRange, totalPages: totalPageCount) else {
            print("Error: Invalid page range specification: \(pageRange)")
            return false
        }
        pagesToProcess = pages
        logMessage(options.verbose, "Processing \(pages.count) pages from range: \(pageRange)")
    } else {
        pagesToProcess = Array(1...totalPageCount)
        logMessage(options.verbose, "Processing all \(totalPageCount) pages")
    }
    
    // Memory-based batch optimization
    guard let firstPage = pdfDocument.page(at: 0) else {
        print("Error: Cannot access first page for memory estimation")
        return false
    }
    
    let pageRect = firstPage.bounds(for: .mediaBox)
    let scaleFactor = calculateScaleFactor(scale: options.scale, pageRect: pageRect)
    
    // Check if we can handle the memory requirements
    let memoryPerPage = MemoryManager.estimateMemoryRequirement(pageRect: pageRect, scaleFactor: scaleFactor, transparentBackground: options.transparentBackground)
    
    if !MemoryManager.canAllocateMemory(memoryPerPage, verbose: options.verbose) {
        logMessage(options.verbose, "Warning: Insufficient memory for optimal processing. Consider reducing scale factor.")
        // Continue with smaller batch size rather than failing
    }
    
    // Initialize resource manager for batch operations
    let resourceManager = BatchResourceManager()
    
    // Calculate optimal concurrency based on memory and resource constraints
    let memoryOptimalConcurrency = MemoryManager.calculateOptimalBatchSize(
        totalPages: pagesToProcess.count,
        pageRect: pageRect,
        scaleFactor: scaleFactor,
        verbose: options.verbose
    )
    
    let optimalConcurrency = resourceManager.getRecommendedConcurrency(
        maxRequested: memoryOptimalConcurrency,
        verbose: options.verbose
    )
    
    logMessage(options.verbose, "Using concurrency level: \(optimalConcurrency) pages (memory-optimal: \(memoryOptimalConcurrency))")
    
    var successCount = 0
    var failCount = 0
    var processedCount = 0
    
    // Initialize progress reporter
    let progressReporter = ProgressReporter(totalItems: pagesToProcess.count, verbose: options.verbose)
    
    logMessage(options.verbose, "Starting batch conversion of \(pagesToProcess.count) pages...")
    
    // Process pages in adaptively-sized chunks
    var remainingPages = pagesToProcess
    var chunkIndex = 0
    var currentChunkSize = optimalConcurrency
    var totalProcessingTime: TimeInterval = 0
    var processedInBatch = 0
    
    while !remainingPages.isEmpty && !shouldTerminate {
        // Check for interruption
        try checkInterruption()
        
        // Adaptively adjust chunk size based on performance
        if processedInBatch > 0 && chunkIndex > 0 {
            let successRate = Double(successCount) / Double(processedInBatch)
            let avgProcessingTime = totalProcessingTime / Double(processedInBatch)
            
            let newChunkSize = MemoryManager.getAdaptiveBatchSize(
                currentBatchSize: currentChunkSize,
                successRate: successRate,
                averageProcessingTime: avgProcessingTime,
                pageRect: pageRect,
                scaleFactor: scaleFactor,
                verbose: options.verbose
            )
            
            if newChunkSize != currentChunkSize {
                logMessage(options.verbose, "Adjusting batch size from \(currentChunkSize) to \(newChunkSize) based on performance")
                currentChunkSize = newChunkSize
            }
        }
        
        // Take the next chunk of pages
        let chunk = Array(remainingPages.prefix(currentChunkSize))
        remainingPages = Array(remainingPages.dropFirst(currentChunkSize))
        
        // Check resource limits before each chunk
        do {
            try resourceManager.canProcessPage(verbose: options.verbose)
            try MemoryManager.checkMemoryPressureDuringBatch(verbose: options.verbose)
        } catch {
            print("Warning: Resource limits exceeded. \(error.localizedDescription)")
            // Reduce chunk size and retry with smaller batch
            if currentChunkSize > 1 {
                currentChunkSize = max(1, currentChunkSize / 2)
                logMessage(options.verbose, "Reducing chunk size to \(currentChunkSize) due to resource constraints")
                // Put the chunk back
                remainingPages = chunk + remainingPages
                continue
            } else {
                // Can't reduce further, break out
                break
            }
        }
        
        let totalChunks = (pagesToProcess.count + currentChunkSize - 1) / currentChunkSize
        logMessage(options.verbose, "Processing chunk \(chunkIndex + 1) (\(chunk.count) pages, batch size: \(currentChunkSize))")
        
        // Log resource statistics
        if options.verbose {
            let stats = resourceManager.getStatistics()
            logMessage(options.verbose, "Resource status: \(stats.processed) processed, \(stats.failed) failed, \(Int(stats.elapsed))s elapsed, \(stats.diskUsage/(1024*1024))MB temp, \(stats.fileHandles) handles")
        }
        
        // Register cleanup for this chunk
        let chunkCleanup = {
            logMessage(options.verbose, "Cleaning up chunk \(chunkIndex + 1) resources...")
        }
        registerCleanupHandler(chunkCleanup)
        
        defer {
            // Remove chunk-specific cleanup handler when done
            cleanupHandlers.removeAll { _ in 
                chunkCleanup()
                return false // Don't actually remove, just execute
            }
        }
        
        // Track chunk processing time
        let chunkStartTime = Date()
        
        // Use TaskGroup for parallel processing within each chunk
        await withTaskGroup(of: (success: Bool, pageNum: Int, processingTime: TimeInterval).self) { group in
            for pageNum in chunk {
                // Check for interruption before adding each task
                if shouldTerminate {
                    logMessage(options.verbose, "Termination requested, stopping chunk processing")
                    break
                }
                
                group.addTask { [options] in
                    var localOptions = options
                    
                    // Check interruption at start of each page task
                    guard !shouldTerminate else {
                        return (false, pageNum, 0)
                    }
                    
                    // Start tracking page processing
                    let startTime = Date()
                    resourceManager.startPageProcessing(pageNum: pageNum, verbose: localOptions.verbose)
                    
                    let result = await processBatchPage(
                        pageNum: pageNum,
                        pdfDocument: pdfDocument,
                        outputDir: outputDir,
                        prefix: prefix,
                        totalPageCount: totalPageCount,
                        options: &localOptions,
                        resourceManager: resourceManager
                    )
                    
                    // Record processing completion
                    let processingTime = Date().timeIntervalSince(startTime)
                    resourceManager.finishPageProcessing(
                        pageNum: pageNum,
                        success: result.success,
                        processingTime: processingTime,
                        verbose: localOptions.verbose
                    )
                    
                    return (result.success, pageNum, processingTime)
                }
            }
            
            // Collect results for this chunk
            for await (success, pageNum, processingTime) in group {
                if shouldTerminate {
                    logMessage(options.verbose, "Termination requested during result collection")
                    break
                }
                
                if success {
                    successCount += 1
                } else {
                    failCount += 1
                }
                processedCount += 1
                processedInBatch += 1
                totalProcessingTime += processingTime
                
                // Report progress using enhanced progress reporter
                progressReporter.reportProgress(successful: success)
            }
        }
        
        // Log chunk completion time
        let chunkProcessingTime = Date().timeIntervalSince(chunkStartTime)
        logMessage(options.verbose, "Chunk \(chunkIndex + 1) completed in \(String(format: "%.2f", chunkProcessingTime))s")
        
        // Log memory status after each chunk in verbose mode
        if options.verbose {
            MemoryManager.logMemoryStatus(verbose: true)
        }
        
        // Increment chunk index
        chunkIndex += 1
        
        // Break if terminated
        if shouldTerminate {
            logMessage(options.verbose, "Processing terminated after chunk \(chunkIndex)")
            break
        }
    }
    
    // Finalize progress reporting
    progressReporter.finish()
    
    // Clean up memory pool and log final statistics
    if options.verbose {
        let poolStats = globalBitmapPool.getStatistics()
        logMessage(options.verbose, "Memory pool final stats: \(poolStats.total) contexts, \(poolStats.memoryMB)MB")
    }
    globalBitmapPool.cleanupOldContexts(maxAge: 0) // Clean up all unused contexts
    
    // Report results
    if options.dryRun {
        print("[DRY-RUN] Would convert \(pagesToProcess.count) pages to PNG files")
    } else if shouldTerminate {
        print("⚠️  Batch processing interrupted: \(successCount) pages converted before interruption, \(failCount) pages failed.")
    }
    
    return successCount > 0
}

@Sendable
func processBatchPage(
    pageNum: Int,
    pdfDocument: PDFDocument,
    outputDir: String,
    prefix: String,
    totalPageCount: Int,
    options: inout ProcessingOptions,
    resourceManager: BatchResourceManager
) async -> (success: Bool, pageNum: Int) {
    logMessage(options.verbose, "Starting processing for page \(pageNum)...")
    
    // Check for interruption at start of page processing
    guard !shouldTerminate else {
        logMessage(options.verbose, "Page \(pageNum) processing skipped due to termination request")
        return (false, pageNum)
    }
    
    // Set up timeout monitoring
    let timeout = PageProcessingTimeout()
    timeout.startTimeout(pageNum: pageNum) {
        // Timeout handler - set termination flag
        shouldTerminate = true
    }
    defer {
        timeout.cancelTimeout()
    }
    
    guard let pdfPage = pdfDocument.page(at: pageNum - 1) else {
        print("Warning: Failed to get page \(pageNum), skipping.")
        return (false, pageNum)
    }
    
    let pageRect = pdfPage.bounds(for: .mediaBox)
    let scaleFactor = calculateScaleFactor(scale: options.scale, pageRect: pageRect)
    logMessage(options.verbose, "Calculated scale factor for page \(pageNum): \(scaleFactor)")
    
    guard let image = renderPDFPageToImage(
        page: pdfPage,
        scaleFactor: scaleFactor,
        transparentBackground: options.transparentBackground,
        verbose: options.verbose
    ) else {
        print("Warning: Failed to render page \(pageNum), skipping.")
        return (false, pageNum)
    }
    
    var extractedText: String?
    
    // Extract text if needed
    if options.includeText || (options.namingPattern?.contains("{text}") ?? false) {
        // Extract text from PDF page first
        var pageText = extractTextFromPDFPage(page: pdfPage)
        
        // If no text found, try OCR
        if pageText == nil || pageText!.isEmpty {
            logMessage(options.verbose, "No text extracted from PDF, attempting OCR for page \(pageNum)")
            pageText = await performOCROnImage(image: image)
        }
        
        // Slugify the text if found
        if let text = pageText, !text.isEmpty {
            extractedText = slugifyText(text, maxLength: 30)
            logMessage(options.verbose, "Extracted text for page \(pageNum): \(extractedText ?? "")")
        } else {
            logMessage(options.verbose, "No text found for page \(pageNum)")
        }
    }
    
    // Generate filename
    let filename: String
    if let pattern = options.namingPattern {
        filename = formatFilenameWithPattern(
            pattern: pattern,
            basename: prefix,
            pageNum: pageNum,
            totalPages: totalPageCount,
            extractedText: extractedText
        ) + ".png"
    } else {
        let includeTextPart = options.includeText ? extractedText : nil
        filename = formatFilenameWithPattern(
            pattern: nil,
            basename: prefix,
            pageNum: pageNum,
            totalPages: totalPageCount,
            extractedText: includeTextPart
        ) + ".png"
    }
    
    let outputPath = (outputDir as NSString).appendingPathComponent(filename)
    logMessage(options.verbose, "Writing image for page \(pageNum) to file: \(outputPath)")
    
    let success = writeImageToFile(
        image: image,
        path: outputPath,
        quality: options.pngQuality,
        verbose: options.verbose,
        dryRun: options.dryRun,
        forceOverwrite: options.forceOverwrite
    )
    
    if !success {
        print("Warning: Failed to write page \(pageNum) to '\(outputPath)', skipping.")
    }
    
    logMessage(options.verbose, "Finished processing for page \(pageNum).")
    return (success, pageNum)
}

// MARK: - Enhanced Error Reporting

func reportEnhancedError(_ error: Error, context: String? = nil) {
    // Print error with enhanced formatting
    print("❌ Error: \(error.localizedDescription)")
    
    if let ctx = context {
        print("📍 Context: \(ctx)")
    }
    
    // Provide specific troubleshooting based on error type
    if let validationError = error as? ValidationError {
        handleValidationError(validationError)
    } else if let pdfError = error as? PDF22PNGError {
        handlePDF22PNGError(pdfError)
    } else {
        // Generic troubleshooting
        print("\n💡 Troubleshooting:")
        print("   • Run with --verbose flag for detailed information")
        print("   • Check that all file paths are correct and accessible")
        print("   • Verify the PDF file opens correctly in Preview")
        print("   • Try with a smaller scale factor if processing large documents")
        print("   • Check available disk space and memory")
        print("   • Run pdf22png --help for usage examples")
    }
    
    print("\n🆘 For additional help:")
    print("   • Documentation: See man pdf22png")
    print("   • Examples: pdf22png --help")
    print("   • Issues: https://github.com/twardoch/pdf22png/issues")
}

func handleValidationError(_ error: ValidationError) {
    print("\n💡 Input Validation Help:")
    
    switch error {
    case .message(let msg):
        if msg.contains("path") {
            print("   • Use absolute paths to avoid confusion")
            print("   • Check that the directory exists")
            print("   • Verify you have read/write permissions")
            print("   • Avoid special characters in file names")
        } else if msg.contains("page") {
            print("   • PDF pages start at 1, not 0")
            print("   • Use --verbose to see total page count")
            print("   • Valid formats: 5 (single), 1-10 (range), 1,3,5-10 (list)")
        } else if msg.contains("quality") {
            print("   • PNG quality must be between 0-9")
            print("   • Recommended: 6 (default) or 9 (best)")
        } else if msg.contains("scale") {
            print("   • Valid formats: 150%, 2.0, 800x600, 300dpi")
            print("   • Percentage: append % (e.g., 150%)")
            print("   • Factor: decimal number (e.g., 1.5)")
            print("   • Dimensions: WIDTHxHEIGHT (e.g., 1024x768)")
            print("   • DPI: number + dpi (e.g., 300dpi)")
        } else {
            print("   • Check the input format and try again")
            print("   • Use --help to see valid input formats")
        }
    }
}

func handlePDF22PNGError(_ error: PDF22PNGError) {
    print("\n💡 PDF Processing Help:")
    
    switch error {
    case .encryptedPDF:
        print("   • Remove password protection:")
        print("     - In Preview: File → Export As → PDF (uncheck Encrypt)")
        print("     - Command line: qpdf --decrypt --password=PASSWORD input.pdf output.pdf")
        
    case .emptyPDF:
        print("   • The PDF appears to be empty or corrupted")
        print("   • Try opening it in Preview to verify it's readable")
        print("   • Check the file size - very small files may be empty")
        
    case .memoryPressure:
        print("   • System is under memory pressure")
        print("   • Close other applications to free memory")
        print("   • Use a smaller scale factor: --scale 50%")
        print("   • Process fewer pages at once")
        
    case .resourceExhaustion:
        print("   • PDF is too complex for current settings")
        print("   • Reduce scale factor: --scale 100% or --scale 50%")
        print("   • Process pages in smaller batches")
        print("   • Consider using lower DPI: --resolution 150dpi")
        
    case .renderFailed:
        print("   • Failed to render PDF page")
        print("   • PDF may have complex graphics or be corrupted")
        print("   • Try with a different page: --page 1")
        print("   • Use smaller scale factor")
        
    case .invalidPDF:
        print("   • File is not a valid PDF")
        print("   • Check file extension and content")
        print("   • Try opening in Preview to verify")
        
    case .fileRead:
        print("   • Cannot read the input file")
        print("   • Check file permissions: ls -la filename.pdf")
        print("   • Verify file exists and path is correct")
        
    case .fileWrite:
        print("   • Cannot write to output location")
        print("   • Check disk space: df -h")
        print("   • Verify write permissions to output directory")
        print("   • Try a different output location")
        
    default:
        print("   • Run with --verbose for detailed information")
        print("   • Try with a simpler PDF first")
    }
    
    // Add context-aware suggestions
    if let suggestion = error.recoverySuggestion {
        print("\n🔧 Quick Fix:")
        print("   \(suggestion)")
    }
}