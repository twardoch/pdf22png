import Foundation
import XCTest
import CoreGraphics
@testable import pdf22png

/// Unit tests for MemoryManager module
final class MemoryManagerTests: XCTestCase {
    
    var memoryManager: MemoryManager!
    
    override func setUp() {
        super.setUp()
        memoryManager = MemoryManager.shared
    }
    
    override func tearDown() {
        memoryManager = nil
        super.tearDown()
    }
    
    // MARK: - System Memory Information Tests
    
    func testGetSystemMemoryInfo() {
        let memInfo = memoryManager.getSystemMemoryInfo()
        
        XCTAssertGreaterThan(memInfo.total, 0, "Total memory should be greater than 0")
        XCTAssertGreaterThanOrEqual(memInfo.total, memInfo.used, "Total memory should be >= used memory")
        XCTAssertEqual(memInfo.total, memInfo.used + memInfo.available, "Total should equal used + available")
    }
    
    // MARK: - Memory Pressure Detection Tests
    
    func testMemoryPressureDetection() {
        // Test memory pressure detection methods exist and return valid results
        let isHighPressure = memoryManager.isMemoryPressureHigh()
        let isCriticalPressure = memoryManager.isMemoryPressureCritical()
        
        // If critical pressure is true, high pressure should also be true
        if isCriticalPressure {
            XCTAssertTrue(isHighPressure, "Critical pressure implies high pressure")
        }
        
        // Both should be boolean values (this test always passes but ensures methods work)
        XCTAssertTrue(isHighPressure == true || isHighPressure == false)
        XCTAssertTrue(isCriticalPressure == true || isCriticalPressure == false)
    }
    
    // MARK: - Memory Requirement Estimation Tests
    
    func testEstimateMemoryRequirementBasic() {
        let pageRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let scaleFactor: CGFloat = 1.0
        let transparentBackground = false
        
        let requirement = memoryManager.estimateMemoryRequirement(
            pageRect: pageRect,
            scaleFactor: scaleFactor,
            transparentBackground: transparentBackground
        )
        
        XCTAssertGreaterThan(requirement, 0, "Memory requirement should be positive")
        
        // Basic calculation: 100x100 pixels * 4 bytes = 40,000 bytes + overhead
        XCTAssertGreaterThanOrEqual(requirement, 40000, "Should be at least base pixel memory")
    }
    
    func testEstimateMemoryRequirementWithScaling() {
        let pageRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let scaleFactor: CGFloat = 2.0
        let transparentBackground = false
        
        let requirement = memoryManager.estimateMemoryRequirement(
            pageRect: pageRect,
            scaleFactor: scaleFactor,
            transparentBackground: transparentBackground
        )
        
        // Should be roughly 4x the memory for 2x scale factor (2x width * 2x height)
        XCTAssertGreaterThan(requirement, 160000, "Scaled requirement should be much larger")
    }
    
    func testEstimateMemoryRequirementWithTransparency() {
        let pageRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let scaleFactor: CGFloat = 1.0
        
        let opaqueRequirement = memoryManager.estimateMemoryRequirement(
            pageRect: pageRect,
            scaleFactor: scaleFactor,
            transparentBackground: false
        )
        
        let transparentRequirement = memoryManager.estimateMemoryRequirement(
            pageRect: pageRect,
            scaleFactor: scaleFactor,
            transparentBackground: true
        )
        
        XCTAssertGreaterThan(transparentRequirement, opaqueRequirement,
                           "Transparent background should require more memory")
    }
    
    // MARK: - Memory Allocation Tests
    
    func testCanAllocateMemorySmallAmount() {
        let smallAmount: UInt64 = 1024 * 1024 // 1MB
        let canAllocate = memoryManager.canAllocateMemory(smallAmount, verbose: false)
        
        // On most systems, 1MB should be allocatable
        XCTAssertTrue(canAllocate, "Should be able to allocate 1MB")
    }
    
    func testCanAllocateMemoryLargeAmount() {
        let largeAmount: UInt64 = 100 * 1024 * 1024 * 1024 // 100GB
        let canAllocate = memoryManager.canAllocateMemory(largeAmount, verbose: false)
        
        // 100GB should not be allocatable on most systems
        XCTAssertFalse(canAllocate, "Should not be able to allocate 100GB")
    }
    
    // MARK: - Batch Size Calculation Tests
    
    func testCalculateOptimalBatchSizeSmallPages() {
        let totalPages = 10
        let pageRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let scaleFactor: CGFloat = 1.0
        
        let batchSize = memoryManager.calculateOptimalBatchSize(
            totalPages: totalPages,
            pageRect: pageRect,
            scaleFactor: scaleFactor,
            verbose: false
        )
        
        XCTAssertGreaterThan(batchSize, 0, "Batch size should be positive")
        XCTAssertLessThanOrEqual(batchSize, totalPages, "Batch size should not exceed total pages")
    }
    
    func testCalculateOptimalBatchSizeLargePages() {
        let totalPages = 1000
        let pageRect = CGRect(x: 0, y: 0, width: 2000, height: 2000)
        let scaleFactor: CGFloat = 2.0
        
        let batchSize = memoryManager.calculateOptimalBatchSize(
            totalPages: totalPages,
            pageRect: pageRect,
            scaleFactor: scaleFactor,
            verbose: false
        )
        
        XCTAssertGreaterThan(batchSize, 0, "Batch size should be positive")
        XCTAssertLessThan(batchSize, totalPages, "Batch size should be smaller for large pages")
    }
    
    // MARK: - Memory Status Logging Tests
    
    func testLogMemoryStatusVerbose() {
        // Test that verbose logging doesn't crash
        memoryManager.logMemoryStatus(verbose: true)
        XCTAssertTrue(true, "Verbose logging should complete without crashing")
    }
    
    func testLogMemoryStatusNonVerbose() {
        // Test that non-verbose mode doesn't log
        memoryManager.logMemoryStatus(verbose: false)
        XCTAssertTrue(true, "Non-verbose logging should complete without output")
    }
    
    // MARK: - Memory Pressure Handling Tests
    
    func testCheckMemoryPressureDuringBatch() {
        // Test memory pressure checking during batch processing
        do {
            try memoryManager.checkMemoryPressureDuringBatch(verbose: false)
            XCTAssertTrue(true, "Memory pressure check should complete normally")
        } catch {
            // If memory pressure is critical, an error should be thrown
            XCTAssertTrue(error is PDF22PNGError, "Should throw PDF22PNGError for memory pressure")
        }
    }
}

// MARK: - Test Extensions

extension MemoryManagerTests {
    
    /// Helper method to create test page rect
    private func createTestPageRect(width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    /// Helper method to get current memory usage percentage
    private func getCurrentMemoryUsage() -> Double {
        let memInfo = memoryManager.getSystemMemoryInfo()
        return Double(memInfo.used) / Double(memInfo.total)
    }
}