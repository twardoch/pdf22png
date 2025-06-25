import Foundation

// MARK: - Result Types

struct ProcessingResults {
    let totalPages: Int
    let successfulPages: Int
    let failedPages: Int
    let interrupted: Bool
    let processingTime: TimeInterval
    let outputFiles: [String]
    
    var successRate: Double {
        guard totalPages > 0 else { return 0.0 }
        return Double(successfulPages) / Double(totalPages)
    }
    
    var pagesPerSecond: Double {
        guard processingTime > 0 else { return 0.0 }
        return Double(successfulPages) / processingTime
    }
    
    var isSuccessful: Bool {
        return failedPages == 0 && !interrupted
    }
}

struct PageResult {
    let pageNumber: Int
    let success: Bool
    let outputFile: String?
    let processingTime: TimeInterval
    let errorMessage: String?
    
    init(pageNumber: Int, success: Bool, outputFile: String? = nil, processingTime: TimeInterval = 0, error: Error? = nil) {
        self.pageNumber = pageNumber
        self.success = success
        self.outputFile = outputFile
        self.processingTime = processingTime
        self.errorMessage = error?.localizedDescription
    }
}

struct BatchResult {
    let totalPages: Int
    let successfulPages: Int
    let failedPages: Int
    let interrupted: Bool
    let processingTime: TimeInterval
    let pageResults: [PageResult]
    
    var processingResults: ProcessingResults {
        let outputFiles = pageResults.compactMap { $0.outputFile }
        return ProcessingResults(
            totalPages: totalPages,
            successfulPages: successfulPages,
            failedPages: failedPages,
            interrupted: interrupted,
            processingTime: processingTime,
            outputFiles: outputFiles
        )
    }
    
    init(totalPages: Int, successfulPages: Int, failedPages: Int, interrupted: Bool, processingTime: TimeInterval = 0, pageResults: [PageResult] = []) {
        self.totalPages = totalPages
        self.successfulPages = successfulPages
        self.failedPages = failedPages
        self.interrupted = interrupted
        self.processingTime = processingTime
        self.pageResults = pageResults
    }
}