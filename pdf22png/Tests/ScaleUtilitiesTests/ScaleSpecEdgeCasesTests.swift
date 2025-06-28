import XCTest
@testable import ScaleUtilities

final class ScaleSpecEdgeCasesTests: XCTestCase {
    
    // MARK: - Width-only tests
    
    func testWidthOnlyScale() {
        guard let spec = parseScaleSpec("800x") else {
            XCTFail("Failed to parse width-only scale")
            return
        }
        XCTAssertTrue(spec.hasWidth)
        XCTAssertFalse(spec.hasHeight)
        XCTAssertEqual(spec.maxWidth, 800)
        XCTAssertEqual(spec.maxHeight, 0)
    }
    
    func testWidthOnlyScaleWithSpaces() {
        // Should handle trimming
        guard let spec = parseScaleSpec(" 1024x ") else {
            XCTFail("Failed to parse width-only scale with spaces")
            return
        }
        XCTAssertTrue(spec.hasWidth)
        XCTAssertEqual(spec.maxWidth, 1024)
    }
    
    // MARK: - Height-only tests
    
    func testHeightOnlyScale() {
        guard let spec = parseScaleSpec("x600") else {
            XCTFail("Failed to parse height-only scale")
            return
        }
        XCTAssertFalse(spec.hasWidth)
        XCTAssertTrue(spec.hasHeight)
        XCTAssertEqual(spec.maxWidth, 0)
        XCTAssertEqual(spec.maxHeight, 600)
    }
    
    // MARK: - Zero and negative values
    
    func testZeroPercentage() {
        let spec = parseScaleSpec("0%")
        XCTAssertNil(spec, "Should reject 0% scale")
    }
    
    func testNegativePercentage() {
        let spec = parseScaleSpec("-50%")
        XCTAssertNil(spec, "Should reject negative percentage")
    }
    
    func testZeroDPI() {
        let spec = parseScaleSpec("0dpi")
        XCTAssertNil(spec, "Should reject 0 DPI")
    }
    
    func testNegativeDPI() {
        let spec = parseScaleSpec("-100dpi")
        XCTAssertNil(spec, "Should reject negative DPI")
    }
    
    func testZeroWidth() {
        let spec = parseScaleSpec("0x600")
        XCTAssertNil(spec, "Should reject 0 width")
    }
    
    func testZeroHeight() {
        let spec = parseScaleSpec("800x0")
        XCTAssertNil(spec, "Should reject 0 height")
    }
    
    func testNegativeDimensions() {
        let spec1 = parseScaleSpec("-800x600")
        XCTAssertNil(spec1, "Should reject negative width")
        
        let spec2 = parseScaleSpec("800x-600")
        XCTAssertNil(spec2, "Should reject negative height")
    }
    
    // MARK: - Decimal values
    
    func testDecimalPercentage() {
        guard let spec = parseScaleSpec("150.5%") else {
            XCTFail("Failed to parse decimal percentage")
            return
        }
        XCTAssertTrue(spec.isPercentage)
        XCTAssertEqual(spec.scaleFactor, 1.505, accuracy: 0.0001)
    }
    
    func testDecimalDPI() {
        guard let spec = parseScaleSpec("300.5dpi") else {
            XCTFail("Failed to parse decimal DPI")
            return
        }
        XCTAssertTrue(spec.isDPI)
        XCTAssertEqual(spec.dpi, 300.5, accuracy: 0.1)
    }
    
    func testDecimalDimensions() {
        // Most image formats don't support fractional pixels, but we should handle parsing
        guard let spec = parseScaleSpec("800.5x600.5") else {
            XCTFail("Failed to parse decimal dimensions")
            return
        }
        XCTAssertEqual(spec.maxWidth, 800.5, accuracy: 0.1)
        XCTAssertEqual(spec.maxHeight, 600.5, accuracy: 0.1)
    }
    
    func testDecimalScaleFactor() {
        guard let spec = parseScaleSpec("1.5") else {
            XCTFail("Failed to parse decimal scale factor")
            return
        }
        XCTAssertEqual(spec.scaleFactor, 1.5, accuracy: 0.0001)
    }
    
    // MARK: - Very large values
    
    func testVeryLargePercentage() {
        guard let spec = parseScaleSpec("10000%") else {
            XCTFail("Failed to parse large percentage")
            return
        }
        XCTAssertEqual(spec.scaleFactor, 100.0, accuracy: 0.0001)
    }
    
    func testVeryLargeDPI() {
        guard let spec = parseScaleSpec("9600dpi") else {
            XCTFail("Failed to parse large DPI")
            return
        }
        XCTAssertEqual(spec.dpi, 9600, accuracy: 0.1)
    }
    
    func testVeryLargeDimensions() {
        guard let spec = parseScaleSpec("10000x10000") else {
            XCTFail("Failed to parse large dimensions")
            return
        }
        XCTAssertEqual(spec.maxWidth, 10000)
        XCTAssertEqual(spec.maxHeight, 10000)
    }
    
    // MARK: - Invalid formats
    
    func testEmptyString() {
        let spec = parseScaleSpec("")
        XCTAssertNil(spec, "Should reject empty string")
    }
    
    func testOnlyX() {
        let spec = parseScaleSpec("x")
        XCTAssertNil(spec, "Should reject lone 'x'")
    }
    
    func testMultipleX() {
        let spec = parseScaleSpec("800x600x400")
        // The current implementation will treat this as "800x600x400" with width=800 and height="600x400"
        // Since "600x400" is not a valid number, it should fail
        XCTAssertNil(spec, "Should reject multiple 'x' separators")
    }
    
    func testInvalidSuffix() {
        let spec1 = parseScaleSpec("100px")
        XCTAssertNil(spec1, "Should reject 'px' suffix")
        
        let spec2 = parseScaleSpec("100pt")
        XCTAssertNil(spec2, "Should reject 'pt' suffix")
    }
    
    func testMixedFormats() {
        let spec1 = parseScaleSpec("100%dpi")
        XCTAssertNil(spec1, "Should reject mixed percentage and DPI")
        
        // "800x600%" is parsed as width=800, height="600%" 
        // Since "600%" is not a valid number for height, it should actually work as width-only
        let spec2 = parseScaleSpec("800x600%")
        if let spec = spec2 {
            // This is actually valid - it's treated as 800x with invalid height (ignored)
            XCTAssertTrue(spec.hasWidth)
            XCTAssertFalse(spec.hasHeight)
            XCTAssertEqual(spec.maxWidth, 800)
        } else {
            XCTFail("Should parse as width-only when height is invalid")
        }
    }
    
    // MARK: - Case sensitivity
    
    func testUppercaseDPI() {
        guard let spec = parseScaleSpec("300DPI") else {
            XCTFail("Failed to parse uppercase DPI")
            return
        }
        XCTAssertTrue(spec.isDPI)
        XCTAssertEqual(spec.dpi, 300, accuracy: 0.1)
    }
    
    func testMixedCaseDPI() {
        guard let spec = parseScaleSpec("300DpI") else {
            XCTFail("Failed to parse mixed case DPI")
            return
        }
        XCTAssertTrue(spec.isDPI)
        XCTAssertEqual(spec.dpi, 300, accuracy: 0.1)
    }
}