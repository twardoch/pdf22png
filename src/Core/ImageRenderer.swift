import Foundation
import CoreGraphics
import PDFKit
import UniformTypeIdentifiers

// MARK: - Image Rendering

class ImageRenderer {
    static let shared = ImageRenderer()
    private init() {}
    
    struct RenderOptions {
        let scaleFactor: CGFloat
        let transparentBackground: Bool
        let quality: Int
        let verbose: Bool
        let dryRun: Bool
        let forceOverwrite: Bool
    }
    
    func renderPageToImage(page: PDFPage, options: RenderOptions) -> CGImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let scaledWidth = Int(pageRect.width * options.scaleFactor)
        let scaledHeight = Int(pageRect.height * options.scaleFactor)
        
        logMessage(options.verbose, "Rendering page at \(scaledWidth)x\(scaledHeight) (scale: \(options.scaleFactor))")
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = options.transparentBackground ? 
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
        
        context.scaleBy(x: options.scaleFactor, y: options.scaleFactor)
        
        if !options.transparentBackground {
            context.setFillColor(CGColor.white)
            context.fill(CGRect(x: 0, y: 0, width: pageRect.width, height: pageRect.height))
        }
        
        page.draw(with: .mediaBox, to: context)
        
        return context.makeImage()
    }
    
    func writeImageToFile(image: CGImage, path: String, options: RenderOptions) -> Bool {
        if options.dryRun {
            let width = image.width
            let height = image.height
            print("[DRY-RUN] Would write \(width)x\(height) PNG to: \(path)")
            return true
        }
        
        // Check if file exists and handle overwrite
        if FileManager.default.fileExists(atPath: path) && !options.forceOverwrite {
            print("File \(path) already exists. Use --force to overwrite.")
            return false
        }
        
        let url = URL(fileURLWithPath: path)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            return false
        }
        
        let compressionOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: CGFloat(options.quality) / 9.0
        ]
        
        CGImageDestinationAddImage(destination, image, compressionOptions as CFDictionary)
        let success = CGImageDestinationFinalize(destination)
        
        if success {
            logMessage(options.verbose, "Successfully wrote PNG to: \(path)")
        }
        
        return success
    }
    
    func writeImageToStdout(image: CGImage, options: RenderOptions) -> Bool {
        logMessage(options.verbose, "Writing PNG to stdout")
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return false
        }
        
        let compressionOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: CGFloat(options.quality) / 9.0
        ]
        
        CGImageDestinationAddImage(destination, image, compressionOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return false
        }
        
        let stdout = FileHandle.standardOutput
        stdout.write(data as Data)
        return true
    }
    
    func calculateScaleFactor(spec: ScaleSpecification, pageRect: CGRect) -> CGFloat {
        switch spec {
        case .percentage(let percent):
            return percent / 100.0
        case .factor(let factor):
            return factor
        case .resolution(let dpi):
            return dpi / 72.0  // 72 DPI is the default PDF resolution
        case .width(let width):
            return width / pageRect.width
        case .height(let height):
            return height / pageRect.height
        case .fit(let width, let height):
            let scaleX = width / pageRect.width
            let scaleY = height / pageRect.height
            return min(scaleX, scaleY)
        }
    }
}