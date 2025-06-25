import Foundation
import CoreGraphics
import PDFKit
import UniformTypeIdentifiers

// MARK: - PDF Processing

class PDFProcessor {
    static let shared = PDFProcessor()
    private init() {}
    
    func readPDFData(_ inputPath: String?, verbose: Bool) -> Data? {
        if let path = inputPath, path != "-" {
            logMessage(verbose, "Reading PDF from file: \(path)")
            return FileManager.default.contents(atPath: path)
        } else {
            logMessage(verbose, "Reading PDF from stdin")
            let stdin = FileHandle.standardInput
            return stdin.readDataToEndOfFile()
        }
    }
    
    func createPDFDocument(from data: Data) -> PDFDocument? {
        return PDFDocument(data: data)
    }
    
    func validatePDF(_ document: PDFDocument) -> Bool {
        return document.pageCount > 0
    }
    
    func getPageCount(_ document: PDFDocument) -> Int {
        return document.pageCount
    }
    
    func extractPage(_ document: PDFDocument, pageNumber: Int) -> PDFPage? {
        guard pageNumber > 0 && pageNumber <= document.pageCount else {
            return nil
        }
        return document.page(at: pageNumber - 1) // Convert to 0-based index
    }
}