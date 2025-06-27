import XCTest
@testable import ScaleUtilities

final class ScaleSpecTests: XCTestCase {
    func testPercentageScale() {
        guard let spec = parseScaleSpec("150%") else {
            XCTFail("Failed to parse percentage scale")
            return
        }
        XCTAssertTrue(spec.isPercentage)
        XCTAssertEqual(spec.scaleFactor, 1.5, accuracy: 0.0001)
    }

    func testDpiScale() {
        guard let spec = parseScaleSpec("300dpi") else {
            XCTFail("Failed to parse dpi scale")
            return
        }
        XCTAssertTrue(spec.isDPI)
        XCTAssertEqual(spec.dpi, 300, accuracy: 0.1)
    }

    func testDimensionScale() {
        guard let spec = parseScaleSpec("800x600") else {
            XCTFail("Failed to parse dimension scale")
            return
        }
        XCTAssertTrue(spec.hasWidth)
        XCTAssertTrue(spec.hasHeight)
        XCTAssertEqual(spec.maxWidth, 800)
        XCTAssertEqual(spec.maxHeight, 600)
    }

    func testScaleFactor() {
        guard let spec = parseScaleSpec("2.0") else {
            XCTFail("Failed to parse numeric scale factor")
            return
        }
        XCTAssertFalse(spec.isPercentage)
        XCTAssertFalse(spec.isDPI)
        XCTAssertEqual(spec.scaleFactor, 2.0, accuracy: 0.0001)
    }

    func testInvalidScale() {
        let spec = parseScaleSpec("invalid!")
        XCTAssertNil(spec, "Parsing should fail for invalid spec")
    }
} 