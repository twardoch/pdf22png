import Foundation
import CoreGraphics
import PDFKit
import ArgumentParser
import Dispatch
import ScaleUtilities
import struct ScaleUtilities.ScaleSpec
import func ScaleUtilities.parseScaleSpec
import func ScaleUtilities.calculateScaleFactor

// Extension to print to stderr
struct StandardError: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stderr)
    }
}
var standardError = StandardError()

// MARK: - Error Types

enum PDF22PNGError: Int, Error {
    case invalidArgs = 2
    case fileNotFound = 3
    case fileRead = 4
    case fileWrite = 5
    case outputDir = 6
    case renderFailed = 7
    case pageNotFound = 8
    case invalidScale = 9
    case memory = 10
    case signalInterruption = 130
}



// MARK: - Command Line Interface

@main
struct PDF22PNGCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf22png",
        abstract: "Converts PDF documents to PNG images.",
        version: "2.2.0"
    )
    
    @Argument(help: "Input PDF file. If '-', reads from stdin.")
    var inputFile: String
    
    @Argument(help: "Output PNG file. Required if not using -o or -d. If input is stdin and output is not specified, output goes to stdout. In batch mode (-a or -d), this is used as a prefix if -o is not set.")
    var outputFile: String?
    
    @Option(name: .shortAndLong, help: "Page(s) to convert. Single page, range, or comma-separated. Examples: 1 | 1-5 | 1,3,5-10 (default: 1). In batch mode, only specified pages are converted.")
    var page: String = "1"
    
    @Flag(name: .shortAndLong, help: "Convert all pages. If -d is not given, uses input filename as prefix. Output files named <prefix>-<page_num>.png.")
    var all: Bool = false
    
    @Option(name: .shortAndLong, help: "Set output DPI (e.g., 150dpi). Overrides -s if both used with numbers.")
    var resolution: String?
    
    @Option(name: .shortAndLong, help: "Scaling specification (default: 100% or 1.0). NNN%: percentage (e.g., 150%) | N.N: scale factor (e.g., 1.5) | WxH: fit to WxH pixels (e.g., 800x600) | Wx: fit to width W pixels (e.g., 1024x) | xH: fit to height H pixels (e.g., x768)")
    var scale: String = "100%"
    
    @Flag(name: .shortAndLong, help: "Preserve transparency (default: white background).")
    var transparent: Bool = false
    
    @Option(name: .shortAndLong, help: "PNG compression quality (0-9, default: 6). Currently informational.")
    var quality: Int = 6
    
    @Option(name: .shortAndLong, help: "Output PNG file or prefix for batch mode. If '-', output to stdout (single page mode only).")
    var output: String?
    
    @Option(name: .shortAndLong, help: "Output directory for batch mode (converts all pages). If used, -o specifies filename prefix inside this directory.")
    var directory: String?
    
    @Flag(name: .shortAndLong, help: "Verbose output.")
    var verbose: Bool = false
    
    @Flag(name: .shortAndLong, help: "Include extracted text in output filename (batch mode only).")
    var name: Bool = false
    
    @Option(name: [.customShort("P"), .long], help: "Custom naming pattern for batch mode. Placeholders: {basename} - Input filename without extension | {page} - Page number (auto-padded) | {page:03d} - Page with custom padding | {text} - Extracted text (requires -n) | {date} - Current date (YYYYMMDD) | {time} - Current time (HHMMSS) | {total} - Total page count. Example: '{basename}_p{page:04d}_of_{total}'")
    var pattern: String?
    
    @Flag(name: [.customShort("D"), .long], help: "Preview operations without writing files.")
    var dryRun: Bool = false
    
    @Flag(name: .shortAndLong, help: "Force overwrite existing files without prompting.")
    var force: Bool = false
    
    func run() throws {
        // Check if batch mode is enabled
        let isBatchMode = all || directory != nil
        
        // Handle input source
        let document: PDFDocument
        let isStdin = inputFile == "-"
        
        if isStdin {
            // Read from stdin
            let inputData = FileHandle.standardInput.readDataToEndOfFile()
            guard let pdfDoc = PDFDocument(data: inputData) else {
                throw PDF22PNGError.fileRead
            }
            document = pdfDoc
        } else {
            // Read from file
            let url = URL(fileURLWithPath: inputFile)
            guard let pdfDoc = PDFDocument(url: url) else {
                throw PDF22PNGError.fileRead
            }
            document = pdfDoc
        }
        
        if document.isEncrypted {
            print("Error: PDF is encrypted")
            throw PDF22PNGError.fileRead
        }
        
        let pageCount = document.pageCount
        if verbose {
            print("PDF has \(pageCount) pages")
        }
        
        // Parse pages to convert
        // If -d is used without explicit page specification, convert all pages
        let pagesToConvert: [Int]
        if directory != nil && page == "1" && !all {
            // -d implies all pages like in Objective-C version
            pagesToConvert = Array(1...pageCount)
        } else if all {
            // -a explicitly requests all pages
            pagesToConvert = Array(1...pageCount)
        } else {
            // Parse the page specification
            pagesToConvert = try parsePageSpecification(page, maxPage: pageCount)
        }
        
        // Determine output configuration
        let outputConfig = determineOutputConfiguration(
            isBatchMode: isBatchMode,
            isStdin: isStdin
        )
        
        if isBatchMode {
            // Convert multiple pages using parallel processing
            if dryRun {
                // Dry run - just show what would be created
                for pageNum in pagesToConvert {
                    let outputPath = generateBatchOutputPath(
                        baseName: outputConfig.baseName,
                        pageNumber: pageNum,
                        totalPages: pageCount
                    )
                    print("Would create: \(outputPath)")
                }
            } else {
                // Parallel processing for actual conversion
                try convertPagesInParallel(
                    document: document,
                    pages: pagesToConvert,
                    baseName: outputConfig.baseName,
                    totalPages: pageCount
                )
            }
        } else {
            // Convert single page
            guard let firstPage = pagesToConvert.first else {
                throw PDF22PNGError.pageNotFound
            }
            let pageIndex = firstPage - 1
            
            if outputConfig.isStdout {
                // Write to stdout
                try convertPageToStdout(document: document, pageIndex: pageIndex)
            } else {
                try convertPage(document: document, pageIndex: pageIndex, outputPath: outputConfig.outputPath)
            }
        }
    }
    
    private func convertPage(document: PDFDocument, pageIndex: Int, outputPath: String) throws {
        guard let page = document.page(at: pageIndex) else {
            throw PDF22PNGError.pageNotFound
        }
        
        // Check if file exists and handle accordingly
        // Note: We now overwrite by default to match expected behavior
        if !force && FileManager.default.fileExists(atPath: outputPath) {
            // Only show warning if verbose, but still overwrite
            if verbose {
                print("Warning: Overwriting existing file: \(outputPath)")
            }
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        guard let scaleSpec = ScaleUtilities.parseScaleSpec(resolution ?? scale) else {
            throw PDF22PNGError.invalidScale
        }
        let scaleFactor = ScaleUtilities.calculateScaleFactor(scale: scaleSpec, pageRect: pageRect)
        
        let scaledSize = CGSize(
            width: pageRect.width * scaleFactor,
            height: pageRect.height * scaleFactor
        )
        
        if verbose {
            print("Converting page \(pageIndex + 1): \(Int(scaledSize.width))x\(Int(scaledSize.height))")
        }
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo: CGBitmapInfo = transparent ? 
            [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)] :
            [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
        
        guard let context = CGContext(
            data: nil,
            width: Int(scaledSize.width),
            height: Int(scaledSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw PDF22PNGError.renderFailed
        }
        
        if !transparent {
            context.setFillColor(CGColor.white)
            context.fill(CGRect(origin: .zero, size: scaledSize))
        }
        
        context.scaleBy(x: scaleFactor, y: scaleFactor)
        context.translateBy(x: -pageRect.minX, y: -pageRect.minY)
        
        page.draw(with: .mediaBox, to: context)
        
        guard let image = context.makeImage() else {
            throw PDF22PNGError.renderFailed
        }
        
        let url = URL(fileURLWithPath: outputPath)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw PDF22PNGError.fileWrite
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Double(quality) / 9.0
        ]
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw PDF22PNGError.fileWrite
        }
        
        // Print the path that was written (unless it's stdout)
        if outputPath != "-" {
            print(outputPath)
        }
    }
    
    private func parsePageSpecification(_ spec: String, maxPage: Int) throws -> [Int] {
        var pages: Set<Int> = []
        
        // Handle "all" pages
        if spec.lowercased() == "all" {
            return Array(1...maxPage)
        }
        
        // Split by comma for multiple specifications
        let parts = spec.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        for part in parts {
            if part.contains("-") {
                // Range specification
                let rangeParts = part.split(separator: "-")
                guard rangeParts.count == 2,
                      let start = Int(rangeParts[0]),
                      let end = Int(rangeParts[1]) else {
                    throw PDF22PNGError.invalidArgs
                }
                
                guard start >= 1 && end <= maxPage && start <= end else {
                    throw PDF22PNGError.pageNotFound
                }
                
                for i in start...end {
                    pages.insert(i)
                }
            } else {
                // Single page
                guard let pageNum = Int(part) else {
                    throw PDF22PNGError.invalidArgs
                }
                
                guard pageNum >= 1 && pageNum <= maxPage else {
                    throw PDF22PNGError.pageNotFound
                }
                
                pages.insert(pageNum)
            }
        }
        
        return pages.sorted()
    }
    
    private func determineOutputConfiguration(isBatchMode: Bool, isStdin: Bool) -> (baseName: String, outputPath: String, isStdout: Bool) {
        var baseName = "output"
        var outputPath = ""
        var isStdout = false
        
        if !isStdin {
            let url = URL(fileURLWithPath: inputFile)
            baseName = url.deletingPathExtension().lastPathComponent
        }
        
        if isBatchMode {
            // Batch mode output configuration
            if let dir = directory {
                // Create directory if it doesn't exist
                try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            }
            
            if let prefix = output {
                baseName = prefix
            } else if let outFile = outputFile {
                baseName = URL(fileURLWithPath: outFile).deletingPathExtension().lastPathComponent
            }
        } else {
            // Single page mode
            if let out = output {
                if out == "-" {
                    isStdout = true
                } else {
                    outputPath = out
                }
            } else if let outFile = outputFile {
                outputPath = outFile
            } else if isStdin {
                isStdout = true
            } else {
                outputPath = "\(baseName).png"
            }
        }
        
        return (baseName: baseName, outputPath: outputPath, isStdout: isStdout)
    }
    
    private func generateBatchOutputPathOptimized(baseName: String, pageNumber: Int, totalPages: Int, currentDate: String, currentTime: String) -> String {
        let outputDir = directory ?? "."
        
        if let pattern = pattern {
            // Custom pattern processing
            var result = pattern
            
            // Replace placeholders
            result = result.replacingOccurrences(of: "{basename}", with: baseName)
            result = result.replacingOccurrences(of: "{total}", with: String(totalPages))
            result = result.replacingOccurrences(of: "{date}", with: currentDate)
            result = result.replacingOccurrences(of: "{time}", with: currentTime)
            
            // Page number with custom padding
            if let regex = try? NSRegularExpression(pattern: "\\{page:([0-9]+)d\\}", options: []) {
                let nsString = result as NSString
                if let match = regex.firstMatch(in: result, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    let paddingRange = match.range(at: 1)
                    let paddingStr = nsString.substring(with: paddingRange)
                    if let padding = Int(paddingStr) {
                        let paddedPage = String(format: "%0\(padding)d", pageNumber)
                        result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(location: 0, length: nsString.length), withTemplate: paddedPage)
                    }
                } else {
                    // Default page padding
                    let digits = String(totalPages).count
                    let paddedPage = String(format: "%0\(digits)d", pageNumber)
                    result = result.replacingOccurrences(of: "{page}", with: paddedPage)
                }
            } else {
                // Default page padding
                let digits = String(totalPages).count
                let paddedPage = String(format: "%0\(digits)d", pageNumber)
                result = result.replacingOccurrences(of: "{page}", with: paddedPage)
            }
            
            // Text placeholder (if -n flag is set)
            if name {
                // TODO: Extract text from page
                result = result.replacingOccurrences(of: "{text}", with: "page\(pageNumber)")
            }
            
            return "\(outputDir)/\(result).png"
        } else {
            // Default naming - use 3 digits minimum to match Objective-C version
            let digits = max(3, String(totalPages).count)
            let paddedPage = String(format: "%0\(digits)d", pageNumber)
            return "\(outputDir)/\(baseName)-\(paddedPage).png"
        }
    }
    
    private func generateBatchOutputPath(baseName: String, pageNumber: Int, totalPages: Int) -> String {
        let outputDir = directory ?? "."
        
        if let pattern = pattern {
            // Custom pattern processing
            var result = pattern
            
            // Replace placeholders
            result = result.replacingOccurrences(of: "{basename}", with: baseName)
            result = result.replacingOccurrences(of: "{total}", with: String(totalPages))
            
            // Date and time
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            result = result.replacingOccurrences(of: "{date}", with: formatter.string(from: Date()))
            formatter.dateFormat = "HHmmss"
            result = result.replacingOccurrences(of: "{time}", with: formatter.string(from: Date()))
            
            // Page number with custom padding
            if let regex = try? NSRegularExpression(pattern: "\\{page:([0-9]+)d\\}", options: []) {
                let nsString = result as NSString
                if let match = regex.firstMatch(in: result, options: [], range: NSRange(location: 0, length: nsString.length)) {
                    let paddingRange = match.range(at: 1)
                    let paddingStr = nsString.substring(with: paddingRange)
                    if let padding = Int(paddingStr) {
                        let paddedPage = String(format: "%0\(padding)d", pageNumber)
                        result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(location: 0, length: nsString.length), withTemplate: paddedPage)
                    }
                } else {
                    // Default page padding
                    let digits = String(totalPages).count
                    let paddedPage = String(format: "%0\(digits)d", pageNumber)
                    result = result.replacingOccurrences(of: "{page}", with: paddedPage)
                }
            } else {
                // Default page padding
                let digits = String(totalPages).count
                let paddedPage = String(format: "%0\(digits)d", pageNumber)
                result = result.replacingOccurrences(of: "{page}", with: paddedPage)
            }
            
            // Text placeholder (if -n flag is set)
            if name {
                // TODO: Extract text from page
                result = result.replacingOccurrences(of: "{text}", with: "page\(pageNumber)")
            }
            
            return "\(outputDir)/\(result).png"
        } else {
            // Default naming - use 3 digits minimum to match Objective-C version
            let digits = max(3, String(totalPages).count)
            let paddedPage = String(format: "%0\(digits)d", pageNumber)
            return "\(outputDir)/\(baseName)-\(paddedPage).png"
        }
    }
    
    private func convertPageToStdout(document: PDFDocument, pageIndex: Int) throws {
        guard let page = document.page(at: pageIndex) else {
            throw PDF22PNGError.pageNotFound
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        guard let scaleSpec = ScaleUtilities.parseScaleSpec(resolution ?? scale) else {
            throw PDF22PNGError.invalidScale
        }
        let scaleFactor = ScaleUtilities.calculateScaleFactor(scale: scaleSpec, pageRect: pageRect)
        
        let scaledSize = CGSize(
            width: pageRect.width * scaleFactor,
            height: pageRect.height * scaleFactor
        )
        
        if verbose {
            fputs("Converting page \(pageIndex + 1): \(Int(scaledSize.width))x\(Int(scaledSize.height))\n", stderr)
        }
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo: CGBitmapInfo = transparent ? 
            [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)] :
            [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
        
        guard let context = CGContext(
            data: nil,
            width: Int(scaledSize.width),
            height: Int(scaledSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw PDF22PNGError.renderFailed
        }
        
        if !transparent {
            context.setFillColor(CGColor.white)
            context.fill(CGRect(origin: .zero, size: scaledSize))
        }
        
        context.scaleBy(x: scaleFactor, y: scaleFactor)
        context.translateBy(x: -pageRect.minX, y: -pageRect.minY)
        
        page.draw(with: .mediaBox, to: context)
        
        guard let image = context.makeImage() else {
            throw PDF22PNGError.renderFailed
        }
        
        // Write to stdout
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) else {
            throw PDF22PNGError.fileWrite
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Double(quality) / 9.0
        ]
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw PDF22PNGError.fileWrite
        }
        
        FileHandle.standardOutput.write(data as Data)
        
        // Don't print path for stdout output
    }
    
    
    
    private func convertPagesInParallel(document: PDFDocument, pages: [Int], baseName: String, totalPages: Int) throws {
        let renderQueue = DispatchQueue(label: "com.pdf22png.render", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "progress.updates")
        
        var successCount = 0
        var errorCount = 0
        
        // Optimize concurrency based on memory and CPU
        let optimalConcurrency = min(pages.count, ProcessInfo.processInfo.activeProcessorCount * 2)
        let semaphore = DispatchSemaphore(value: optimalConcurrency)
        
        // Pre-calculate shared resources
        let sharedColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let scaleSpec = ScaleUtilities.parseScaleSpec(resolution ?? scale) else {
            throw PDF22PNGError.invalidScale
        }
        
        // Cache date formatters for batch naming
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmmss"
        let currentDate = dateFormatter.string(from: Date())
        let currentTime = timeFormatter.string(from: Date())
        
        for pageNum in pages {
            group.enter()
            
            renderQueue.async { [self] in
                semaphore.wait()
                defer {
                    semaphore.signal()
                    group.leave()
                }
                
                autoreleasepool {
                    do {
                        let pageIndex = pageNum - 1
                        let outputPath = generateBatchOutputPathOptimized(
                            baseName: baseName,
                            pageNumber: pageNum,
                            totalPages: totalPages,
                            currentDate: currentDate,
                            currentTime: currentTime
                        )
                        
                        try convertPageSyncOptimized2(
                            document: document,
                            pageIndex: pageIndex,
                            outputPath: outputPath,
                            colorSpace: sharedColorSpace,
                            scaleSpec: scaleSpec
                        )
                        
                        serialQueue.sync {
                            successCount += 1
                            print(outputPath)
                        }
                    } catch {
                        serialQueue.sync {
                            errorCount += 1
                            if verbose {
                                print("Error converting page \(pageNum): \(error)", to: &standardError)
                            }
                        }
                    }
                }
            }
        }
        
        group.wait()
        
        if errorCount > 0 {
            throw PDF22PNGError.renderFailed
        }
    }
    
    private func convertPageSyncOptimized2(document: PDFDocument, pageIndex: Int, outputPath: String, colorSpace: CGColorSpace, scaleSpec: ScaleUtilities.ScaleSpec) throws {
        guard let page = document.page(at: pageIndex) else {
            throw PDF22PNGError.pageNotFound
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        let scaleFactor = ScaleUtilities.calculateScaleFactor(scale: scaleSpec, pageRect: pageRect)
        
        let scaledSize = CGSize(
            width: pageRect.width * scaleFactor,
            height: pageRect.height * scaleFactor
        )
        
        // Use aligned memory for better performance
        let bytesPerRow = (Int(scaledSize.width) * 4 + 15) & ~15
        let bitmapData = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * Int(scaledSize.height), alignment: 16)
        defer { bitmapData.deallocate() }
        
        let bitmapInfo: CGBitmapInfo = transparent ? 
            [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)] :
            [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
        
        guard let context = CGContext(
            data: bitmapData,
            width: Int(scaledSize.width),
            height: Int(scaledSize.height),
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw PDF22PNGError.renderFailed
        }
        
        if !transparent {
            context.setFillColor(CGColor.white)
            context.fill(CGRect(origin: .zero, size: scaledSize))
        }
        
        context.scaleBy(x: scaleFactor, y: scaleFactor)
        context.translateBy(x: -pageRect.minX, y: -pageRect.minY)
        
        // Use high-quality rendering
        context.interpolationQuality = CGInterpolationQuality.high
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        
        page.draw(with: .mediaBox, to: context)
        
        guard let image = context.makeImage() else {
            throw PDF22PNGError.renderFailed
        }
        
        let url = URL(fileURLWithPath: outputPath)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw PDF22PNGError.fileWrite
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Double(quality) / 9.0
        ]
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw PDF22PNGError.fileWrite
        }
    }
    
    private func convertPageSyncOptimized(document: PDFDocument, pageIndex: Int, outputPath: String) throws {
        // Create a local autorelease pool to manage memory more aggressively
        try autoreleasepool {
        guard let page = document.page(at: pageIndex) else {
            throw PDF22PNGError.pageNotFound
        }
        
        // Check if file exists and handle accordingly
        // Note: We now overwrite by default to match expected behavior
        if !force && FileManager.default.fileExists(atPath: outputPath) {
            // Only show warning if verbose, but still overwrite
            if verbose {
                print("Warning: Overwriting existing file: \(outputPath)")
            }
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        guard let scaleSpec = ScaleUtilities.parseScaleSpec(resolution ?? scale) else {
            throw PDF22PNGError.invalidScale
        }
        let scaleFactor = ScaleUtilities.calculateScaleFactor(scale: scaleSpec, pageRect: pageRect)
        
        let scaledSize = CGSize(
            width: pageRect.width * scaleFactor,
            height: pageRect.height * scaleFactor
        )
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo: CGBitmapInfo = transparent ? 
            [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)] :
            [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
        
        guard let context = CGContext(
            data: nil,
            width: Int(scaledSize.width),
            height: Int(scaledSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw PDF22PNGError.renderFailed
        }
        
        if !transparent {
            context.setFillColor(CGColor.white)
            context.fill(CGRect(origin: .zero, size: scaledSize))
        }
        
        context.scaleBy(x: scaleFactor, y: scaleFactor)
        context.translateBy(x: -pageRect.minX, y: -pageRect.minY)
        
        page.draw(with: .mediaBox, to: context)
        
        guard let image = context.makeImage() else {
            throw PDF22PNGError.renderFailed
        }
        
        let url = URL(fileURLWithPath: outputPath)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw PDF22PNGError.fileWrite
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Double(quality) / 9.0
        ]
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw PDF22PNGError.fileWrite
        }
        }
    }
    
    
}