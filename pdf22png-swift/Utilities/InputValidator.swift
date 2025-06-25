import Foundation

// MARK: - Input Validation

class InputValidator {
    static let maxFileSize: UInt64 = 500 * 1024 * 1024 // 500MB
    static let maxPageNumber: Int = 10000
    static let maxTotalPages: Int = 5000
    static let maxPathLength: Int = 1024
    
    static func validateFilePath(_ path: String, allowCreate: Bool = false) throws -> String {
        // Check path length
        guard path.count <= maxPathLength else {
            throw PDF22PNGError.invalidArgs
        }
        
        // Prevent path traversal attacks
        let normalizedPath = (path as NSString).standardizingPath
        guard !normalizedPath.contains("../") && !normalizedPath.contains("..\\") else {
            throw PDF22PNGError.invalidArgs
        }
        
        // Check for null bytes and other dangerous characters
        guard !path.contains("\0") && !path.contains("\n") && !path.contains("\r") else {
            throw PDF22PNGError.invalidArgs
        }
        
        if !allowCreate {
            // For input files, check existence and size
            guard FileManager.default.fileExists(atPath: normalizedPath) else {
                throw PDF22PNGError.fileNotFound
            }
            
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: normalizedPath)
                if let fileSize = attributes[.size] as? UInt64, fileSize > maxFileSize {
                    throw PDF22PNGError.invalidArgs
                }
            } catch {
                throw PDF22PNGError.fileRead
            }
        }
        
        return normalizedPath
    }
    
    static func validateOutputDirectory(_ path: String) throws -> String {
        let normalizedPath = try validateFilePath(path, allowCreate: true)
        
        // Check if parent directory exists and is writable
        let parentDir = (normalizedPath as NSString).deletingLastPathComponent
        guard FileManager.default.fileExists(atPath: parentDir) else {
            throw PDF22PNGError.outputDir
        }
        
        guard FileManager.default.isWritableFile(atPath: parentDir) else {
            throw PDF22PNGError.fileWrite
        }
        
        return normalizedPath
    }
    
    static func validatePageNumber(_ page: Int, totalPages: Int) throws {
        guard page >= 1 && page <= totalPages else {
            throw PDF22PNGError.pageNotFound
        }
        
        guard page <= maxPageNumber else {
            throw PDF22PNGError.invalidArgs
        }
    }
    
    static func validatePageRange(_ range: String, totalPages: Int) throws {
        // Basic validation of page range format
        let validChars = CharacterSet(charactersIn: "0123456789,-")
        guard range.rangeOfCharacter(from: validChars.inverted) == nil else {
            throw PDF22PNGError.invalidArgs
        }
        
        // Check for reasonable range limits
        let components = range.components(separatedBy: CharacterSet(charactersIn: ",-"))
        for component in components {
            if let pageNum = Int(component.trimmingCharacters(in: .whitespaces)) {
                try validatePageNumber(pageNum, totalPages: totalPages)
            }
        }
    }
    
    static func validateScale(_ scale: String) throws {
        guard scale.count <= 20 else { // Reasonable limit for scale specification
            throw PDF22PNGError.invalidScale
        }
        
        // Check for basic format validity
        let validChars = CharacterSet(charactersIn: "0123456789.%xdpi")
        guard scale.rangeOfCharacter(from: validChars.inverted) == nil else {
            throw PDF22PNGError.invalidScale
        }
    }
    
    static func validateQuality(_ quality: Int) throws {
        guard quality >= 0 && quality <= 9 else {
            throw PDF22PNGError.invalidArgs
        }
    }
    
    static func validateNamingPattern(_ pattern: String) throws {
        guard pattern.count <= 200 else { // Reasonable pattern length
            throw PDF22PNGError.invalidArgs
        }
        
        // Check for potentially dangerous pattern elements
        guard !pattern.contains("../") && !pattern.contains("..\\") && !pattern.contains("\0") else {
            throw PDF22PNGError.invalidArgs
        }
    }
}