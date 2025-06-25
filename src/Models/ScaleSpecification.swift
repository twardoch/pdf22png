import Foundation
import CoreGraphics

// MARK: - Scale Specification

enum ScaleSpecification {
    case percentage(CGFloat)
    case factor(CGFloat)
    case resolution(CGFloat)  // DPI
    case width(CGFloat)
    case height(CGFloat)
    case fit(width: CGFloat, height: CGFloat)
}

struct ScaleParser {
    static func parseScaleSpecification(_ scaleStr: String) -> ScaleSpecification? {
        let trimmed = scaleStr.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasSuffix("%") {
            let percentStr = String(trimmed.dropLast())
            guard let percent = Double(percentStr), percent > 0 else { return nil }
            return .percentage(CGFloat(percent))
        }
        
        if trimmed.hasSuffix("dpi") {
            let dpiStr = String(trimmed.dropLast(3))
            guard let dpi = Double(dpiStr), dpi > 0 else { return nil }
            return .resolution(CGFloat(dpi))
        }
        
        if trimmed.contains("x") {
            let parts = trimmed.components(separatedBy: "x")
            guard parts.count == 2 else { return nil }
            
            let widthStr = parts[0]
            let heightStr = parts[1]
            
            if !widthStr.isEmpty && !heightStr.isEmpty {
                guard let width = Double(widthStr), width > 0,
                      let height = Double(heightStr), height > 0 else { return nil }
                return .fit(width: CGFloat(width), height: CGFloat(height))
            } else if !widthStr.isEmpty {
                guard let width = Double(widthStr), width > 0 else { return nil }
                return .width(CGFloat(width))
            } else if !heightStr.isEmpty {
                guard let height = Double(heightStr), height > 0 else { return nil }
                return .height(CGFloat(height))
            }
            
            return nil
        }
        
        guard let factor = Double(trimmed), factor > 0 else { return nil }
        return .factor(CGFloat(factor))
    }
}