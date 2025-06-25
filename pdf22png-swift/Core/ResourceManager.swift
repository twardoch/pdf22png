import Foundation

// MARK: - Resource Management System

class ResourceManager {
    static let shared = ResourceManager()
    private init() {}
    
    private var tempFiles: Set<String> = []
    private var fileHandles: Set<ObjectIdentifier> = []
    private let resourceQueue = DispatchQueue(label: "resource.management", qos: .utility)
    
    func registerTempFile(_ path: String) {
        resourceQueue.sync {
            _ = tempFiles.insert(path)
        }
    }
    
    func unregisterTempFile(_ path: String) {
        resourceQueue.sync {
            _ = tempFiles.remove(path)
        }
    }
    
    func registerFileHandle(_ handle: FileHandle) {
        resourceQueue.sync {
            _ = fileHandles.insert(ObjectIdentifier(handle))
        }
    }
    
    func unregisterFileHandle(_ handle: FileHandle) {
        resourceQueue.sync {
            _ = fileHandles.remove(ObjectIdentifier(handle))
        }
    }
    
    func cleanupAllResources() {
        resourceQueue.sync {
            // Clean up temporary files
            for tempFile in tempFiles {
                do {
                    if FileManager.default.fileExists(atPath: tempFile) {
                        try FileManager.default.removeItem(atPath: tempFile)
                    }
                } catch {
                    // Ignore cleanup errors
                }
            }
            tempFiles.removeAll()
            
            // Clear file handle tracking
            fileHandles.removeAll()
        }
    }
    
    func createSecureTempFile(prefix: String = "pdf22png", suffix: String = ".tmp") -> String? {
        let tempDir = NSTemporaryDirectory()
        let tempFileName = "\(prefix)_\(UUID().uuidString)\(suffix)"
        let tempPath = (tempDir as NSString).appendingPathComponent(tempFileName)
        
        // Create the file with secure permissions (600)
        let success = FileManager.default.createFile(atPath: tempPath, contents: nil, attributes: [
            .posixPermissions: 0o600
        ])
        
        if success {
            registerTempFile(tempPath)
            return tempPath
        }
        
        return nil
    }
}