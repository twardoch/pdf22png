import Foundation
import CoreGraphics
import PDFKit
import ArgumentParser

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

// MARK: - Scale Specification

enum ScaleSpecification {
    case percentage(Double)
    case dpi(Double)
    case dimensions(width: Int, height: Int)
    case scaleFactor(Double)
}

// MARK: - Command Line Interface

@main
struct PDF22PNGCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf22png-swift",
        abstract: "Convert PDF pages to PNG images",
        version: "1.0.0"
    )
    
    @Argument(help: "Input PDF file")
    var inputFile: String
    
    @Option(name: .shortAndLong, help: "Output PNG file")
    var output: String?
    
    @Option(name: .shortAndLong, help: "Page number to convert (default: 1)")
    var page: Int = 1
    
    @Option(name: .shortAndLong, help: "Scale specification (e.g., 150%, 300dpi, 1024x768)")
    var scale: String = "100%"
    
    @Flag(name: .shortAndLong, help: "Convert all pages")
    var all: Bool = false
    
    @Flag(name: .shortAndLong, help: "Verbose output")
    var verbose: Bool = false
    
    @Flag(help: "Transparent background")
    var transparent: Bool = false
    
    @Option(help: "PNG quality (0-9)")
    var quality: Int = 6
    
    func run() throws {
        // Load PDF document
        let url = URL(fileURLWithPath: inputFile)
        guard let document = PDFDocument(url: url) else {
            throw PDF22PNGError.fileRead
        }
        
        if document.isEncrypted {
            print("Error: PDF is encrypted")
            throw PDF22PNGError.fileRead
        }
        
        let pageCount = document.pageCount
        if verbose {
            print("PDF has \(pageCount) pages")
        }
        
        if all {
            // Convert all pages
            for pageIndex in 0..<pageCount {
                let outputPath = generateOutputPath(baseName: inputFile, pageNumber: pageIndex + 1)
                try convertPage(document: document, pageIndex: pageIndex, outputPath: outputPath)
            }
        } else {
            // Convert single page
            let pageIndex = page - 1
            guard pageIndex >= 0 && pageIndex < pageCount else {
                throw PDF22PNGError.pageNotFound
            }
            
            let outputPath = output ?? generateOutputPath(baseName: inputFile, pageNumber: page)
            try convertPage(document: document, pageIndex: pageIndex, outputPath: outputPath)
        }
    }
    
    private func convertPage(document: PDFDocument, pageIndex: Int, outputPath: String) throws {
        guard let page = document.page(at: pageIndex) else {
            throw PDF22PNGError.pageNotFound
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        let scaleSpec = parseScale(scale)
        let scaleFactor = calculateScaleFactor(spec: scaleSpec, pageRect: pageRect)
        
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
        
        if verbose {
            print("✓ Saved: \(outputPath)")
        }
    }
    
    private func parseScale(_ scaleString: String) -> ScaleSpecification {
        let trimmed = scaleString.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasSuffix("%") {
            let percentString = String(trimmed.dropLast())
            if let percent = Double(percentString) {
                return .percentage(percent)
            }
        } else if trimmed.hasSuffix("dpi") {
            let dpiString = String(trimmed.dropLast(3))
            if let dpi = Double(dpiString) {
                return .dpi(dpi)
            }
        } else if trimmed.contains("x") {
            let parts = trimmed.split(separator: "x")
            if parts.count == 2,
               let width = Int(parts[0]),
               let height = Int(parts[1]) {
                return .dimensions(width: width, height: height)
            }
        } else if let factor = Double(trimmed) {
            return .scaleFactor(factor)
        }
        
        return .percentage(100.0)
    }
    
    private func calculateScaleFactor(spec: ScaleSpecification, pageRect: CGRect) -> CGFloat {
        switch spec {
        case .percentage(let percent):
            return CGFloat(percent / 100.0)
        case .dpi(let dpi):
            return CGFloat(dpi / 72.0)
        case .dimensions(let width, let height):
            let widthScale = CGFloat(width) / pageRect.width
            let heightScale = CGFloat(height) / pageRect.height
            return min(widthScale, heightScale)
        case .scaleFactor(let factor):
            return CGFloat(factor)
        }
    }
    
    private func generateOutputPath(baseName: String, pageNumber: Int) -> String {
        let url = URL(fileURLWithPath: baseName)
        let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let directory = url.deletingLastPathComponent().path
        
        if all {
            return "\(directory)/\(nameWithoutExtension)_page_\(String(format: "%03d", pageNumber)).png"
        } else {
            return "\(directory)/\(nameWithoutExtension).png"
        }
    }
}