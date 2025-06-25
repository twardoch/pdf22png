import Foundation
import Darwin.Mach

// MARK: - Memory Management System

class MemoryManager {
    static let shared = MemoryManager()
    private init() {}
    
    // System memory thresholds (in bytes)
    private let lowMemoryThreshold: UInt64 = 512 * 1024 * 1024    // 512MB
    private let criticalMemoryThreshold: UInt64 = 256 * 1024 * 1024 // 256MB
    private let maxMemoryUsage: UInt64 = 2 * 1024 * 1024 * 1024    // 2GB
    
    func getSystemMemoryInfo() -> (total: UInt64, available: UInt64, used: UInt64) {
        var size = MemoryLayout<vm_size_t>.size
        var physicalMemory: vm_size_t = 0
        sysctlbyname("hw.memsize", &physicalMemory, &size, nil, 0)
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        let used = UInt64(kr == KERN_SUCCESS ? info.resident_size : 0)
        let total = UInt64(physicalMemory)
        let available = total > used ? total - used : 0
        
        return (total: total, available: available, used: used)
    }
    
    func isMemoryPressureHigh() -> Bool {
        let memInfo = getSystemMemoryInfo()
        return memInfo.available < lowMemoryThreshold
    }
    
    func isMemoryPressureCritical() -> Bool {
        let memInfo = getSystemMemoryInfo()
        return memInfo.available < criticalMemoryThreshold
    }
    
    func estimateMemoryRequirement(pageRect: CGRect, scaleFactor: CGFloat, transparentBackground: Bool) -> UInt64 {
        let scaledWidth = pageRect.width * scaleFactor
        let scaledHeight = pageRect.height * scaleFactor
        let pixelCount = scaledWidth * scaledHeight
        
        // 4 bytes per pixel (RGBA), plus overhead
        let baseMemory = UInt64(pixelCount * 4)
        
        // Add overhead for Core Graphics contexts and intermediate buffers
        let overhead = baseMemory / 4
        
        // Transparent backgrounds require more memory
        let transparencyMultiplier: CGFloat = transparentBackground ? 1.5 : 1.0
        
        return UInt64(CGFloat(baseMemory + overhead) * transparencyMultiplier)
    }
    
    func canAllocateMemory(_ requiredMemory: UInt64, verbose: Bool) -> Bool {
        let memInfo = getSystemMemoryInfo()
        let canAllocate = memInfo.available > requiredMemory + criticalMemoryThreshold
        
        if verbose {
            let availableMB = memInfo.available / (1024 * 1024)
            let requiredMB = requiredMemory / (1024 * 1024)
            logMessage(true, "Memory check: Available \(availableMB)MB, Required \(requiredMB)MB")
        }
        
        return canAllocate
    }
    
    func calculateOptimalBatchSize(totalPages: Int, pageRect: CGRect, scaleFactor: CGFloat, verbose: Bool) -> Int {
        let memoryPerPage = estimateMemoryRequirement(pageRect: pageRect, scaleFactor: scaleFactor, transparentBackground: false)
        let memInfo = getSystemMemoryInfo()
        let availableForBatch = memInfo.available / 2 // Use only half of available memory
        
        let optimalBatchSize = max(1, min(totalPages, Int(availableForBatch / memoryPerPage)))
        
        if verbose {
            let batchMemoryMB = (UInt64(optimalBatchSize) * memoryPerPage) / (1024 * 1024)
            logMessage(true, "Optimal batch size: \(optimalBatchSize) pages (\(batchMemoryMB)MB estimated)")
        }
        
        return optimalBatchSize
    }
    
    func logMemoryStatus(verbose: Bool) {
        if !verbose { return }
        
        let memInfo = getSystemMemoryInfo()
        let totalMB = memInfo.total / (1024 * 1024)
        let availableMB = memInfo.available / (1024 * 1024)
        let usedMB = memInfo.used / (1024 * 1024)
        let usagePercent = totalMB > 0 ? (usedMB * 100) / totalMB : 0
        
        logMessage(true, "Memory status: \(usedMB)MB/\(totalMB)MB used (\(usagePercent)%), \(availableMB)MB available")
        
        if isMemoryPressureCritical() {
            logMessage(true, "⚠️  Critical memory pressure detected!")
        } else if isMemoryPressureHigh() {
            logMessage(true, "⚠️  High memory pressure detected")
        }
    }
}

// Helper function for logging (to be defined elsewhere)
func logMessage(_ verbose: Bool, _ message: String) {
    if verbose {
        fputs("[\(DateFormatter.logFormat.string(from: Date()))] \(message)\n", stderr)
    }
}

extension DateFormatter {
    static let logFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}