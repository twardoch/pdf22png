#ifndef PDF22PNG_ERRORS_H
#define PDF22PNG_ERRORS_H

// Error codes for pdf22png
typedef enum {
    PDF22PNG_SUCCESS = 0,
    PDF22PNG_ERROR_GENERAL = 1,
    PDF22PNG_ERROR_INVALID_ARGS = 2,
    PDF22PNG_ERROR_FILE_NOT_FOUND = 3,
    PDF22PNG_ERROR_FILE_READ = 4,
    PDF22PNG_ERROR_FILE_WRITE = 5,
    PDF22PNG_ERROR_NO_INPUT = 6,
    PDF22PNG_ERROR_INVALID_PDF = 7,
    PDF22PNG_ERROR_ENCRYPTED_PDF = 8,
    PDF22PNG_ERROR_EMPTY_PDF = 9,
    PDF22PNG_ERROR_PAGE_NOT_FOUND = 10,
    PDF22PNG_ERROR_RENDER_FAILED = 11,
    PDF22PNG_ERROR_MEMORY = 12,
    PDF22PNG_ERROR_OUTPUT_DIR = 13,
    PDF22PNG_ERROR_INVALID_SCALE = 14,
    PDF22PNG_ERROR_BATCH_FAILED = 15
} PDF22PNGError;

// Error messages
static const char* PDF22PNG_ERROR_MESSAGES[] = {
    "Success",
    "General error",
    "Invalid command line arguments",
    "Input file not found",
    "Failed to read input file",
    "Failed to write output file",
    "No input data received",
    "Invalid PDF document",
    "PDF document is encrypted (password-protected PDFs not supported)",
    "PDF document has no pages",
    "Requested page does not exist",
    "Failed to render PDF page",
    "Memory allocation failed",
    "Failed to create output directory",
    "Invalid scale specification",
    "Batch processing failed"
};

// Function to get error message
static inline const char* pdf22png_error_string(PDF22PNGError error) {
    if (error >= 0 && error <= PDF22PNG_ERROR_BATCH_FAILED) {
        return PDF22PNG_ERROR_MESSAGES[error];
    }
    return "Unknown error";
}

// Macro for error reporting with file and line info
#define PDF22PNG_ERROR(code, ...) do { \
    fprintf(stderr, "Error: %s\n", pdf22png_error_string(code)); \
    if (##__VA_ARGS__) { \
        fprintf(stderr, "Details: "); \
        fprintf(stderr, ##__VA_ARGS__); \
        fprintf(stderr, "\n"); \
    } \
} while(0)

#endif // PDF22PNG_ERRORS_H