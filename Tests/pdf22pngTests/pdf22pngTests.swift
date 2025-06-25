import XCTest
@testable import pdf22png

final class pdf22pngTests: XCTestCase {
    
    // MARK: - Scale Specification Tests
    
    func testParseScaleSpec_percentage() {
        let scale = parseScaleSpecification("150%")
        XCTAssertNotNil(scale)
        XCTAssertTrue(scale!.isPercentage)
        XCTAssertEqual(scale!.scaleFactor, 1.5, accuracy: 0.001)
        XCTAssertFalse(scale!.isDPI)
    }
    
    func testParseScaleSpec_factor() {
        let scale = parseScaleSpecification("2.0")
        XCTAssertNotNil(scale)
        XCTAssertFalse(scale!.isPercentage)
        XCTAssertEqual(scale!.scaleFactor, 2.0, accuracy: 0.001)
    }
    
    func testParseScaleSpec_dpi() {
        let scale = parseScaleSpecification("300dpi")
        XCTAssertNotNil(scale)
        XCTAssertTrue(scale!.isDPI)
        XCTAssertEqual(scale!.dpi, 300.0, accuracy: 0.001)
    }
    
    func testParseScaleSpec_dimensions() {
        // Test width only
        var scale = parseScaleSpecification("800x")
        XCTAssertNotNil(scale)
        XCTAssertTrue(scale!.hasWidth)
        XCTAssertFalse(scale!.hasHeight)
        XCTAssertEqual(scale!.maxWidth, 800.0, accuracy: 0.001)
        
        // Test height only
        scale = parseScaleSpecification("x600")
        XCTAssertNotNil(scale)
        XCTAssertFalse(scale!.hasWidth)
        XCTAssertTrue(scale!.hasHeight)
        XCTAssertEqual(scale!.maxHeight, 600.0, accuracy: 0.001)
        
        // Test both dimensions
        scale = parseScaleSpecification("800x600")
        XCTAssertNotNil(scale)
        XCTAssertTrue(scale!.hasWidth)
        XCTAssertTrue(scale!.hasHeight)
        XCTAssertEqual(scale!.maxWidth, 800.0, accuracy: 0.001)
        XCTAssertEqual(scale!.maxHeight, 600.0, accuracy: 0.001)
    }
    
    func testParseScaleSpec_invalid() {
        XCTAssertNil(parseScaleSpecification("invalid"))
        XCTAssertNil(parseScaleSpecification(""))
        XCTAssertNil(parseScaleSpecification("-100%"))
        XCTAssertNil(parseScaleSpecification("0dpi"))
    }
    
    // MARK: - Page Range Tests
    
    func testParsePageRange_single() {
        let pages = parsePageRange("5", totalPages: 10)
        XCTAssertNotNil(pages)
        XCTAssertEqual(pages!.count, 1)
        XCTAssertEqual(pages![0], 5)
    }
    
    func testParsePageRange_range() {
        let pages = parsePageRange("1-3", totalPages: 10)
        XCTAssertNotNil(pages)
        XCTAssertEqual(pages!.count, 3)
        XCTAssertEqual(pages!, [1, 2, 3])
    }
    
    func testParsePageRange_commaSeparated() {
        let pages = parsePageRange("1,3,5", totalPages: 10)
        XCTAssertNotNil(pages)
        XCTAssertEqual(pages!.count, 3)
        XCTAssertEqual(pages!, [1, 3, 5])
    }
    
    func testParsePageRange_complex() {
        let pages = parsePageRange("1-3,5,7-9", totalPages: 10)
        XCTAssertNotNil(pages)
        XCTAssertEqual(pages!.count, 7)
        XCTAssertEqual(pages!, [1, 2, 3, 5, 7, 8, 9])
    }
    
    func testParsePageRange_outOfBounds() {
        let pages = parsePageRange("8-12", totalPages: 10)
        XCTAssertNotNil(pages)
        XCTAssertEqual(pages!, [8, 9, 10]) // Should cap at totalPages
    }
    
    func testParsePageRange_invalid() {
        XCTAssertNil(parsePageRange("0", totalPages: 10)) // Page 0 invalid
        XCTAssertNil(parsePageRange("abc", totalPages: 10))
        XCTAssertNil(parsePageRange("5-3", totalPages: 10)) // Invalid range
    }
    
    // MARK: - Text Slugification Tests
    
    func testSlugifyText() {
        XCTAssertEqual(slugifyText("Hello World!", maxLength: 30), "hello-world")
        XCTAssertEqual(slugifyText("Test@#$123", maxLength: 30), "test123")
        XCTAssertEqual(slugifyText("   Multiple   Spaces   ", maxLength: 30), "multiple-spaces")
    }
    
    func testSlugifyText_truncation() {
        let longText = "This is a very long text that should be truncated"
        let slug = slugifyText(longText, maxLength: 20)
        XCTAssertEqual(slug.count, 20)
        XCTAssertTrue(slug.hasPrefix("this-is-a-very-long"))
    }
    
    // MARK: - Filename Pattern Tests
    
    func testFormatFilenameWithPattern_default() {
        let filename = formatFilenameWithPattern(
            pattern: nil,
            basename: "document",
            pageNum: 5,
            totalPages: 100,
            extractedText: nil
        )
        XCTAssertEqual(filename, "document-005")
    }
    
    func testFormatFilenameWithPattern_custom() {
        let filename = formatFilenameWithPattern(
            pattern: "{basename}_page_{page:04d}_of_{total}",
            basename: "myfile",
            pageNum: 3,
            totalPages: 10,
            extractedText: nil
        )
        XCTAssertEqual(filename, "myfile_page_0003_of_10")
    }
    
    func testFormatFilenameWithPattern_withText() {
        let filename = formatFilenameWithPattern(
            pattern: "{basename}_{page}_{text}",
            basename: "doc",
            pageNum: 1,
            totalPages: 5,
            extractedText: "introduction"
        )
        XCTAssertTrue(filename.contains("introduction"))
    }
    
    // MARK: - File Operations Tests
    
    func testFileExists() {
        // Test with non-existent file
        XCTAssertFalse(fileExists("/path/that/does/not/exist"))
        
        // Test with temp file
        let tempPath = NSTemporaryDirectory().appending("test_file.txt")
        try? "test".write(toFile: tempPath, atomically: true, encoding: .utf8)
        XCTAssertTrue(fileExists(tempPath))
        try? FileManager.default.removeItem(atPath: tempPath)
    }
    
    func testShouldOverwriteFile_nonExistent() {
        XCTAssertTrue(shouldOverwriteFile(path: "/path/that/does/not/exist", interactive: false))
        XCTAssertTrue(shouldOverwriteFile(path: "/path/that/does/not/exist", interactive: true))
    }
    
    func testShouldOverwriteFile_existing() {
        let tempPath = NSTemporaryDirectory().appending("test_file2.txt")
        try? "test".write(toFile: tempPath, atomically: true, encoding: .utf8)
        
        // Non-interactive mode should not overwrite
        XCTAssertFalse(shouldOverwriteFile(path: tempPath, interactive: false))
        
        try? FileManager.default.removeItem(atPath: tempPath)
    }
    
    // MARK: - Scale Factor Calculation Tests
    
    func testCalculateScaleFactor_dpi() {
        var scale = ScaleSpecification()
        scale.isDPI = true
        scale.dpi = 300
        
        let factor = calculateScaleFactor(scale: scale, pageRect: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(factor, 300.0 / 72.0, accuracy: 0.001)
    }
    
    func testCalculateScaleFactor_fitWidth() {
        var scale = ScaleSpecification()
        scale.hasWidth = true
        scale.maxWidth = 800
        
        let factor = calculateScaleFactor(scale: scale, pageRect: CGRect(x: 0, y: 0, width: 400, height: 600))
        XCTAssertEqual(factor, 2.0, accuracy: 0.001)
    }
    
    func testCalculateScaleFactor_fitHeight() {
        var scale = ScaleSpecification()
        scale.hasHeight = true
        scale.maxHeight = 600
        
        let factor = calculateScaleFactor(scale: scale, pageRect: CGRect(x: 0, y: 0, width: 400, height: 300))
        XCTAssertEqual(factor, 2.0, accuracy: 0.001)
    }
    
    func testCalculateScaleFactor_fitBoth() {
        var scale = ScaleSpecification()
        scale.hasWidth = true
        scale.hasHeight = true
        scale.maxWidth = 800
        scale.maxHeight = 600
        
        // Should use smaller scale to fit within bounds
        let factor = calculateScaleFactor(scale: scale, pageRect: CGRect(x: 0, y: 0, width: 400, height: 400))
        XCTAssertEqual(factor, 1.5, accuracy: 0.001) // Limited by height
    }
}