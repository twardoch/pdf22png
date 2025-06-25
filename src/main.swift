import Foundation
import CoreGraphics
import PDFKit
import Dispatch

// MARK: - Main Entry Point

// Helper function for logging is defined in MemoryManager.swift

// Global references for signal handling compatibility
var shouldTerminate: Bool { return SignalHandler.shared.isTerminated }
func installSignalHandlers() { SignalHandler.shared.installSignalHandlers() }
func registerCleanupHandler(_ handler: @escaping () -> Void) { SignalHandler.shared.registerCleanupHandler(handler) }
func checkInterruption() throws { try SignalHandler.shared.checkInterruption() }
func performCleanup() { ResourceManager.shared.cleanupAllResources() }

func main() async -> Int32 {
    let options = ArgumentParser.parseArguments()
    
    if options.showHelp {
        OutputFormatter.printHelp()
        return 0
    }
    
    if options.showVersion {
        OutputFormatter.printVersion()
        return 0
    }
    
    // Install signal handlers for graceful shutdown
    installSignalHandlers()
    
    guard let inputFile = options.inputFile else {
        print("Error: Input PDF file required")
        print("Use --help for usage information")
        return 2
    }
    
    // Validate input arguments
    do {
        try ArgumentParser.validateArguments(options)
        
        // Additional validation with InputValidator
        try InputValidator.validateQuality(options.quality)
        try InputValidator.validateScale(options.effectiveScale)
        
        if inputFile != "-" {
            _ = try InputValidator.validateFilePath(inputFile, allowCreate: false)
        }
        
        if let outputPath = options.outputPath, outputPath != "-" {
            _ = try InputValidator.validateFilePath(outputPath, allowCreate: true)
        }
        
        if let outputFile = options.outputFile, outputFile != "-" {
            _ = try InputValidator.validateFilePath(outputFile, allowCreate: true)
        }
        
        if let directory = options.directory {
            _ = try InputValidator.validateOutputDirectory(directory)
        }
        
        if let pattern = options.namingPattern {
            try InputValidator.validateNamingPattern(pattern)
        }
        
    } catch let error as PDF22PNGError {
        ErrorReporter.reportError(error, context: "Input validation failed")
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
    
    // Load PDF document
    guard let pdfData = PDFProcessor.shared.readPDFData(inputFile, verbose: options.verbose) else {
        print("Error: Failed to read PDF data")
        return 4
    }
    
    guard let pdfDocument = PDFProcessor.shared.createPDFDocument(from: pdfData) else {
        print("Error: Invalid PDF document")
        return 7
    }
    
    if pdfDocument.isEncrypted {
        print("Error: PDF document is encrypted")
        return 8
    }
    
    let pageCount = PDFProcessor.shared.getPageCount(pdfDocument)
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
    
    // Validate page ranges now that we know the total count
    if !options.isBatchMode {
        do {
            if let pageNum = Int(options.page) {
                try InputValidator.validatePageNumber(pageNum, totalPages: pageCount)
            } else {
                try InputValidator.validatePageRange(options.page, totalPages: pageCount)
            }
        } catch let error as PDF22PNGError {
            ErrorReporter.reportError(error, context: "Page validation failed")
            return Int32(error.rawValue)
        } catch {
            print("Error: Page validation failed - \(error.localizedDescription)")
            return 10
        }
    }
    
    // Process PDF
    let success: Bool
    do {
        if options.isBatchMode {
            success = try await processBatchMode(options: options, pdfDocument: pdfDocument)
        } else {
            success = try processSinglePage(options: options, pdfDocument: pdfDocument)
        }
    } catch let error as PDF22PNGError {
        ErrorReporter.reportError(error, context: "Processing failed")
        return Int32(error.rawValue)
    } catch {
        print("Error: Processing failed - \(error.localizedDescription)")
        return 1
    }
    
    // Final cleanup
    performCleanup()
    
    return success ? 0 : 1
}

// MARK: - Processing Functions

func processSinglePage(options: ProcessingOptions, pdfDocument: PDFDocument) throws -> Bool {
    let pageNumber = Int(options.page) ?? 1
    
    try checkInterruption()
    
    logMessage(options.verbose, "Processing single page: \(pageNumber)")
    
    guard let pdfPage = PDFProcessor.shared.extractPage(pdfDocument, pageNumber: pageNumber) else {
        throw PDF22PNGError.pageNotFound
    }
    
    guard let scaleSpec = ScaleParser.parseScaleSpecification(options.effectiveScale) else {
        throw PDF22PNGError.invalidScale
    }
    
    let pageRect = pdfPage.bounds(for: .mediaBox)
    let scaleFactor = ImageRenderer.shared.calculateScaleFactor(spec: scaleSpec, pageRect: pageRect)
    
    logMessage(options.verbose, "Calculated scale factor: \(scaleFactor)")
    
    // Check memory requirements
    let memoryRequired = MemoryManager.shared.estimateMemoryRequirement(
        pageRect: pageRect, 
        scaleFactor: scaleFactor, 
        transparentBackground: options.transparent
    )
    
    if !MemoryManager.shared.canAllocateMemory(memoryRequired, verbose: options.verbose) {
        print("Warning: Insufficient memory for processing this page at current scale.")
    }
    
    try MemoryManager.shared.checkMemoryPressureDuringBatch(verbose: options.verbose)
    
    let renderOptions = ImageRenderer.RenderOptions(
        scaleFactor: scaleFactor,
        transparentBackground: options.transparent,
        quality: options.quality,
        verbose: options.verbose,
        dryRun: options.dryRun,
        forceOverwrite: options.forceOverwrite
    )
    
    guard let image = ImageRenderer.shared.renderPageToImage(page: pdfPage, options: renderOptions) else {
        throw PDF22PNGError.renderFailed
    }
    
    try checkInterruption()
    
    if options.isStdoutMode {
        if options.dryRun {
            print("[DRY-RUN] Would write \(image.width)x\(image.height) PNG to stdout")
            return true
        } else {
            return ImageRenderer.shared.writeImageToStdout(image: image, options: renderOptions)
        }
    } else if let outputPath = options.outputPath ?? options.outputFile {
        return ImageRenderer.shared.writeImageToFile(image: image, path: outputPath, options: renderOptions)
    } else {
        throw PDF22PNGError.invalidArgs
    }
}

func processBatchMode(options: ProcessingOptions, pdfDocument: PDFDocument) async throws -> Bool {
    let totalPages = PDFProcessor.shared.getPageCount(pdfDocument)
    let outputDir = options.effectiveOutputDirectory
    
    logMessage(options.verbose, "Processing in batch mode. Output directory: \(outputDir)")
    
    let inputBasename = (options.inputFile != nil && options.inputFile != "-") ? 
        URL(fileURLWithPath: options.inputFile!).deletingPathExtension().lastPathComponent : "output"
    let prefix = options.outputPath ?? inputBasename
    
    guard let scaleSpec = ScaleParser.parseScaleSpecification(options.effectiveScale) else {
        throw PDF22PNGError.invalidScale
    }
    
    guard let firstPage = PDFProcessor.shared.extractPage(pdfDocument, pageNumber: 1) else {
        throw PDF22PNGError.renderFailed
    }
    
    let pageRect = firstPage.bounds(for: .mediaBox)
    let scaleFactor = ImageRenderer.shared.calculateScaleFactor(spec: scaleSpec, pageRect: pageRect)
    
    let batchOptions = BatchProcessor.BatchOptions(
        totalPages: totalPages,
        outputDirectory: outputDir,
        prefix: prefix,
        scaleFactor: scaleFactor,
        transparent: options.transparent,
        quality: options.quality,
        verbose: options.verbose,
        dryRun: options.dryRun,
        forceOverwrite: options.forceOverwrite
    )
    
    let result = try await BatchProcessor.shared.processBatch(document: pdfDocument, options: batchOptions)
    return result.successfulPages > 0
}

// Entry point
let semaphore = DispatchSemaphore(value: 0)
var exitCode: Int32 = 0

Task {
    exitCode = await main()
    semaphore.signal()
}

semaphore.wait()
exit(exitCode)