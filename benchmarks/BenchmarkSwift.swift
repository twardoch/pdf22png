import Foundation
import CoreGraphics
import pdf22png

// Bridge functions to call from Objective-C
@objc public class SwiftBenchmarkBridge: NSObject {
    
    @objc public static func benchmarkSwiftImplementation(config: BenchmarkConfig) -> BenchmarkResult {
        var result = BenchmarkResult()
        var times: [Double] = []
        let initialMemory = getCurrentMemoryUsage()
        var peakMemory = initialMemory
        
        // Load PDF document
        guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: config.pdfPath)) else {
            print("Failed to load PDF: \(config.pdfPath)")
            result.failureCount = config.iterations
            return result
        }
        
        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            print("PDF has no pages")
            result.failureCount = config.iterations
            return result
        }
        
        // Create temporary output directory
        let tempDir = NSTemporaryDirectory().appending("/pdf22png_benchmark_swift")
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        
        // Run benchmark iterations
        for i in 0..<config.iterations {
            autoreleasepool {
                let startTime = getCurrentTimeInSeconds()
                
                // Create options for conversion
                let scaleSpec = ScaleSpec(
                    scaleFactor: config.scaleFactor,
                    maxWidth: 0,
                    maxHeight: 0,
                    dpi: config.dpi,
                    isPercentage: false,
                    isDPI: config.dpi > 0,
                    hasWidth: false,
                    hasHeight: false
                )
                
                let options = Options(
                    scale: scaleSpec,
                    pageNumber: 1,
                    inputPath: config.pdfPath,
                    outputPath: "",
                    outputDirectory: tempDir,
                    batchMode: config.pageCount > 1,
                    transparentBackground: config.transparent,
                    pngQuality: 6,
                    verbose: false
                )
                
                var success = true
                let renderer = PDFRenderer()
                
                do {
                    if config.pageCount == 1 {
                        // Single page conversion
                        let outputPath = "\(tempDir)/page_\(i).png"
                        
                        if let page = pdfDocument.page(at: 0) {
                            let image = try renderer.renderPage(page, with: options)
                            success = Utils.saveImage(image, to: outputPath, quality: options.pngQuality)
                        } else {
                            success = false
                        }
                    } else {
                        // Multi-page conversion
                        for pageNum in 0..<min(pageCount, Int(config.pageCount)) {
                            let outputPath = String(format: "%@/iter_%ld_page_%03d.png", tempDir, i, pageNum + 1)
                            
                            if let page = pdfDocument.page(at: pageNum) {
                                let image = try renderer.renderPage(page, with: options)
                                if !Utils.saveImage(image, to: outputPath, quality: options.pngQuality) {
                                    success = false
                                }
                            } else {
                                success = false
                            }
                        }
                    }
                } catch {
                    success = false
                    print("Rendering error: \(error)")
                }
                
                let endTime = getCurrentTimeInSeconds()
                let elapsedTime = endTime - startTime
                
                times.append(elapsedTime)
                
                if success {
                    result.successCount += 1
                } else {
                    result.failureCount += 1
                }
                
                // Update peak memory
                let currentMemory = getCurrentMemoryUsage()
                if currentMemory > peakMemory {
                    peakMemory = currentMemory
                }
                
                // Clean up generated files for this iteration
                if let files = try? FileManager.default.contentsOfDirectory(atPath: tempDir) {
                    for file in files {
                        if file.hasPrefix("iter_\(i)_") || file == "page_\(i).png" {
                            try? FileManager.default.removeItem(atPath: "\(tempDir)/\(file)")
                        }
                    }
                }
            }
        }
        
        // Clean up temp directory
        try? FileManager.default.removeItem(atPath: tempDir)
        
        // Calculate statistics
        result.memoryPeak = peakMemory
        
        if !times.isEmpty {
            let sum = times.reduce(0, +)
            result.totalTime = sum
            result.averageTime = sum / Double(times.count)
            result.minTime = times.min() ?? 0
            result.maxTime = times.max() ?? 0
            
            // Calculate standard deviation
            let mean = result.averageTime
            let variance = times.map { pow($0 - mean, 2) }.reduce(0, +) / Double(times.count - 1)
            result.stdDev = sqrt(variance)
        }
        
        return result
    }
}

// Helper class for PDF operations (since PDFKit might not be available)
private class PDFDocument {
    private let document: CGPDFDocument
    
    var pageCount: Int {
        return document.numberOfPages
    }
    
    init?(url: URL) {
        guard let document = CGPDFDocument(url as CFURL) else {
            return nil
        }
        self.document = document
    }
    
    func page(at index: Int) -> CGPDFPage? {
        return document.page(at: index + 1) // CGPDFDocument uses 1-based indexing
    }
}