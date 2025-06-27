import XCTest
@testable import ScaleUtilities

final class CalculateScaleFactorTests: XCTestCase {
    
    // MARK: - Percentage scaling tests
    
    func testPercentageScaling() {
        let spec = ScaleSpec(
            scaleFactor: 1.5,
            maxWidth: 0,
            maxHeight: 0,
            dpi: 0,
            isPercentage: true,
            isDPI: false,
            hasWidth: false,
            hasHeight: false
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter at 72 DPI
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        XCTAssertEqual(scale, 1.5, accuracy: 0.0001, "150% should result in 1.5x scale")
    }
    
    func testSmallPercentageScaling() {
        let spec = ScaleSpec(
            scaleFactor: 0.5,
            maxWidth: 0,
            maxHeight: 0,
            dpi: 0,
            isPercentage: true,
            isDPI: false,
            hasWidth: false,
            hasHeight: false
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        XCTAssertEqual(scale, 0.5, accuracy: 0.0001, "50% should result in 0.5x scale")
    }
    
    // MARK: - DPI scaling tests
    
    func testDPIScaling72() {
        let spec = ScaleSpec(
            scaleFactor: 1.0,
            maxWidth: 0,
            maxHeight: 0,
            dpi: 72,
            isPercentage: false,
            isDPI: true,
            hasWidth: false,
            hasHeight: false
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        XCTAssertEqual(scale, 1.0, accuracy: 0.0001, "72 DPI should result in 1.0x scale")
    }
    
    func testDPIScaling300() {
        let spec = ScaleSpec(
            scaleFactor: 1.0,
            maxWidth: 0,
            maxHeight: 0,
            dpi: 300,
            isPercentage: false,
            isDPI: true,
            hasWidth: false,
            hasHeight: false
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        XCTAssertEqual(scale, 300.0 / 72.0, accuracy: 0.0001, "300 DPI should result in 4.167x scale")
    }
    
    // MARK: - Fixed dimension tests
    
    func testFixedWidthOnly() {
        let spec = ScaleSpec(
            scaleFactor: 1.0,
            maxWidth: 1224,
            maxHeight: 0,
            dpi: 0,
            isPercentage: false,
            isDPI: false,
            hasWidth: true,
            hasHeight: false
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        XCTAssertEqual(scale, 2.0, accuracy: 0.0001, "1224px width from 612px should be 2.0x scale")
    }
    
    func testFixedHeightOnly() {
        let spec = ScaleSpec(
            scaleFactor: 1.0,
            maxWidth: 0,
            maxHeight: 1584,
            dpi: 0,
            isPercentage: false,
            isDPI: false,
            hasWidth: false,
            hasHeight: true
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        XCTAssertEqual(scale, 2.0, accuracy: 0.0001, "1584px height from 792px should be 2.0x scale")
    }
    
    func testFixedBothDimensionsLimitedByWidth() {
        let spec = ScaleSpec(
            scaleFactor: 1.0,
            maxWidth: 800,
            maxHeight: 2000,
            dpi: 0,
            isPercentage: false,
            isDPI: false,
            hasWidth: true,
            hasHeight: true
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        // Width scale: 800/612 = 1.307
        // Height scale: 2000/792 = 2.525
        // Should use the smaller scale to fit within bounds
        XCTAssertEqual(scale, 800.0 / 612.0, accuracy: 0.0001, "Should be limited by width")
    }
    
    func testFixedBothDimensionsLimitedByHeight() {
        let spec = ScaleSpec(
            scaleFactor: 1.0,
            maxWidth: 2000,
            maxHeight: 900,
            dpi: 0,
            isPercentage: false,
            isDPI: false,
            hasWidth: true,
            hasHeight: true
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        // Width scale: 2000/612 = 3.268
        // Height scale: 900/792 = 1.136
        // Should use the smaller scale to fit within bounds
        XCTAssertEqual(scale, 900.0 / 792.0, accuracy: 0.0001, "Should be limited by height")
    }
    
    // MARK: - Direct scale factor tests
    
    func testDirectScaleFactor() {
        let spec = ScaleSpec(
            scaleFactor: 2.5,
            maxWidth: 0,
            maxHeight: 0,
            dpi: 0,
            isPercentage: false,
            isDPI: false,
            hasWidth: false,
            hasHeight: false
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        XCTAssertEqual(scale, 2.5, accuracy: 0.0001, "Direct scale factor should be used as-is")
    }
    
    // MARK: - Edge cases
    
    func testZeroSizedPage() {
        let spec = ScaleSpec(
            scaleFactor: 2.0,
            maxWidth: 0,
            maxHeight: 0,
            dpi: 0,
            isPercentage: false,
            isDPI: false,
            hasWidth: false,
            hasHeight: false
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 0, height: 0)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        // Should still return the scale factor even with zero-sized page
        XCTAssertEqual(scale, 2.0, accuracy: 0.0001, "Should handle zero-sized page")
    }
    
    func testVerySmallPage() {
        let spec = ScaleSpec(
            scaleFactor: 1.0,
            maxWidth: 100,
            maxHeight: 0,
            dpi: 0,
            isPercentage: false,
            isDPI: false,
            hasWidth: true,
            hasHeight: false
        )
        
        let pageRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let scale = calculateScaleFactor(scale: spec, pageRect: pageRect)
        
        XCTAssertEqual(scale, 100.0, accuracy: 0.0001, "Should handle very small page")
    }
    
    func testNonSquarePage() {
        let spec = ScaleSpec(
            scaleFactor: 1.0,
            maxWidth: 1000,
            maxHeight: 1000,
            dpi: 0,
            isPercentage: false,
            isDPI: false,
            hasWidth: true,
            hasHeight: true
        )
        
        // Very wide page
        let widePageRect = CGRect(x: 0, y: 0, width: 1000, height: 100)
        let wideScale = calculateScaleFactor(scale: spec, pageRect: widePageRect)
        XCTAssertEqual(wideScale, 1.0, accuracy: 0.0001, "Wide page should scale to fit width")
        
        // Very tall page
        let tallPageRect = CGRect(x: 0, y: 0, width: 100, height: 1000)
        let tallScale = calculateScaleFactor(scale: spec, pageRect: tallPageRect)
        XCTAssertEqual(tallScale, 1.0, accuracy: 0.0001, "Tall page should scale to fit height")
    }
}