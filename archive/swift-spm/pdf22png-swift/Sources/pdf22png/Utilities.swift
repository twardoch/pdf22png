import Foundation
import CoreGraphics
import Quartz
import ImageIO
import UniformTypeIdentifiers
import Vision
import Darwin.Mach

// MARK: - Logging

func logMessage(_ verbose: Bool, _ message: String) {
    if verbose {
        fputs("[INFO] \(message)\n", stderr)
    }
}

// MARK: - Scale Parsing

func parseScaleSpecification(_ spec: String) -> ScaleSpecification? {
    var scale = ScaleSpecification()
    
    // Check for percentage (e.g., "150%")
    if spec.hasSuffix("%") {
        let percentStr = String(spec.dropLast())
        guard let percent = Double(percentStr), percent > 0 else { return nil }
        scale.scaleFactor = CGFloat(percent / 100.0)
        scale.isPercentage = true
        return scale
    }
    
    // Check for DPI (e.g., "300dpi")
    if spec.hasSuffix("dpi") {
        let dpiStr = String(spec.dropLast(3))
        guard let dpiValue = Double(dpiStr), dpiValue > 0 else { return nil }
        scale.dpi = CGFloat(dpiValue)
        scale.isDPI = true
        return scale
    }
    
    // Check for dimensions (e.g., "800x600", "800x", "x600")
    if spec.contains("x") {
        let parts = spec.split(separator: "x", maxSplits: 1)
        
        if parts.count == 2 {
            // Width
            if !parts[0].isEmpty {
                guard let width = Double(parts[0]), width > 0 else { return nil }
                scale.maxWidth = CGFloat(width)
                scale.hasWidth = true
            }
            
            // Height
            if !parts[1].isEmpty {
                guard let height = Double(parts[1]), height > 0 else { return nil }
                scale.maxHeight = CGFloat(height)
                scale.hasHeight = true
            }
            
            if scale.hasWidth || scale.hasHeight {
                return scale
            }
        } else if parts.count == 1 && spec.hasPrefix("x") {
            // Height only (e.g., "x600")
            let heightStr = String(spec.dropFirst())
            guard let height = Double(heightStr), height > 0 else { return nil }
            scale.maxHeight = CGFloat(height)
            scale.hasHeight = true
            return scale
        } else if parts.count == 1 && spec.hasSuffix("x") {
            // Width only (e.g., "800x")
            let widthStr = String(spec.dropLast())
            guard let width = Double(widthStr), width > 0 else { return nil }
            scale.maxWidth = CGFloat(width)
            scale.hasWidth = true
            return scale
        }
    }
    
    // Try as simple scale factor (e.g., "2.0")
    if let factor = Double(spec), factor > 0 {
        scale.scaleFactor = CGFloat(factor)
        scale.isPercentage = false
        return scale
    }
    
    return nil
}

// MARK: - Scale Calculation

func calculateScaleFactor(scale: ScaleSpecification, pageRect: CGRect) -> CGFloat {
    // DPI-based scaling
    if scale.isDPI {
        // PDF points are 72 DPI by default
        return scale.dpi / 72.0
    }
    
    // Fixed dimensions
    if scale.hasWidth || scale.hasHeight {
        var scaleX = CGFloat.greatestFiniteMagnitude
        var scaleY = CGFloat.greatestFiniteMagnitude
        
        if scale.hasWidth && pageRect.width > 0 {
            scaleX = scale.maxWidth / pageRect.width
        }
        
        if scale.hasHeight && pageRect.height > 0 {
            scaleY = scale.maxHeight / pageRect.height
        }
        
        // Use the smaller scale to fit within bounds
        return min(scaleX, scaleY)
    }
    
    // Simple scale factor or percentage
    return scale.scaleFactor
}

// MARK: - PDF Operations

func readPDFData(_ inputPath: String?, verbose: Bool) -> Data? {
    if let path = inputPath {
        logMessage(verbose, "Reading PDF from file: \(path)")
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // Check file size limits
            try PDFComplexityAnalyzer.validateFileSize(data.count, verbose: verbose)
            
            return data
        } catch {
            print("Error: Failed to read PDF file '\(path)': \(error.localizedDescription)")
            return nil
        }
    } else {
        logMessage(verbose, "Reading PDF from stdin")
        let data = FileHandle.standardInput.readDataToEndOfFile()
        
        // Check stdin data size
        do {
            try PDFComplexityAnalyzer.validateFileSize(data.count, verbose: verbose)
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
        
        // For large stdin data, use secure temporary file to avoid memory issues
        if data.count > 50 * 1024 * 1024 { // 50MB threshold
            return handleLargeStdinData(data, verbose: verbose)
        }
        
        return data
    }
}

/// Handle large stdin data using secure temporary files
private func handleLargeStdinData(_ data: Data, verbose: Bool) -> Data? {
    logMessage(verbose, "Large stdin data detected, using secure temporary file")
    
    let tempPath = InputValidator.createSecureTempPath(prefix: "pdf22png_stdin", suffix: ".pdf")
    
    // Register temp file for cleanup
    registerTempFile(tempPath)
    
    do {
        // Write data to secure temp file
        try data.write(to: URL(fileURLWithPath: tempPath))
        logMessage(verbose, "Wrote \(data.count) bytes to temporary file: \(tempPath)")
        
        // Read back from temp file to ensure consistency
        let tempData = try Data(contentsOf: URL(fileURLWithPath: tempPath))
        
        return tempData
    } catch {
        print("Error: Failed to handle large stdin data: \(error.localizedDescription)")
        
        // Clean up temp file on error
        do {
            try FileManager.default.removeItem(atPath: tempPath)
            unregisterTempFile(tempPath)
        } catch {
            // Ignore cleanup errors
        }
        
        return nil
    }
}

func createPDFDocument(from data: Data) -> PDFDocument? {
    return PDFDocument(data: data)
}

// MARK: - PDF Complexity Analysis

struct PDFComplexityInfo {
    let pageCount: Int
    let averagePageSize: CGSize
    let largestPageSize: CGSize
    let totalPixelsAtScale1: Int64  // Total pixels if rendered at 1x scale
    let estimatedComplexity: ComplexityLevel
    let hasTransparency: Bool
    let hasImages: Bool
    let hasComplexGraphics: Bool
    
    enum ComplexityLevel {
        case low
        case medium
        case high
        case extreme
    }
}

class PDFComplexityAnalyzer {
    // Resource limits
    static let maxFileSize = 500 * 1024 * 1024 // 500MB
    static let maxPixelsPerPage: Int64 = 50_000_000 // 50 megapixels per page
    static let maxTotalPixels: Int64 = 1_000_000_000 // 1 gigapixel total
    static let maxPageDimension: CGFloat = 50000 // 50,000 points
    static let warningFileSize = 100 * 1024 * 1024 // 100MB warning threshold
    
    /// Validate PDF file size
    static func validateFileSize(_ size: Int, verbose: Bool) throws {
        logMessage(verbose, "PDF file size: \(ByteCountFormatter().string(fromByteCount: Int64(size)))")
        
        if size > maxFileSize {
            throw PDF22PNGError.resourceExhaustion
        }
        
        if size > warningFileSize {
            logMessage(verbose, "⚠️  Large PDF file detected. Processing may be slow and memory-intensive.")
        }
    }
    
    /// Analyze PDF complexity to determine resource requirements
    static func analyzePDFComplexity(_ document: PDFDocument, verbose: Bool) throws -> PDFComplexityInfo {
        let pageCount = document.numberOfPages
        
        guard pageCount > 0 else {
            throw PDF22PNGError.emptyPDF
        }
        
        logMessage(verbose, "Analyzing PDF complexity for \(pageCount) pages...")
        
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var largestWidth: CGFloat = 0
        var largestHeight: CGFloat = 0
        var totalPixels: Int64 = 0
        var hasTransparency = false
        var hasImages = false
        var hasComplexGraphics = false
        
        // Sample pages for analysis (check first 10 pages and some random ones)
        let pagesToAnalyze = min(pageCount, 10)
        let sampleIndices = Array(0..<pagesToAnalyze)
        
        for i in sampleIndices {
            guard let page = document.page(at: i) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            let width = pageRect.width
            let height = pageRect.height
            
            // Check for extremely large pages
            if width > maxPageDimension || height > maxPageDimension {
                logMessage(verbose, "⚠️  Page \(i+1) has extreme dimensions: \(width)x\(height)")
                throw PDF22PNGError.resourceExhaustion
            }
            
            totalWidth += width
            totalHeight += height
            largestWidth = max(largestWidth, width)
            largestHeight = max(largestHeight, height)
            
            // Calculate pixels at 1x scale
            let pagePixels = Int64(width * height)
            totalPixels += pagePixels
            
            // Check individual page pixel limit
            if pagePixels > maxPixelsPerPage {
                logMessage(verbose, "⚠️  Page \(i+1) exceeds pixel limit: \(pagePixels) pixels")
                throw PDF22PNGError.resourceExhaustion
            }
            
            // Analyze page content (simplified analysis)
            let pageAnalysis = analyzePage(page)
            hasTransparency = hasTransparency || pageAnalysis.hasTransparency
            hasImages = hasImages || pageAnalysis.hasImages
            hasComplexGraphics = hasComplexGraphics || pageAnalysis.hasComplexGraphics
        }
        
        // Scale total pixels by actual page count
        let scaledTotalPixels = totalPixels * Int64(pageCount) / Int64(pagesToAnalyze)
        
        // Check total pixel limit
        if scaledTotalPixels > maxTotalPixels {
            logMessage(verbose, "⚠️  Total pixel count exceeds limit: \(scaledTotalPixels) pixels")
            throw PDF22PNGError.resourceExhaustion
        }
        
        let averageWidth = totalWidth / CGFloat(pagesToAnalyze)
        let averageHeight = totalHeight / CGFloat(pagesToAnalyze)
        
        let complexity = determineComplexity(
            pageCount: pageCount,
            averagePageSize: CGSize(width: averageWidth, height: averageHeight),
            totalPixels: scaledTotalPixels,
            hasTransparency: hasTransparency,
            hasImages: hasImages,
            hasComplexGraphics: hasComplexGraphics
        )
        
        let info = PDFComplexityInfo(
            pageCount: pageCount,
            averagePageSize: CGSize(width: averageWidth, height: averageHeight),
            largestPageSize: CGSize(width: largestWidth, height: largestHeight),
            totalPixelsAtScale1: scaledTotalPixels,
            estimatedComplexity: complexity,
            hasTransparency: hasTransparency,
            hasImages: hasImages,
            hasComplexGraphics: hasComplexGraphics
        )
        
        logComplexityInfo(info, verbose: verbose)
        
        return info
    }
    
    /// Analyze individual page content
    private static func analyzePage(_ page: PDFPage) -> (hasTransparency: Bool, hasImages: Bool, hasComplexGraphics: Bool) {
        // This is a simplified analysis. In a full implementation, you would
        // parse the PDF content stream to detect specific features
        
        // For now, make educated guesses based on page properties
        let pageString = page.string ?? ""
        let hasImages = pageString.isEmpty // Empty string often indicates image-heavy pages
        
        // Complex graphics detection is simplified
        let hasComplexGraphics = pageString.count > 10000 // Very long text might indicate complex layout
        
        // Transparency detection would require content stream analysis
        let hasTransparency = false // Conservative assumption
        
        return (hasTransparency, hasImages, hasComplexGraphics)
    }
    
    /// Determine overall complexity level
    private static func determineComplexity(
        pageCount: Int,
        averagePageSize: CGSize,
        totalPixels: Int64,
        hasTransparency: Bool,
        hasImages: Bool,
        hasComplexGraphics: Bool
    ) -> PDFComplexityInfo.ComplexityLevel {
        var complexityScore = 0
        
        // Page count factor
        if pageCount > 1000 { complexityScore += 4 }
        else if pageCount > 100 { complexityScore += 3 }
        else if pageCount > 10 { complexityScore += 2 }
        else { complexityScore += 1 }
        
        // Page size factor
        let avgPixels = Int64(averagePageSize.width * averagePageSize.height)
        if avgPixels > 10_000_000 { complexityScore += 4 }
        else if avgPixels > 1_000_000 { complexityScore += 3 }
        else if avgPixels > 100_000 { complexityScore += 2 }
        else { complexityScore += 1 }
        
        // Content factors
        if hasTransparency { complexityScore += 2 }
        if hasImages { complexityScore += 2 }
        if hasComplexGraphics { complexityScore += 2 }
        
        // Total pixel factor
        if totalPixels > 500_000_000 { complexityScore += 3 }
        else if totalPixels > 100_000_000 { complexityScore += 2 }
        else if totalPixels > 10_000_000 { complexityScore += 1 }
        
        // Determine level based on score
        switch complexityScore {
        case 0...4:
            return .low
        case 5...8:
            return .medium
        case 9...12:
            return .high
        default:
            return .extreme
        }
    }
    
    /// Log complexity analysis results
    private static func logComplexityInfo(_ info: PDFComplexityInfo, verbose: Bool) {
        guard verbose else { return }
        
        logMessage(verbose, "PDF Complexity Analysis:")
        logMessage(verbose, "  Pages: \(info.pageCount)")
        logMessage(verbose, "  Average page size: \(Int(info.averagePageSize.width))x\(Int(info.averagePageSize.height))")
        logMessage(verbose, "  Largest page size: \(Int(info.largestPageSize.width))x\(Int(info.largestPageSize.height))")
        logMessage(verbose, "  Total pixels (1x): \(info.totalPixelsAtScale1)")
        logMessage(verbose, "  Complexity level: \(info.estimatedComplexity)")
        logMessage(verbose, "  Has transparency: \(info.hasTransparency)")
        logMessage(verbose, "  Has images: \(info.hasImages)")
        logMessage(verbose, "  Has complex graphics: \(info.hasComplexGraphics)")
        
        switch info.estimatedComplexity {
        case .low:
            logMessage(verbose, "✅ PDF complexity is low - processing should be fast")
        case .medium:
            logMessage(verbose, "⚠️  PDF complexity is medium - processing may take some time")
        case .high:
            logMessage(verbose, "⚠️  PDF complexity is high - processing will be slow and memory-intensive")
        case .extreme:
            logMessage(verbose, "🚨 PDF complexity is extreme - consider reducing scale or processing fewer pages")
        }
    }
    
    /// Get recommended scale factor based on complexity
    static func getRecommendedScale(for complexity: PDFComplexityInfo, requestedScale: CGFloat) -> CGFloat {
        let maxRecommended: CGFloat
        
        switch complexity.estimatedComplexity {
        case .low:
            maxRecommended = 4.0  // Up to 4x scale
        case .medium:
            maxRecommended = 2.0  // Up to 2x scale
        case .high:
            maxRecommended = 1.0  // 1x scale only
        case .extreme:
            maxRecommended = 0.5  // Reduce to 0.5x scale
        }
        
        return min(requestedScale, maxRecommended)
    }
    
    /// Estimate memory usage for given complexity and scale
    static func estimateMemoryUsage(
        complexity: PDFComplexityInfo,
        scaleFactor: CGFloat,
        concurrent: Int = 1
    ) -> UInt64 {
        let pixelsPerPage = complexity.totalPixelsAtScale1 / Int64(complexity.pageCount)
        let scaledPixelsPerPage = Int64(CGFloat(pixelsPerPage) * scaleFactor * scaleFactor)
        
        // 4 bytes per pixel (RGBA) + overhead
        let bytesPerPage = UInt64(scaledPixelsPerPage * 4)
        let overhead = bytesPerPage / 2  // 50% overhead for Core Graphics
        
        return (bytesPerPage + overhead) * UInt64(concurrent)
    }
}

// MARK: - Resource Limiting for Batch Operations

struct ResourceLimits {
    static let maxConcurrentOperations = min(ProcessInfo.processInfo.activeProcessorCount, 8) // Max 8 concurrent
    static let maxProcessingTimePerPage: TimeInterval = 300 // 5 minutes per page
    static let maxTotalProcessingTime: TimeInterval = 3600 * 4 // 4 hours total
    static let maxMemoryUsagePercent: Double = 0.8 // 80% of system memory
    static let maxDiskUsageGB: UInt64 = 10 // 10GB temp disk usage
    static let maxOpenFileHandles = 100 // Max file handles
    static let pageProcessingTimeout: TimeInterval = 600 // 10 minutes per page
    static let checkInterval: TimeInterval = 30 // Check resources every 30 seconds
}

class BatchResourceManager {
    private var startTime: Date
    private var processedPages = 0
    private var failedPages = 0
    private var openFileHandles = Set<FileHandle>()
    private var tempDiskUsage: UInt64 = 0
    private let lock = NSLock()
    private var resourceCheckTimer: Timer?
    
    init() {
        self.startTime = Date()
        startResourceMonitoring()
    }
    
    deinit {
        stopResourceMonitoring()
    }
    
    /// Start monitoring system resources
    private func startResourceMonitoring() {
        resourceCheckTimer = Timer.scheduledTimer(withTimeInterval: ResourceLimits.checkInterval, repeats: true) { [weak self] _ in
            self?.checkResourceLimits()
        }
    }
    
    /// Stop resource monitoring
    private func stopResourceMonitoring() {
        resourceCheckTimer?.invalidate()
        resourceCheckTimer = nil
    }
    
    /// Check if we can start processing another page
    func canProcessPage(verbose: Bool = false) throws -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        // Check total processing time
        let elapsedTime = Date().timeIntervalSince(startTime)
        if elapsedTime > ResourceLimits.maxTotalProcessingTime {
            logMessage(verbose, "⚠️  Maximum total processing time exceeded: \(elapsedTime/3600) hours")
            throw PDF22PNGError.resourceExhaustion
        }
        
        // Check memory pressure
        if let memInfo = MemoryManager.getMemoryInfo() {
            if memInfo.memoryPressure > ResourceLimits.maxMemoryUsagePercent {
                logMessage(verbose, "⚠️  Memory usage too high: \(Int(memInfo.memoryPressure * 100))%")
                throw PDF22PNGError.memoryPressure
            }
        }
        
        // Check disk usage
        if tempDiskUsage > ResourceLimits.maxDiskUsageGB * 1024 * 1024 * 1024 {
            logMessage(verbose, "⚠️  Temporary disk usage too high: \(tempDiskUsage / (1024*1024*1024))GB")
            throw PDF22PNGError.resourceExhaustion
        }
        
        // Check file handles
        if openFileHandles.count > ResourceLimits.maxOpenFileHandles {
            logMessage(verbose, "⚠️  Too many open file handles: \(openFileHandles.count)")
            throw PDF22PNGError.resourceExhaustion
        }
        
        return true
    }
    
    /// Record that a page has started processing
    func startPageProcessing(pageNum: Int, verbose: Bool = false) {
        lock.lock()
        defer { lock.unlock() }
        
        logMessage(verbose, "Starting page \(pageNum) processing. Total: \(processedPages + failedPages + 1)")
    }
    
    /// Record that a page has finished processing
    func finishPageProcessing(pageNum: Int, success: Bool, processingTime: TimeInterval, verbose: Bool = false) {
        lock.lock()
        defer { lock.unlock() }
        
        if success {
            processedPages += 1
        } else {
            failedPages += 1
        }
        
        logMessage(verbose, "Finished page \(pageNum) in \(processingTime)s. Success: \(processedPages), Failed: \(failedPages)")
        
        // Check if individual page took too long
        if processingTime > ResourceLimits.maxProcessingTimePerPage {
            logMessage(verbose, "⚠️  Page \(pageNum) processing time exceeded limit: \(processingTime)s")
        }
    }
    
    /// Register file handle for tracking
    func registerFileHandle(_ handle: FileHandle) {
        lock.lock()
        defer { lock.unlock() }
        
        openFileHandles.insert(handle)
    }
    
    /// Unregister file handle
    func unregisterFileHandle(_ handle: FileHandle) {
        lock.lock()
        defer { lock.unlock() }
        
        openFileHandles.remove(handle)
    }
    
    /// Add to temporary disk usage tracking
    func addTempDiskUsage(_ bytes: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        
        tempDiskUsage += bytes
    }
    
    /// Remove from temporary disk usage tracking
    func removeTempDiskUsage(_ bytes: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        
        tempDiskUsage = tempDiskUsage > bytes ? tempDiskUsage - bytes : 0
    }
    
    /// Check resource limits periodically
    private func checkResourceLimits() {
        do {
            _ = try canProcessPage(verbose: false)
        } catch {
            // If resource limits exceeded, set termination flag
            shouldTerminate = true
            print("⚠️  Resource limits exceeded, terminating batch processing...")
        }
    }
    
    /// Get current processing statistics
    func getStatistics() -> (processed: Int, failed: Int, elapsed: TimeInterval, diskUsage: UInt64, fileHandles: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        let elapsed = Date().timeIntervalSince(startTime)
        return (processedPages, failedPages, elapsed, tempDiskUsage, openFileHandles.count)
    }
    
    /// Calculate recommended concurrency based on current system state
    func getRecommendedConcurrency(maxRequested: Int, verbose: Bool = false) -> Int {
        // Start with system limits
        var recommended = min(maxRequested, ResourceLimits.maxConcurrentOperations)
        
        // Adjust based on memory pressure
        if let memInfo = MemoryManager.getMemoryInfo() {
            if memInfo.memoryPressure > 0.7 {
                recommended = max(1, recommended / 2) // Halve concurrency if memory pressure high
                logMessage(verbose, "Reduced concurrency due to memory pressure: \(recommended)")
            }
        }
        
        // Adjust based on processing time trends
        let elapsed = Date().timeIntervalSince(startTime)
        if processedPages > 0 {
            let avgTimePerPage = elapsed / Double(processedPages)
            if avgTimePerPage > ResourceLimits.maxProcessingTimePerPage / 2 {
                recommended = max(1, recommended / 2) // Reduce if pages taking too long
                logMessage(verbose, "Reduced concurrency due to slow processing: \(recommended)")
            }
        }
        
        // Adjust based on failure rate
        let totalProcessed = processedPages + failedPages
        if totalProcessed > 10 && failedPages > totalProcessed / 4 { // More than 25% failure rate
            recommended = max(1, recommended / 2) // Reduce if high failure rate
            logMessage(verbose, "Reduced concurrency due to high failure rate: \(recommended)")
        }
        
        return recommended
    }
}

/// Timeout wrapper for page processing
class PageProcessingTimeout {
    private let timeout: TimeInterval
    private var timeoutSource: DispatchSourceTimer?
    private var isCompleted = false
    private let lock = NSLock()
    
    init(timeout: TimeInterval = ResourceLimits.pageProcessingTimeout) {
        self.timeout = timeout
    }
    
    /// Start timeout monitoring for page processing
    func startTimeout(pageNum: Int, onTimeout: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isCompleted else { return }
        
        timeoutSource = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timeoutSource?.schedule(deadline: .now() + timeout)
        timeoutSource?.setEventHandler {
            print("⚠️  Page \(pageNum) processing timeout after \(self.timeout) seconds")
            onTimeout()
        }
        timeoutSource?.resume()
    }
    
    /// Cancel timeout (call when processing completes)
    func cancelTimeout() {
        lock.lock()
        defer { lock.unlock() }
        
        isCompleted = true
        timeoutSource?.cancel()
        timeoutSource = nil
    }
    
    deinit {
        cancelTimeout()
    }
}

// MARK: - Progress Reporting

class ProgressReporter {
    private let totalItems: Int
    private var processedItems: Int = 0
    private var successfulItems: Int = 0
    private var failedItems: Int = 0
    private let startTime: Date
    private var lastReportTime: Date
    private let reportInterval: TimeInterval = 1.0 // Report every second
    private let verbose: Bool
    
    init(totalItems: Int, verbose: Bool = false) {
        self.totalItems = totalItems
        self.verbose = verbose
        self.startTime = Date()
        self.lastReportTime = Date()
    }
    
    func reportProgress(successful: Bool = true) {
        processedItems += 1
        if successful {
            successfulItems += 1
        } else {
            failedItems += 1
        }
        
        let now = Date()
        let shouldReport = now.timeIntervalSince(lastReportTime) >= reportInterval || processedItems == totalItems
        
        if shouldReport && !verbose {
            displayProgress()
            lastReportTime = now
        } else if verbose {
            displayVerboseProgress(successful: successful)
        }
    }
    
    private func displayProgress() {
        let percentage = Int((Double(processedItems) / Double(totalItems)) * 100)
        let elapsed = Date().timeIntervalSince(startTime)
        let rate = Double(processedItems) / elapsed
        let eta = totalItems > processedItems ? Int((Double(totalItems - processedItems) / rate)) : 0
        
        let progressBar = createProgressBar(percentage: percentage)
        let etaString = formatDuration(eta)
        
        print("\r\(progressBar) \(percentage)% (\(processedItems)/\(totalItems)) ⏱ ETA: \(etaString)", terminator: "")
        fflush(stdout)
    }
    
    private func displayVerboseProgress(successful: Bool) {
        let elapsed = Date().timeIntervalSince(startTime)
        let rate = Double(processedItems) / elapsed
        let status = successful ? "✅" : "❌"
        
        print("[\(formatDuration(Int(elapsed)))] \(status) Page \(processedItems)/\(totalItems) | Rate: \(String(format: "%.1f", rate)) pages/sec | Success: \(successfulItems) | Failed: \(failedItems)")
    }
    
    private func createProgressBar(percentage: Int) -> String {
        let width = 20
        let filled = Int(Double(width) * Double(percentage) / 100.0)
        let empty = width - filled
        
        let filledBar = String(repeating: "█", count: filled)
        let emptyBar = String(repeating: "░", count: empty)
        
        return "[\(filledBar)\(emptyBar)]"
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    func finish() {
        if !verbose {
            // Clear the progress line
            print("\r\(String(repeating: " ", count: 80))\r", terminator: "")
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let rate = Double(processedItems) / elapsed
        
        print("🎯 Processing complete: \(successfulItems) successful, \(failedItems) failed (\(String(format: "%.1f", rate)) pages/sec)")
    }
}

// MARK: - Rendering

enum RenderingScenario {
    case thumbnail      // Small size, low quality acceptable
    case preview        // Medium size, balanced quality
    case standard       // Normal rendering
    case highQuality    // High quality, larger size
    
    var qualityPreset: (interpolationQuality: CGInterpolationQuality, antialiasing: Bool, fractionalWidths: Bool) {
        switch self {
        case .thumbnail:
            return (.low, false, false)
        case .preview:
            return (.medium, true, false)
        case .standard:
            return (.default, true, true)
        case .highQuality:
            return (.high, true, true)
        }
    }
}

/// Determine optimal rendering scenario based on output dimensions
func determineRenderingScenario(scaledWidth: Int, scaledHeight: Int) -> RenderingScenario {
    let pixels = scaledWidth * scaledHeight
    
    if pixels <= 250_000 { // <= 500x500
        return .thumbnail
    } else if pixels <= 1_000_000 { // <= 1000x1000
        return .preview
    } else if pixels <= 4_000_000 { // <= 2000x2000
        return .standard
    } else {
        return .highQuality
    }
}

/// Fast rendering path for thumbnails and previews
func renderPDFPageToImageFast(
    page: PDFPage,
    scaleFactor: CGFloat,
    transparentBackground: Bool,
    scenario: RenderingScenario,
    verbose: Bool,
    useMemoryPool: Bool = true
) -> CGImage? {
    let pageRect = page.bounds(for: .mediaBox)
    let scaledWidth = Int(pageRect.width * scaleFactor)
    let scaledHeight = Int(pageRect.height * scaleFactor)
    
    logMessage(verbose, "Fast rendering (\(scenario)) page with dimensions: \(scaledWidth)x\(scaledHeight)")
    
    // Create bitmap context with optimizations for scenario
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // For thumbnails, we can use simpler pixel format
    let bitsPerComponent = scenario == .thumbnail ? 5 : 8  // RGB555 for thumbnails
    
    var context: CGContext?
    var fromPool = false
    
    // Try to get context from pool for batch operations
    if useMemoryPool && bitsPerComponent == 8 { // Pool only supports 8-bit contexts
        context = globalBitmapPool.getContext(
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: bitsPerComponent,
            transparentBackground: transparentBackground,
            colorSpace: colorSpace
        )
        fromPool = context != nil
        
        if fromPool && verbose {
            let stats = globalBitmapPool.getStatistics()
            logMessage(verbose, "Using pooled context (pool: \(stats.total) total, \(stats.inUse) in use, \(stats.memoryMB)MB)")
        }
    }
    
    // Create new context if not from pool
    if context == nil {
        let bitmapInfo: CGBitmapInfo = transparentBackground
            ? [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)]
            : [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)]
        
        context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
    }
    
    guard let renderContext = context else {
        // Fallback to standard rendering
        return renderPDFPageToImage(page: page, scaleFactor: scaleFactor, transparentBackground: transparentBackground, verbose: verbose)
    }
    
    defer {
        // Return context to pool if it came from there
        if fromPool {
            globalBitmapPool.returnContext(renderContext)
        }
    }
    
    // Apply quality presets
    let preset = scenario.qualityPreset
    renderContext.interpolationQuality = preset.interpolationQuality
    renderContext.setShouldAntialias(preset.antialiasing)
    renderContext.setShouldSmoothFonts(preset.antialiasing)
    renderContext.setAllowsFontSubpixelQuantization(preset.fractionalWidths)
    
    // Fill background if not transparent
    if !transparentBackground {
        renderContext.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        renderContext.fill(CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
    }
    
    // Setup coordinate transformation
    renderContext.saveGState()
    renderContext.scaleBy(x: scaleFactor, y: scaleFactor)
    
    // Draw PDF page
    page.draw(with: .mediaBox, to: renderContext)
    
    renderContext.restoreGState()
    
    // Create image from context
    guard let image = renderContext.makeImage() else {
        return nil
    }
    
    logMessage(verbose, "Fast rendering completed successfully")
    return image
}

func renderPDFPageToImage(
    page: PDFPage,
    scaleFactor: CGFloat,
    transparentBackground: Bool,
    verbose: Bool,
    useMemoryPool: Bool = true
) -> CGImage? {
    let pageRect = page.bounds(for: .mediaBox)
    let scaledWidth = Int(pageRect.width * scaleFactor)
    let scaledHeight = Int(pageRect.height * scaleFactor)
    
    // Determine if we can use fast path
    let scenario = determineRenderingScenario(scaledWidth: scaledWidth, scaledHeight: scaledHeight)
    if scenario == .thumbnail || scenario == .preview {
        if let fastResult = renderPDFPageToImageFast(
            page: page,
            scaleFactor: scaleFactor,
            transparentBackground: transparentBackground,
            scenario: scenario,
            verbose: verbose,
            useMemoryPool: useMemoryPool
        ) {
            return fastResult
        }
    }
    
    logMessage(verbose, "Rendering page with dimensions: \(scaledWidth)x\(scaledHeight), scale: \(scaleFactor)")
    
    // Try to get context from pool for batch operations
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var context: CGContext?
    var fromPool = false
    
    if useMemoryPool {
        context = globalBitmapPool.getContext(
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            transparentBackground: transparentBackground,
            colorSpace: colorSpace
        )
        fromPool = context != nil
        
        if fromPool && verbose {
            let stats = globalBitmapPool.getStatistics()
            logMessage(verbose, "Using pooled context (pool: \(stats.total) total, \(stats.inUse) in use, \(stats.memoryMB)MB)")
        }
    }
    
    // Create new context if not from pool
    if context == nil {
        let bitmapInfo: CGBitmapInfo = transparentBackground
            ? [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)]
            : [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)]
        
        context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
    }
    
    guard let renderContext = context else {
        print("Error: Failed to create bitmap context")
        return nil
    }
    
    defer {
        // Return context to pool if it came from there
        if fromPool {
            globalBitmapPool.returnContext(renderContext)
        }
    }
    
    // Fill background if not transparent
    if !transparentBackground {
        renderContext.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        renderContext.fill(CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
    }
    
    // Setup coordinate transformation
    renderContext.saveGState()
    renderContext.scaleBy(x: scaleFactor, y: scaleFactor)
    
    // Draw PDF page
    page.draw(with: .mediaBox, to: renderContext)
    
    renderContext.restoreGState()
    
    // Create image from context
    guard let image = renderContext.makeImage() else {
        print("Error: Failed to create image from context")
        return nil
    }
    
    logMessage(verbose, "Page rendered to CGImage successfully")
    return image
}

// MARK: - Image Output

func writeImageToStdout(image: CGImage, quality: Int, verbose: Bool) -> Bool {
    logMessage(verbose, "Writing image as PNG to stdout with quality: \(quality)")
    
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        data as CFMutableData,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        print("Failed to create image destination for stdout")
        return false
    }
    
    // Note: PNG quality setting has limited effect as PNG is lossless
    logMessage(verbose, "PNG quality setting (\(quality)) is noted, but CoreGraphics offers limited control for PNG compression levels.")
    
    CGImageDestinationAddImage(destination, image, nil)
    
    guard CGImageDestinationFinalize(destination) else {
        print("Failed to finalize image for stdout")
        return false
    }
    
    FileHandle.standardOutput.write(data as Data)
    logMessage(verbose, "Image written to stdout successfully")
    return true
}

func writeImageToFile(
    image: CGImage,
    path: String,
    quality: Int,
    verbose: Bool,
    dryRun: Bool,
    forceOverwrite: Bool
) -> Bool {
    if dryRun {
        let exists = FileManager.default.fileExists(atPath: path)
        print("[DRY-RUN] Would create: \(path)\(exists ? " (overwrites existing)" : "")")
        
        let width = image.width
        let height = image.height
        let bitsPerPixel = 32 // RGBA
        let estimatedSize = (width * height * bitsPerPixel) / 8 / 1024
        
        print("          Dimensions: \(width)x\(height), Estimated size: ~\(estimatedSize) KB")
        return true
    }
    
    // Check for overwrite protection
    if !forceOverwrite && !shouldOverwriteFile(path: path, interactive: true) {
        logMessage(verbose, "Skipping \(path) - file exists and overwrite denied")
        return false
    }
    
    logMessage(verbose, "Writing image as PNG to file: \(path) with quality: \(quality)")
    
    guard let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: path) as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        print("Failed to create image destination for file: \(path)")
        return false
    }
    
    logMessage(verbose, "PNG quality setting (\(quality)) is noted, but CoreGraphics offers limited control for PNG compression levels.")
    
    CGImageDestinationAddImage(destination, image, nil)
    
    let success = CGImageDestinationFinalize(destination)
    if !success {
        print("Failed to write image to file: \(path)")
    }
    
    logMessage(verbose, "Image written to file \(path) \(success ? "successfully" : "failed")")
    return success
}

// MARK: - File Operations

func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

func shouldOverwriteFile(path: String, interactive: Bool) -> Bool {
    if !fileExists(path) {
        return true
    }
    
    if !interactive {
        return false
    }
    
    return promptUserForOverwrite(path: path)
}

func promptUserForOverwrite(path: String) -> Bool {
    print("File '\(path)' already exists. Overwrite? (y/N): ", terminator: "")
    fflush(stdout)
    
    guard let response = readLine()?.lowercased() else {
        return false
    }
    
    return response == "y" || response == "yes"
}

func getOutputPrefix(options: ProcessingOptions) -> String {
    if let outputPath = options.outputPath, outputPath != "-" {
        return (outputPath as NSString).deletingPathExtension
    } else if let inputPath = options.inputPath {
        return (inputPath as NSString).lastPathComponent.replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
    } else {
        return "page"
    }
}

// MARK: - Text Extraction

func extractTextFromPDFPage(page: PDFPage) -> String? {
    return page.string
}

func performOCROnImage(image: CGImage) async -> String? {
    return await withCheckedContinuation { continuation in
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Error: \(error.localizedDescription)")
                continuation.resume(returning: nil)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                continuation.resume(returning: nil)
                return
            }
            
            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            
            continuation.resume(returning: text.isEmpty ? nil : text)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error.localizedDescription)")
            continuation.resume(returning: nil)
        }
    }
}

func slugifyText(_ text: String, maxLength: Int) -> String {
    // Remove non-alphanumeric characters and convert to lowercase
    let slug = text
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9\\s-]", with: "", options: .regularExpression)
        .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    
    // Truncate to maxLength
    if slug.count > maxLength {
        return String(slug.prefix(maxLength))
    }
    
    return slug
}

// MARK: - Page Range Parsing

func parsePageRange(_ rangeSpec: String, totalPages: Int) -> [Int]? {
    var pages = Set<Int>()
    
    // Split by comma for multiple ranges/pages
    let parts = rangeSpec.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    
    for part in parts {
        if part.contains("-") {
            // Handle range (e.g., "1-5")
            let rangeParts = part.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            guard rangeParts.count == 2,
                  let start = Int(rangeParts[0]),
                  let end = Int(rangeParts[1]),
                  start >= 1, end >= start else {
                return nil
            }
            
            let actualEnd = min(end, totalPages)
            for page in start...actualEnd {
                pages.insert(page)
            }
        } else {
            // Handle single page
            guard let page = Int(part), page >= 1, page <= totalPages else {
                return nil
            }
            pages.insert(page)
        }
    }
    
    return pages.isEmpty ? nil : Array(pages).sorted()
}

// MARK: - Filename Formatting

func formatFilenameWithPattern(
    pattern: String?,
    basename: String,
    pageNum: Int,
    totalPages: Int,
    extractedText: String?
) -> String {
    let effectivePattern = pattern ?? "{basename}-{page:03d}"
    
    var result = effectivePattern
    
    // Replace placeholders
    result = result.replacingOccurrences(of: "{basename}", with: basename)
    result = result.replacingOccurrences(of: "{total}", with: "\(totalPages)")
    
    // Handle page number with custom padding
    if let range = result.range(of: #"\{page:(\d+)d\}"#, options: .regularExpression) {
        let match = result[range]
        if let paddingRange = match.range(of: #"\d+"#, options: .regularExpression) {
            let padding = Int(match[paddingRange]) ?? 3
            let paddedPage = String(format: "%0\(padding)d", pageNum)
            result = result.replacingOccurrences(of: match, with: paddedPage)
        }
    } else {
        // Default padding based on total pages
        let digits = String(totalPages).count
        let paddedPage = String(format: "%0\(max(digits, 3))d", pageNum)
        result = result.replacingOccurrences(of: "{page}", with: paddedPage)
    }
    
    // Handle text placeholder
    if let text = extractedText {
        result = result.replacingOccurrences(of: "{text}", with: text)
    } else {
        result = result.replacingOccurrences(of: "{text}", with: "")
    }
    
    // Handle date and time
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    result = result.replacingOccurrences(of: "{date}", with: dateFormatter.string(from: Date()))
    
    dateFormatter.dateFormat = "HHmmss"
    result = result.replacingOccurrences(of: "{time}", with: dateFormatter.string(from: Date()))
    
    return result
}

// MARK: - Error Reporting

func reportError(_ message: String, hint: String?) {
    print("Error: \(message)")
    if let hint = hint {
        print("Hint: \(hint)")
    }
}

func reportWarning(_ message: String, hint: String?) {
    print("Warning: \(message)")
    if let hint = hint {
        print("Hint: \(hint)")
    }
}

func getTroubleshootingHint(_ errorContext: String) -> String? {
    return troubleshootingHints[errorContext]
}

// MARK: - Memory Pressure Monitoring

struct MemoryInfo {
    let totalMemory: UInt64      // Total system memory in bytes
    let availableMemory: UInt64  // Available memory in bytes 
    let usedMemory: UInt64       // Currently used memory in bytes
    let memoryPressure: Double   // Memory pressure as percentage (0.0-1.0)
    let isUnderPressure: Bool    // True if system is under memory pressure
}

class MemoryManager {
    private static let pressureThreshold: Double = 0.85  // 85% memory usage triggers pressure warning
    private static let criticalThreshold: Double = 0.95 // 95% memory usage triggers critical warning
    
    /// Get current system memory information
    static func getMemoryInfo() -> MemoryInfo? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return nil
        }
        
        // Get physical memory info
        var size = MemoryLayout<UInt64>.size
        var totalMemory: UInt64 = 0
        
        guard sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0) == 0 else {
            return nil
        }
        
        // Get memory pressure info
        var pressure: vm_pressure_level_t = VM_PRESSURE_NORMAL
        var pressureSize = MemoryLayout<vm_pressure_level_t>.size
        
        if sysctlbyname("kern.memorystatus_vm_pressure_level", &pressure, &pressureSize, nil, 0) != 0 {
            pressure = VM_PRESSURE_NORMAL // Default if we can't get pressure info
        }
        
        let usedMemory = UInt64(info.resident_size)
        let availableMemory = totalMemory - usedMemory
        let memoryPressurePercent = Double(usedMemory) / Double(totalMemory)
        
        let isUnderPressure = pressure != VM_PRESSURE_NORMAL || memoryPressurePercent > pressureThreshold
        
        return MemoryInfo(
            totalMemory: totalMemory,
            availableMemory: availableMemory,
            usedMemory: usedMemory,
            memoryPressure: memoryPressurePercent,
            isUnderPressure: isUnderPressure
        )
    }
    
    /// Estimate memory requirements for rendering a PDF page at given scale
    static func estimateMemoryRequirement(pageRect: CGRect, scaleFactor: CGFloat, transparentBackground: Bool = false) -> UInt64 {
        let width = pageRect.width * scaleFactor
        let height = pageRect.height * scaleFactor
        
        // RGBA = 4 bytes per pixel, plus some overhead for Core Graphics
        let bytesPerPixel: UInt64 = transparentBackground ? 4 : 4  // Both use RGBA
        let imageBytes = UInt64(width * height) * bytesPerPixel
        
        // Add 50% overhead for Core Graphics bitmap context and processing
        let totalEstimate = imageBytes + (imageBytes / 2)
        
        return totalEstimate
    }
    
    /// Check if we have enough memory for an operation
    static func canAllocateMemory(_ requiredBytes: UInt64, verbose: Bool = false) -> Bool {
        guard let memInfo = getMemoryInfo() else {
            logMessage(verbose, "Warning: Could not get memory information, proceeding with caution")
            return true  // Proceed if we can't get memory info
        }
        
        logMessage(verbose, "Memory check: Required \(formatBytes(requiredBytes)), Available \(formatBytes(memInfo.availableMemory))")
        
        // Check if we have enough available memory plus some safety margin
        let safetyMargin = requiredBytes / 4  // 25% safety margin
        let totalRequired = requiredBytes + safetyMargin
        
        return memInfo.availableMemory > totalRequired
    }
    
    /// Calculate optimal batch size based on available memory
    static func calculateOptimalBatchSize(
        totalPages: Int, 
        pageRect: CGRect, 
        scaleFactor: CGFloat, 
        maxConcurrency: Int = ProcessInfo.processInfo.activeProcessorCount,
        verbose: Bool = false
    ) -> Int {
        guard let memInfo = getMemoryInfo() else {
            logMessage(verbose, "Cannot determine optimal batch size, using conservative default")
            return min(4, totalPages)  // Conservative fallback
        }
        
        let memoryPerPage = estimateMemoryRequirement(pageRect: pageRect, scaleFactor: scaleFactor)
        
        // Adaptive memory allocation based on current pressure
        let memoryMultiplier: Double
        if memInfo.memoryPressure < 0.5 {
            // Low memory usage - can be more aggressive
            memoryMultiplier = 0.75  // Use up to 75% of available
        } else if memInfo.memoryPressure < 0.7 {
            // Moderate memory usage
            memoryMultiplier = 0.5   // Use up to 50% of available
        } else {
            // High memory usage - be conservative
            memoryMultiplier = 0.25  // Use only 25% of available
        }
        
        let availableForBatch = UInt64(Double(memInfo.availableMemory) * memoryMultiplier)
        
        // Calculate how many pages we can process simultaneously
        let maxPagesForMemory = Int(availableForBatch / memoryPerPage)
        
        // Adaptive concurrency limits based on system state
        var adaptiveConcurrencyLimit = maxConcurrency
        
        // Reduce concurrency under memory pressure
        if memInfo.isUnderPressure {
            adaptiveConcurrencyLimit = max(1, maxConcurrency / 2)
            logMessage(verbose, "Reducing concurrency due to memory pressure: \(adaptiveConcurrencyLimit)")
        }
        
        // Further reduce for very large pages
        let pagePixels = Int64(pageRect.width * pageRect.height * scaleFactor * scaleFactor)
        if pagePixels > 10_000_000 { // > 10 megapixels per page
            adaptiveConcurrencyLimit = min(adaptiveConcurrencyLimit, 4)
            logMessage(verbose, "Large page size detected, limiting concurrency to \(adaptiveConcurrencyLimit)")
        }
        
        // Dynamic maximum based on memory and page size
        let dynamicMax = memInfo.isUnderPressure ? 8 : 32
        
        // Calculate optimal batch size with all constraints
        let optimalBatchSize = min(maxPagesForMemory, adaptiveConcurrencyLimit, dynamicMax)
        
        let finalBatchSize = max(1, min(optimalBatchSize, totalPages))  // At least 1, at most totalPages
        
        logMessage(verbose, "Adaptive batch size: \(finalBatchSize) pages (Memory: \(formatBytes(memoryPerPage)) per page, Available: \(formatBytes(availableForBatch)) with \(Int(memoryMultiplier * 100))% allocation)")
        
        return finalBatchSize
    }
    
    /// Calculate adaptive batch size for ongoing operations
    static func getAdaptiveBatchSize(
        currentBatchSize: Int,
        successRate: Double,
        averageProcessingTime: TimeInterval,
        pageRect: CGRect,
        scaleFactor: CGFloat,
        verbose: Bool = false
    ) -> Int {
        // Start with memory-based calculation
        let memoryOptimal = calculateOptimalBatchSize(
            totalPages: currentBatchSize * 2, // Estimate
            pageRect: pageRect,
            scaleFactor: scaleFactor,
            verbose: verbose
        )
        
        var adjustedSize = memoryOptimal
        
        // Adjust based on success rate
        if successRate < 0.8 { // Less than 80% success
            adjustedSize = max(1, adjustedSize / 2)
            logMessage(verbose, "Low success rate (\(Int(successRate * 100))%), reducing batch size to \(adjustedSize)")
        } else if successRate > 0.95 && averageProcessingTime < 5.0 { // High success and fast processing
            adjustedSize = min(adjustedSize * 2, 32)
            logMessage(verbose, "High success rate and fast processing, increasing batch size to \(adjustedSize)")
        }
        
        // Adjust based on processing time
        if averageProcessingTime > 30.0 { // Slow processing
            adjustedSize = max(1, adjustedSize / 2)
            logMessage(verbose, "Slow processing detected, reducing batch size to \(adjustedSize)")
        }
        
        return adjustedSize
    }
    
    /// Monitor memory pressure during batch operations
    static func checkMemoryPressureDuringBatch(verbose: Bool = false) throws {
        guard let memInfo = getMemoryInfo() else {
            return  // Can't check, proceed
        }
        
        if memInfo.memoryPressure > criticalThreshold {
            logMessage(verbose, "Critical memory pressure detected: \(Int(memInfo.memoryPressure * 100))% memory used")
            throw PDF22PNGError.memoryPressure
        } else if memInfo.isUnderPressure {
            logMessage(verbose, "Memory pressure warning: \(Int(memInfo.memoryPressure * 100))% memory used")
            // Continue but log warning
        }
    }
    
    /// Format bytes in human readable form
    private static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Log current memory status for debugging
    static func logMemoryStatus(verbose: Bool) {
        guard verbose, let memInfo = getMemoryInfo() else { return }
        
        let totalMB = formatBytes(memInfo.totalMemory)
        let usedMB = formatBytes(memInfo.usedMemory)
        let availableMB = formatBytes(memInfo.availableMemory)
        let pressurePercent = Int(memInfo.memoryPressure * 100)
        
        logMessage(verbose, "Memory Status: \(usedMB)/\(totalMB) used (\(pressurePercent)%), \(availableMB) available")
        
        if memInfo.isUnderPressure {
            logMessage(verbose, "⚠️  System is under memory pressure")
        }
    }
}

// MARK: - Memory Pool for Batch Operations

/// Memory pool for reusing bitmap contexts in batch operations
class BitmapMemoryPool {
    private struct PooledContext {
        let context: CGContext
        let width: Int
        let height: Int
        let bitsPerComponent: Int
        let colorSpace: CGColorSpace
        let bytesPerRow: Int
        var inUse: Bool = false
        var lastUsed: Date = Date()
    }
    
    private var pool: [PooledContext] = []
    private let maxPoolSize: Int
    private let lock = NSLock()
    private var totalBytesInPool: Int64 = 0
    private let maxBytesInPool: Int64
    
    init(maxPoolSize: Int = 10, maxMemoryMB: Int = 500) {
        self.maxPoolSize = maxPoolSize
        self.maxBytesInPool = Int64(maxMemoryMB) * 1024 * 1024
    }
    
    /// Get a context from the pool or create a new one
    func getContext(
        width: Int,
        height: Int,
        bitsPerComponent: Int = 8,
        transparentBackground: Bool = false,
        colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    ) -> CGContext? {
        lock.lock()
        defer { lock.unlock() }
        
        // Try to find a suitable context in the pool
        for i in 0..<pool.count {
            if !pool[i].inUse && 
               pool[i].width == width && 
               pool[i].height == height &&
               pool[i].bitsPerComponent == bitsPerComponent {
                pool[i].inUse = true
                pool[i].lastUsed = Date()
                
                // Clear the context for reuse
                let context = pool[i].context
                context.clear(CGRect(x: 0, y: 0, width: width, height: height))
                
                return context
            }
        }
        
        // Create new context if pool doesn't have a suitable one
        let bitmapInfo: CGBitmapInfo = transparentBackground
            ? [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)]
            : [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)]
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        // Calculate memory usage
        let bytesPerRow = context.bytesPerRow
        let contextBytes = Int64(bytesPerRow * height)
        
        // Add to pool if we have space
        if pool.count < maxPoolSize && totalBytesInPool + contextBytes <= maxBytesInPool {
            let pooledContext = PooledContext(
                context: context,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                colorSpace: colorSpace,
                bytesPerRow: bytesPerRow,
                inUse: true,
                lastUsed: Date()
            )
            pool.append(pooledContext)
            totalBytesInPool += contextBytes
        }
        
        return context
    }
    
    /// Return a context to the pool
    func returnContext(_ context: CGContext) {
        lock.lock()
        defer { lock.unlock() }
        
        for i in 0..<pool.count {
            if pool[i].context === context {
                pool[i].inUse = false
                pool[i].lastUsed = Date()
                break
            }
        }
    }
    
    /// Clean up old unused contexts
    func cleanupOldContexts(maxAge: TimeInterval = 60) {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        var indicesToRemove: [Int] = []
        
        for i in (0..<pool.count).reversed() {
            if !pool[i].inUse && now.timeIntervalSince(pool[i].lastUsed) > maxAge {
                indicesToRemove.append(i)
            }
        }
        
        for index in indicesToRemove {
            let contextBytes = Int64(pool[index].bytesPerRow * pool[index].height)
            totalBytesInPool -= contextBytes
            pool.remove(at: index)
        }
    }
    
    /// Get pool statistics
    func getStatistics() -> (total: Int, inUse: Int, memoryMB: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        let inUse = pool.filter { $0.inUse }.count
        let memoryMB = Int(totalBytesInPool / (1024 * 1024))
        
        return (pool.count, inUse, memoryMB)
    }
    
    /// Clear all contexts from the pool
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        pool.removeAll()
        totalBytesInPool = 0
    }
}

/// Global memory pool instance for batch operations
let globalBitmapPool = BitmapMemoryPool()

// MARK: - Array Extensions

extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Input Validation

enum ValidationError: Error, LocalizedError {
    case invalidPath(String)
    case pathTraversal(String)
    case invalidPageNumber(Int)
    case invalidPageRange(String)
    case invalidQuality(Int)
    case invalidScale(String)
    case invalidPattern(String)
    case fileNameTooLong(String)
    case unsafeCharacters(String)
    case pathTooLong(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Invalid file path: \(path)"
        case .pathTraversal(let path):
            return "Path traversal detected in: \(path)"
        case .invalidPageNumber(let page):
            return "Invalid page number: \(page)"
        case .invalidPageRange(let range):
            return "Invalid page range: \(range)"
        case .invalidQuality(let quality):
            return "Invalid quality value: \(quality)"
        case .invalidScale(let scale):
            return "Invalid scale specification: \(scale)"
        case .invalidPattern(let pattern):
            return "Invalid naming pattern: \(pattern)"
        case .fileNameTooLong(let name):
            return "Filename too long: \(name)"
        case .unsafeCharacters(let input):
            return "Unsafe characters detected in: \(input)"
        case .pathTooLong(let path):
            return "Path too long: \(path)"
        }
    }
}

class InputValidator {
    // Security limits
    static let maxPathLength = 4096
    static let maxFilenameLength = 255
    static let maxPageNumber = 100000
    static let maxTotalPages = 50000
    static let maxPatternLength = 500
    
    // Allowed character sets
    static let safeFilenameCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    static let safePathCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-/")
    
    /// Validate file path for security and validity
    static func validateFilePath(_ path: String, allowCreate: Bool = false) throws -> String {
        // Check path length
        guard path.count <= maxPathLength else {
            throw ValidationError.pathTooLong(path)
        }
        
        // Check for empty path
        guard !path.isEmpty else {
            throw ValidationError.invalidPath("Empty path")
        }
        
        // Normalize path to resolve relative components
        let normalizedPath = (path as NSString).standardizingPath
        
        // Check for path traversal attempts
        let dangerousPatterns = ["../", "..\\", "/..", "\\..", "~/", "$HOME"]
        for pattern in dangerousPatterns {
            if path.lowercased().contains(pattern) {
                throw ValidationError.pathTraversal(path)
            }
        }
        
        // Check for null bytes and control characters
        if path.contains("\0") || path.rangeOfCharacter(from: CharacterSet.controlCharacters) != nil {
            throw ValidationError.unsafeCharacters(path)
        }
        
        // Validate individual path components
        let components = normalizedPath.components(separatedBy: "/").filter { !$0.isEmpty }
        for component in components {
            try validateFilenameComponent(component)
        }
        
        // If not allowing creation, check if parent directory exists
        if !allowCreate {
            let parentPath = (normalizedPath as NSString).deletingLastPathComponent
            if !parentPath.isEmpty && !FileManager.default.fileExists(atPath: parentPath) {
                throw ValidationError.invalidPath("Parent directory does not exist: \(parentPath)")
            }
        }
        
        return normalizedPath
    }
    
    /// Validate filename component for security
    static func validateFilenameComponent(_ component: String) throws {
        // Check component length
        guard component.count <= maxFilenameLength else {
            throw ValidationError.fileNameTooLong(component)
        }
        
        // Check for reserved names on various systems
        let reservedNames = ["CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"]
        if reservedNames.contains(component.uppercased()) {
            throw ValidationError.invalidPath("Reserved filename: \(component)")
        }
        
        // Check for dangerous characters
        let dangerousChars = CharacterSet(charactersIn: "<>:\"|?*\0")
        if component.rangeOfCharacter(from: dangerousChars) != nil {
            throw ValidationError.unsafeCharacters(component)
        }
        
        // Check for names starting/ending with dots or spaces
        if component.hasPrefix(".") || component.hasSuffix(".") || component.hasPrefix(" ") || component.hasSuffix(" ") {
            throw ValidationError.invalidPath("Invalid filename format: \(component)")
        }
    }
    
    /// Validate page number
    static func validatePageNumber(_ page: Int, totalPages: Int) throws {
        guard page >= 1 else {
            throw ValidationError.invalidPageNumber(page)
        }
        
        guard page <= maxPageNumber else {
            throw ValidationError.invalidPageNumber(page)
        }
        
        guard page <= totalPages else {
            throw ValidationError.invalidPageNumber(page)
        }
    }
    
    /// Validate page range specification
    static func validatePageRange(_ range: String, totalPages: Int) throws {
        guard !range.isEmpty else {
            throw ValidationError.invalidPageRange("Empty page range")
        }
        
        guard range.count <= 1000 else { // Reasonable limit for range spec
            throw ValidationError.invalidPageRange("Page range specification too long")
        }
        
        // Check for dangerous characters
        let allowedChars = CharacterSet(charactersIn: "0123456789,-")
        if range.rangeOfCharacter(from: allowedChars.inverted) != nil {
            throw ValidationError.invalidPageRange("Invalid characters in page range")
        }
        
        // Validate individual parts
        let parts = range.split(separator: ",")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            
            if trimmed.contains("-") {
                // Range validation
                let rangeParts = trimmed.split(separator: "-")
                guard rangeParts.count == 2 else {
                    throw ValidationError.invalidPageRange("Invalid range format: \(trimmed)")
                }
                
                guard let start = Int(rangeParts[0]), let end = Int(rangeParts[1]) else {
                    throw ValidationError.invalidPageRange("Non-numeric range values: \(trimmed)")
                }
                
                try validatePageNumber(start, totalPages: totalPages)
                try validatePageNumber(end, totalPages: totalPages)
                
                guard start <= end else {
                    throw ValidationError.invalidPageRange("Invalid range order: \(start)-\(end)")
                }
            } else {
                // Single page validation
                guard let page = Int(trimmed) else {
                    throw ValidationError.invalidPageRange("Non-numeric page: \(trimmed)")
                }
                
                try validatePageNumber(page, totalPages: totalPages)
            }
        }
    }
    
    /// Validate PNG quality value
    static func validateQuality(_ quality: Int) throws {
        guard quality >= 0 && quality <= 9 else {
            throw ValidationError.invalidQuality(quality)
        }
    }
    
    /// Validate scale specification
    static func validateScale(_ scale: String) throws {
        guard !scale.isEmpty else {
            throw ValidationError.invalidScale("Empty scale specification")
        }
        
        guard scale.count <= 50 else { // Reasonable limit
            throw ValidationError.invalidScale("Scale specification too long")
        }
        
        // Test if the scale can be parsed
        guard parseScaleSpecification(scale) != nil else {
            throw ValidationError.invalidScale("Invalid scale format: \(scale)")
        }
    }
    
    /// Validate naming pattern
    static func validateNamingPattern(_ pattern: String) throws {
        guard !pattern.isEmpty else {
            throw ValidationError.invalidPattern("Empty pattern")
        }
        
        guard pattern.count <= maxPatternLength else {
            throw ValidationError.invalidPattern("Pattern too long")
        }
        
        // Check for dangerous characters that could cause issues
        let dangerousChars = CharacterSet(charactersIn: "<>:\"|*?\0")
        if pattern.rangeOfCharacter(from: dangerousChars) != nil {
            throw ValidationError.unsafeCharacters(pattern)
        }
        
        // Validate placeholders
        let allowedPlaceholders = ["{basename}", "{name}", "{page}", "{text}", "{date}", "{time}", "{total}"]
        let regex = try NSRegularExpression(pattern: "\\{[^}]+\\}", options: [])
        let matches = regex.matches(in: pattern, options: [], range: NSRange(location: 0, length: pattern.count))
        
        for match in matches {
            let placeholder = (pattern as NSString).substring(with: match.range)
            
            // Allow {page:NNNd} format
            if placeholder.starts(with: "{page:") && placeholder.hasSuffix("d}") {
                continue
            }
            
            if !allowedPlaceholders.contains(placeholder) {
                throw ValidationError.invalidPattern("Unknown placeholder: \(placeholder)")
            }
        }
    }
    
    /// Validate output directory path
    static func validateOutputDirectory(_ directory: String) throws -> String {
        let validated = try validateFilePath(directory, allowCreate: true)
        
        // Additional checks for directory
        if FileManager.default.fileExists(atPath: validated) {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: validated, isDirectory: &isDirectory)
            
            if !isDirectory.boolValue {
                throw ValidationError.invalidPath("Path exists but is not a directory: \(validated)")
            }
        }
        
        return validated
    }
    
    /// Sanitize string for safe usage in filenames
    static func sanitizeForFilename(_ input: String, maxLength: Int = maxFilenameLength) -> String {
        // Remove or replace dangerous characters
        var sanitized = input
        
        // Replace common problematic characters
        let replacements = [
            "<": "_",
            ">": "_",
            ":": "_",
            "\"": "_",
            "|": "_",
            "?": "_",
            "*": "_",
            "/": "_",
            "\\": "_",
            "\0": "_"
        ]
        
        for (char, replacement) in replacements {
            sanitized = sanitized.replacingOccurrences(of: char, with: replacement)
        }
        
        // Remove control characters
        sanitized = sanitized.components(separatedBy: CharacterSet.controlCharacters).joined()
        
        // Trim whitespace and dots
        sanitized = sanitized.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        
        // Ensure not empty
        if sanitized.isEmpty {
            sanitized = "untitled"
        }
        
        // Truncate if too long
        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
        }
        
        return sanitized
    }
    
    /// Advanced file path sanitization with injection prevention
    static func sanitizeFilePath(_ path: String) -> String {
        var sanitized = path
        
        // Remove null bytes and other control characters
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        sanitized = sanitized.components(separatedBy: CharacterSet.controlCharacters).joined()
        
        // Remove or replace path traversal sequences
        let traversalPatterns = [
            "../": "_/",
            "..\\": "_\\",
            "/.": "/_",
            "\\.": "\\_",
            "~": "_"
        ]
        
        for (pattern, replacement) in traversalPatterns {
            sanitized = sanitized.replacingOccurrences(of: pattern, with: replacement)
        }
        
        // Remove leading/trailing whitespace
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure path doesn't start with dangerous patterns
        let dangerousPrefixes = ["/", "\\", ".", "$", "~"]
        for prefix in dangerousPrefixes {
            if sanitized.hasPrefix(prefix) {
                sanitized = "_" + String(sanitized.dropFirst())
            }
        }
        
        return sanitized
    }
    
    /// Sanitize user input to prevent command injection
    static func sanitizeUserInput(_ input: String) -> String {
        var sanitized = input
        
        // Remove potentially dangerous characters for shell injection
        let dangerousChars = [";", "&", "|", "`", "$", "(", ")", "[", "]", "{", "}", "<", ">", "!", "\\"]
        for char in dangerousChars {
            sanitized = sanitized.replacingOccurrences(of: char, with: "_")
        }
        
        // Remove null bytes and control characters
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        sanitized = sanitized.components(separatedBy: CharacterSet.controlCharacters).joined()
        
        // Limit length to prevent buffer overflow attacks
        if sanitized.count > 10000 {
            sanitized = String(sanitized.prefix(10000))
        }
        
        return sanitized
    }
    
    /// Create secure temporary file path
    static func createSecureTempPath(prefix: String = "pdf22png", suffix: String = ".tmp") -> String {
        let sanitizedPrefix = sanitizeForFilename(prefix)
        let randomSuffix = UUID().uuidString.prefix(8)
        let filename = "\(sanitizedPrefix)_\(randomSuffix)\(suffix)"
        
        // Use secure temp directory
        let tempDir = NSTemporaryDirectory()
        return (tempDir as NSString).appendingPathComponent(filename)
    }
    
    /// Resolve symlinks and canonicalize path to prevent symlink attacks
    static func resolvePath(_ path: String) throws -> String {
        let url = URL(fileURLWithPath: path)
        
        do {
            let resolvedURL = try url.resolvingSymlinksInPath()
            return resolvedURL.path
        } catch {
            // If resolution fails, return sanitized original path
            return sanitizeFilePath(path)
        }
    }
    
    /// Check if path is within allowed directory (prevent directory traversal)
    static func isPathWithinDirectory(_ path: String, allowedDirectory: String) -> Bool {
        do {
            let resolvedPath = try resolvePath(path)
            let resolvedAllowedDir = try resolvePath(allowedDirectory)
            
            return resolvedPath.hasPrefix(resolvedAllowedDir)
        } catch {
            return false
        }
    }
    
    /// Safe path joining that prevents traversal
    static func safeJoinPath(_ base: String, _ component: String) -> String {
        let sanitizedComponent = sanitizeFilePath(component)
        let joined = (base as NSString).appendingPathComponent(sanitizedComponent)
        
        // Ensure the result is still within the base directory
        if isPathWithinDirectory(joined, allowedDirectory: base) {
            return joined
        } else {
            // If traversal detected, use just the sanitized component name
            return (base as NSString).appendingPathComponent(sanitizedComponent.components(separatedBy: "/").last ?? "safe_file")
        }
    }
}

// MARK: - Secure Temporary File Management

class SecureTempFile {
    let path: String
    private let fileHandle: FileHandle?
    private var isDeleted = false
    private let lock = NSLock()
    
    /// Create a secure temporary file
    init(prefix: String = "pdf22png", suffix: String = ".tmp") throws {
        // Generate secure path
        self.path = InputValidator.createSecureTempPath(prefix: prefix, suffix: suffix)
        
        // Create the file with restricted permissions (owner read/write only)
        let fileManager = FileManager.default
        guard fileManager.createFile(atPath: path, contents: nil, attributes: [
            .posixPermissions: 0o600  // Owner read/write only
        ]) else {
            throw PDF22PNGError.insecureOperation
        }
        
        // Open file handle
        self.fileHandle = FileHandle(forWritingAtPath: path)
        
        // Register for cleanup
        registerTempFile(path)
        registerCleanupHandler { [weak self] in
            self?.delete()
        }
    }
    
    /// Write data to temporary file
    func write(_ data: Data) throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isDeleted, let handle = fileHandle else {
            throw PDF22PNGError.insecureOperation
        }
        
        try handle.write(contentsOf: data)
        try handle.synchronize()
    }
    
    /// Read data from temporary file
    func read() throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isDeleted else {
            throw PDF22PNGError.insecureOperation
        }
        
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }
    
    /// Delete the temporary file
    func delete() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isDeleted else { return }
        
        isDeleted = true
        
        // Close file handle
        try? fileHandle?.close()
        
        // Securely delete file
        do {
            // First, overwrite the file with random data for security
            if let overwriteHandle = FileHandle(forWritingAtPath: path) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: path)[.size] as? UInt64 ?? 0
                if fileSize > 0 && fileSize < 100 * 1024 * 1024 { // Only overwrite files < 100MB
                    let randomData = Data((0..<fileSize).map { _ in UInt8.random(in: 0...255) })
                    try overwriteHandle.write(contentsOf: randomData)
                    try overwriteHandle.synchronize()
                }
                try overwriteHandle.close()
            }
            
            // Then delete the file
            try FileManager.default.removeItem(atPath: path)
            unregisterTempFile(path)
        } catch {
            // If secure deletion fails, still try normal deletion
            try? FileManager.default.removeItem(atPath: path)
            unregisterTempFile(path)
        }
    }
    
    deinit {
        delete()
    }
}

/// Secure temporary directory manager
class SecureTempDirectory {
    let path: String
    private var isDeleted = false
    private let lock = NSLock()
    
    /// Create a secure temporary directory
    init(prefix: String = "pdf22png_batch") throws {
        let tempDir = NSTemporaryDirectory()
        let sanitizedPrefix = InputValidator.sanitizeForFilename(prefix)
        let randomSuffix = UUID().uuidString.prefix(8)
        let dirName = "\(sanitizedPrefix)_\(randomSuffix)"
        
        self.path = (tempDir as NSString).appendingPathComponent(dirName)
        
        // Create directory with restricted permissions
        try FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]  // Owner access only
        )
        
        // Register for cleanup
        registerTempFile(path)
        registerCleanupHandler { [weak self] in
            self?.delete()
        }
    }
    
    /// Create a secure temporary file within this directory
    func createTempFile(name: String, suffix: String = ".tmp") throws -> SecureTempFile {
        let sanitizedName = InputValidator.sanitizeForFilename(name)
        let fileName = "\(sanitizedName)\(suffix)"
        let filePath = (path as NSString).appendingPathComponent(fileName)
        
        // Create file with restricted permissions
        guard FileManager.default.createFile(atPath: filePath, contents: nil, attributes: [
            .posixPermissions: 0o600
        ]) else {
            throw PDF22PNGError.insecureOperation
        }
        
        return try SecureTempFile(prefix: "", suffix: "")
    }
    
    /// Delete the temporary directory and all contents
    func delete() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isDeleted else { return }
        
        isDeleted = true
        
        do {
            try FileManager.default.removeItem(atPath: path)
            unregisterTempFile(path)
        } catch {
            // If deletion fails, log but don't throw
            print("Warning: Failed to delete temporary directory: \(path)")
        }
    }
    
    deinit {
        delete()
    }
}

/// Secure temporary file operations utility
struct SecureTempOperations {
    /// Process large data using a temporary file to reduce memory usage
    static func processLargeData<T>(
        _ data: Data,
        operation: (String) throws -> T
    ) throws -> T {
        let tempFile = try SecureTempFile(prefix: "pdf22png_process", suffix: ".data")
        defer { tempFile.delete() }
        
        try tempFile.write(data)
        return try operation(tempFile.path)
    }
    
    /// Create a secure working directory for batch operations
    static func withSecureWorkingDirectory<T>(
        prefix: String = "pdf22png_work",
        operation: (String) throws -> T
    ) throws -> T {
        let tempDir = try SecureTempDirectory(prefix: prefix)
        defer { tempDir.delete() }
        
        return try operation(tempDir.path)
    }
    
    /// Securely copy file with validation
    static func secureCopy(from source: String, to destination: String) throws {
        // Validate paths
        let validatedSource = try InputValidator.validateFilePath(source, allowCreate: false)
        let validatedDestination = try InputValidator.validateFilePath(destination, allowCreate: true)
        
        // Copy with secure permissions
        try FileManager.default.copyItem(atPath: validatedSource, toPath: validatedDestination)
        
        // Set restrictive permissions on destination
        try FileManager.default.setAttributes([
            .posixPermissions: 0o600
        ], ofItemAtPath: validatedDestination)
    }
}
}