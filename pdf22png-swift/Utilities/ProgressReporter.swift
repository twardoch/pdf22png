import Foundation

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
    
    // Progress info for external consumption
    func getCurrentProgress() -> ProgressInfo {
        let elapsed = Date().timeIntervalSince(startTime)
        let pagesPerSecond = elapsed > 0 ? Double(processedPages) / elapsed : 0
        let estimatedTotal = pagesPerSecond > 0 ? Double(totalPages) / pagesPerSecond : 0
        let estimatedRemaining = max(0, estimatedTotal - elapsed)
        
        return ProgressInfo(
            completed: processedPages,
            total: totalPages,
            speed: pagesPerSecond > 0 ? pagesPerSecond : nil,
            estimatedTimeRemaining: estimatedRemaining > 0 ? estimatedRemaining : nil,
            currentOperation: nil
        )
    }
}