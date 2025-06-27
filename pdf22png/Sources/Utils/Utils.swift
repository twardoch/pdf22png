import Foundation
import CoreGraphics

// MARK: - ScaleSpec

public struct ScaleSpec {
    public var scaleFactor: Double
    public var maxWidth: Double
    public var maxHeight: Double
    public var dpi: Double
    public var isPercentage: Bool
    public var isDPI: Bool
    public var hasWidth: Bool
    public var hasHeight: Bool
}

// MARK: - Scale Parsing

public func parseScaleSpec(_ spec: String) -> ScaleSpec? {
    // Trim whitespace
    let trimmedSpec = spec.trimmingCharacters(in: .whitespaces)
    
    var scale = ScaleSpec(scaleFactor: 1.0, maxWidth: 0, maxHeight: 0, dpi: 0, isPercentage: false, isDPI: false, hasWidth: false, hasHeight: false)

    // Check for percentage (NNN%)
    if trimmedSpec.hasSuffix("%") {
        let numStr = String(trimmedSpec.dropLast())
        if let value = Double(numStr) {
            scale.scaleFactor = value / 100.0
            scale.isPercentage = true
            if scale.scaleFactor <= 0 {
                fputs("Error: Scale percentage must be positive.\n", stderr)
                return nil
            }
            return scale
        }
    }

    // Check for DPI (AAAdpi) - case insensitive
    let lowerSpec = spec.lowercased()
    if lowerSpec.hasSuffix("dpi") {
        let numStr = String(spec.dropLast(3))
        if let value = Double(numStr) {
            scale.dpi = value
            scale.isDPI = true
            if scale.dpi <= 0 {
                fputs("Error: DPI value must be positive.\n", stderr)
                return nil
            }
            return scale
        }
    }

    // Check for dimensions (WxH, Wx, xH)
    if spec.contains("x") {
        let parts = spec.split(separator: "x", maxSplits: 1, omittingEmptySubsequences: false)
        let widthStr = String(parts[0])
        let heightStr = parts.count > 1 ? String(parts[1]) : ""

        if !widthStr.isEmpty {
            if let value = Double(widthStr) {
                scale.maxWidth = value
                if scale.maxWidth <= 0 {
                    fputs("Error: Width dimension must be positive.\n", stderr)
                    return nil
                }
                scale.hasWidth = true
            }
        }

        if !heightStr.isEmpty {
            if let value = Double(heightStr) {
                scale.maxHeight = value
                if scale.maxHeight <= 0 {
                    fputs("Error: Height dimension must be positive.\n", stderr)
                    return nil
                }
                scale.hasHeight = true
            }
        }
        
        if scale.hasWidth || scale.hasHeight {
            return scale
        }
    }

    // If no known suffix or 'x' separator, try to parse as a simple number (scale factor)
    if let factor = Double(spec) {
        if factor <= 0 {
            fputs("Error: Scale factor must be positive.\n", stderr)
            return nil
        }
        scale.scaleFactor = factor
        scale.isPercentage = false
        scale.isDPI = false
        scale.hasWidth = false
        scale.hasHeight = false
        return scale
    }

    fputs("Error: Invalid scale specification format: \(spec)\n", stderr)
    return nil
}

// MARK: - Scale Calculation

public func calculateScaleFactor(scale: ScaleSpec, pageRect: CGRect) -> CGFloat {
    if scale.isPercentage {
        return CGFloat(scale.scaleFactor)
    }

    if scale.isDPI {
        // PDF points are 72 DPI by default
        return CGFloat(scale.dpi / 72.0)
    }

    // If only scaleFactor is set (e.g. from "-s 2.0")
    if !scale.hasWidth && !scale.hasHeight && scale.scaleFactor > 0 {
        return CGFloat(scale.scaleFactor)
    }

    var scaleX: CGFloat = 1.0
    var scaleY: CGFloat = 1.0

    if scale.hasWidth && pageRect.size.width > 0 {
        scaleX = CGFloat(scale.maxWidth / Double(pageRect.size.width))
    }

    if scale.hasHeight && pageRect.size.height > 0 {
        scaleY = CGFloat(scale.maxHeight / Double(pageRect.size.height))
    }

    if scale.hasWidth && scale.hasHeight {
        return min(scaleX, scaleY)
    } else if scale.hasWidth {
        return scaleX
    } else if scale.hasHeight {
        return scaleY
    }

    return 1.0
}
