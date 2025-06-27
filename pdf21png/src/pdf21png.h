#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import <ImageIO/ImageIO.h>
#import "errors.h"

// Structures from pdf21png.m
typedef struct {
    CGFloat scaleFactor;
    CGFloat maxWidth;
    CGFloat maxHeight;
    CGFloat dpi;
    BOOL isPercentage;
    BOOL isDPI;
    BOOL hasWidth;
    BOOL hasHeight;
} ScaleSpec;

typedef struct {
    ScaleSpec scale;
    NSInteger pageNumber;
    NSString *inputPath;
    NSString *outputPath;
    NSString *outputDirectory;
    BOOL batchMode;
    // Recommended additions for new features from README
    BOOL transparentBackground;
    int pngQuality; // 0-9
    BOOL verbose;
    BOOL includeText; // Include extracted text in filename
    NSString *pageRange; // Page range specification (e.g., "1-5,10,15-20")
    BOOL dryRun; // Preview operations without writing files
    NSString *namingPattern; // Custom naming pattern with placeholders
    BOOL forceOverwrite; // Force overwrite without prompting
} Options;

// Function prototypes from pdf21png.m that should remain in main logic
void printUsage(const char *programName);
Options parseArguments(int argc, const char *argv[]);
BOOL processSinglePage(CGPDFDocumentRef pdfDocument, Options *options);
BOOL processBatchMode(CGPDFDocumentRef pdfDocument, Options *options);

// Potentially new functions based on README advanced options
// These would be implemented in pdf21png.m
// void handleTransparency(CGContextRef context, Options* options); // Example if needed
// void setPNGCompression(CGImageDestinationRef dest, Options* options); // Example if needed

// Main function declaration (though it's standard)
int main(int argc, const char *argv[]);
