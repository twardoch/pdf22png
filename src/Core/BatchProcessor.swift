import Foundation
import CoreGraphics
import PDFKit

// MARK: - Batch Processing

class BatchProcessor {
    static let shared = BatchProcessor()
    private init() {}
    
    struct BatchOptions {
        let totalPages: Int
        let outputDirectory: String
        let prefix: String
        let scaleFactor: CGFloat
        let transparent: Bool
        let quality: Int
        let verbose: Bool
        let dryRun: Bool
        let forceOverwrite: Bool
    }
    
    struct BatchResult {
        let totalPages: Int
        let successfulPages: Int
        let failedPages: Int
        let interrupted: Bool
    }
    
    func processBatch(document: PDFDocument, options: BatchOptions) async throws -> BatchResult {
        let totalPages = options.totalPages
        
        // Create output directory
        if !options.dryRun {
            do {
                try FileManager.default.createDirectory(atPath: options.outputDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw PDF22PNGError.outputDir
            }
        }
        
        // Calculate optimal batch size based on memory
        guard let firstPage = document.page(at: 0) else {
            throw PDF22PNGError.renderFailed
        }
        
        let pageRect = firstPage.bounds(for: .mediaBox)
        let optimalBatchSize = MemoryManager.shared.calculateOptimalBatchSize(
            totalPages: totalPages,
            pageRect: pageRect,
            scaleFactor: options.scaleFactor,
            verbose: options.verbose
        )
        
        // Initialize progress reporter
        let progressReporter = ProgressReporter(totalPages: totalPages, verbose: options.verbose)
        
        if !options.dryRun {
            print("🚀 Starting batch conversion of \(totalPages) pages...")
            if options.verbose {
                print("   Output directory: \(options.outputDirectory)")
                print("   Output prefix: \(options.prefix)")
                print("   Batch size: \(optimalBatchSize) pages/chunk")
            }
        }
        
        // Process pages in memory-optimized chunks
        let chunks = stride(from: 1, through: totalPages, by: optimalBatchSize).map { start in
            Array(start..<min(start + optimalBatchSize, totalPages + 1))
        }
        
        var successfulPages = 0
        var failedPages = 0
        var interrupted = false
        
        for (chunkIndex, chunk) in chunks.enumerated() {
            // Check for interruption before each chunk
            do {
                try checkInterruption()
            } catch {
                interrupted = true
                break
            }
            
            // Check memory pressure before each chunk
            do {
                try MemoryManager.shared.checkMemoryPressureDuringBatch(verbose: options.verbose)
            } catch {
                // Continue processing even under memory pressure
            }
            
            progressReporter.reportChunkStart(chunkNumber: chunkIndex + 1, totalChunks: chunks.count, pagesInChunk: chunk.count)
            
            for pageNum in chunk {
                // Check for interruption for each page
                do {
                    try checkInterruption()
                } catch {
                    interrupted = true
                    break
                }
                
                progressReporter.reportPageStart(pageNumber: pageNum)
                
                guard let pdfPage = document.page(at: pageNum - 1) else {
                    progressReporter.reportPageComplete(pageNumber: pageNum, success: false)
                    failedPages += 1
                    continue
                }
                
                let renderOptions = ImageRenderer.RenderOptions(
                    scaleFactor: options.scaleFactor,
                    transparentBackground: options.transparent,
                    quality: options.quality,
                    verbose: options.verbose,
                    dryRun: options.dryRun,
                    forceOverwrite: options.forceOverwrite
                )
                
                guard let image = ImageRenderer.shared.renderPageToImage(page: pdfPage, options: renderOptions) else {
                    progressReporter.reportPageComplete(pageNumber: pageNum, success: false)
                    failedPages += 1
                    continue
                }
                
                let filename = String(format: "%@-%03d.png", options.prefix, pageNum)
                let outputPath = (options.outputDirectory as NSString).appendingPathComponent(filename)
                
                if options.dryRun {
                    print("[DRY-RUN] Would create: \(filename) (\(image.width)x\(image.height) pixels)")
                    progressReporter.reportPageComplete(pageNumber: pageNum, success: true, outputFile: filename)
                    successfulPages += 1
                } else {
                    let success = ImageRenderer.shared.writeImageToFile(image: image, path: outputPath, options: renderOptions)
                    progressReporter.reportPageComplete(pageNumber: pageNum, success: success, outputFile: success ? filename : nil)
                    if success {
                        successfulPages += 1
                    } else {
                        failedPages += 1
                    }
                }
            }
            
            // Log memory status after each chunk in verbose mode
            if options.verbose && chunks.count > 1 {
                MemoryManager.shared.logMemoryStatus(verbose: true)
            }
            
            if interrupted {
                progressReporter.reportInterrupted()
                break
            }
        }
        
        // Final status report
        if options.dryRun && !interrupted {
            print("\n[DRY-RUN] Would convert \(totalPages) pages to PNG files")
        } else if !interrupted {
            progressReporter.reportBatchComplete()
        }
        
        return BatchResult(
            totalPages: totalPages,
            successfulPages: successfulPages,
            failedPages: failedPages,
            interrupted: interrupted
        )
    }
    
    func calculateOptimalConcurrency(pages: Int, memoryRequirement: UInt64) -> Int {
        let memInfo = MemoryManager.shared.getSystemMemoryInfo()
        let availableMemory = memInfo.available / 2 // Use only half of available memory
        let maxConcurrentPages = max(1, Int(availableMemory / memoryRequirement))
        return min(pages, maxConcurrentPages)
    }
}