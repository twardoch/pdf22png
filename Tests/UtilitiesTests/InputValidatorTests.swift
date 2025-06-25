import Foundation
import XCTest
@testable import pdf22png

/// Unit tests for InputValidator module
final class InputValidatorTests: XCTestCase {
    
    // MARK: - File Path Validation Tests
    
    func testValidateFilePathValid() {
        let validPath = "/tmp/test.pdf"
        
        do {
            let result = try InputValidator.validateFilePath(validPath, allowCreate: true)
            XCTAssertEqual(result, validPath, "Should return normalized path")
        } catch {
            XCTFail("Should not throw error for valid path: \(error)")
        }
    }
    
    func testValidateFilePathTooLong() {
        let longPath = String(repeating: "a", count: InputValidator.maxPathLength + 1)
        
        do {
            _ = try InputValidator.validateFilePath(longPath, allowCreate: true)
            XCTFail("Should throw error for path too long")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidateFilePathWithPathTraversal() {
        let maliciousPath = "../../../etc/passwd"
        
        do {
            _ = try InputValidator.validateFilePath(maliciousPath, allowCreate: true)
            XCTFail("Should throw error for path traversal attempt")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidateFilePathWithNullByte() {
        let maliciousPath = "/tmp/test\0.pdf"
        
        do {
            _ = try InputValidator.validateFilePath(maliciousPath, allowCreate: true)
            XCTFail("Should throw error for null byte in path")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidateFilePathWithNewline() {
        let maliciousPath = "/tmp/test\n.pdf"
        
        do {
            _ = try InputValidator.validateFilePath(maliciousPath, allowCreate: true)
            XCTFail("Should throw error for newline in path")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    // MARK: - Output Directory Validation Tests
    
    func testValidateOutputDirectoryValid() {
        let validDir = "/tmp"
        
        do {
            let result = try InputValidator.validateOutputDirectory(validDir)
            XCTAssertEqual(result, validDir, "Should return normalized directory path")
        } catch {
            XCTFail("Should not throw error for valid directory: \(error)")
        }
    }
    
    func testValidateOutputDirectoryNonExistent() {
        let nonExistentDir = "/non/existent/directory"
        
        do {
            _ = try InputValidator.validateOutputDirectory(nonExistentDir)
            XCTFail("Should throw error for non-existent directory")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    // MARK: - Page Number Validation Tests
    
    func testValidatePageNumberValid() {
        let validPage = 5
        let totalPages = 10
        
        do {
            try InputValidator.validatePageNumber(validPage, totalPages: totalPages)
            XCTAssertTrue(true, "Should not throw error for valid page number")
        } catch {
            XCTFail("Should not throw error for valid page number: \(error)")
        }
    }
    
    func testValidatePageNumberTooLow() {
        let invalidPage = 0
        let totalPages = 10
        
        do {
            try InputValidator.validatePageNumber(invalidPage, totalPages: totalPages)
            XCTFail("Should throw error for page number too low")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidatePageNumberTooHigh() {
        let invalidPage = 15
        let totalPages = 10
        
        do {
            try InputValidator.validatePageNumber(invalidPage, totalPages: totalPages)
            XCTFail("Should throw error for page number too high")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidatePageNumberExceedsMaximum() {
        let invalidPage = InputValidator.maxPageNumber + 1
        let totalPages = InputValidator.maxPageNumber + 10
        
        do {
            try InputValidator.validatePageNumber(invalidPage, totalPages: totalPages)
            XCTFail("Should throw error for page number exceeding maximum")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    // MARK: - Page Range Validation Tests
    
    func testValidatePageRangeValid() {
        let validRange = "1,3,5-10"
        let totalPages = 15
        
        do {
            try InputValidator.validatePageRange(validRange, totalPages: totalPages)
            XCTAssertTrue(true, "Should not throw error for valid page range")
        } catch {
            XCTFail("Should not throw error for valid page range: \(error)")
        }
    }
    
    func testValidatePageRangeInvalidCharacters() {
        let invalidRange = "1,3,5-10a"
        let totalPages = 15
        
        do {
            try InputValidator.validatePageRange(invalidRange, totalPages: totalPages)
            XCTFail("Should throw error for invalid characters in range")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidatePageRangePageOutOfBounds() {
        let invalidRange = "1,3,20"
        let totalPages = 15
        
        do {
            try InputValidator.validatePageRange(invalidRange, totalPages: totalPages)
            XCTFail("Should throw error for page out of bounds")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    // MARK: - Scale Validation Tests
    
    func testValidateScaleValid() {
        let validScales = ["100%", "1.5", "800x600", "300dpi"]
        
        for scale in validScales {
            do {
                try InputValidator.validateScale(scale)
                XCTAssertTrue(true, "Should not throw error for valid scale: \(scale)")
            } catch {
                XCTFail("Should not throw error for valid scale \(scale): \(error)")
            }
        }
    }
    
    func testValidateScaleTooLong() {
        let longScale = String(repeating: "1", count: 25)
        
        do {
            try InputValidator.validateScale(longScale)
            XCTFail("Should throw error for scale too long")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidateScaleInvalidCharacters() {
        let invalidScale = "100%$"
        
        do {
            try InputValidator.validateScale(invalidScale)
            XCTFail("Should throw error for invalid characters in scale")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    // MARK: - Quality Validation Tests
    
    func testValidateQualityValid() {
        for quality in 0...9 {
            do {
                try InputValidator.validateQuality(quality)
                XCTAssertTrue(true, "Should not throw error for valid quality: \(quality)")
            } catch {
                XCTFail("Should not throw error for valid quality \(quality): \(error)")
            }
        }
    }
    
    func testValidateQualityTooLow() {
        let invalidQuality = -1
        
        do {
            try InputValidator.validateQuality(invalidQuality)
            XCTFail("Should throw error for quality too low")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidateQualityTooHigh() {
        let invalidQuality = 10
        
        do {
            try InputValidator.validateQuality(invalidQuality)
            XCTFail("Should throw error for quality too high")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    // MARK: - Naming Pattern Validation Tests
    
    func testValidateNamingPatternValid() {
        let validPattern = "{basename}_p{page:04d}_of_{total}"
        
        do {
            try InputValidator.validateNamingPattern(validPattern)
            XCTAssertTrue(true, "Should not throw error for valid naming pattern")
        } catch {
            XCTFail("Should not throw error for valid naming pattern: \(error)")
        }
    }
    
    func testValidateNamingPatternTooLong() {
        let longPattern = String(repeating: "a", count: 250)
        
        do {
            try InputValidator.validateNamingPattern(longPattern)
            XCTFail("Should throw error for pattern too long")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
    
    func testValidateNamingPatternWithPathTraversal() {
        let maliciousPattern = "../{basename}"
        
        do {
            try InputValidator.validateNamingPattern(maliciousPattern)
            XCTFail("Should throw error for path traversal in pattern")
        } catch {
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError")
        }
    }
}

// MARK: - Test Extensions

extension InputValidatorTests {
    
    /// Helper method to create temporary file for testing
    private func createTemporaryFile() -> String? {
        let tempDir = NSTemporaryDirectory()
        let tempFile = "\(tempDir)/test_\(UUID().uuidString).pdf"
        
        if FileManager.default.createFile(atPath: tempFile, contents: Data(), attributes: nil) {
            return tempFile
        }
        return nil
    }
    
    /// Helper method to clean up temporary file
    private func cleanupTemporaryFile(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}