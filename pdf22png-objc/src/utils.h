#ifndef UTILS_H
#define UTILS_H

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "pdf22png.h" // For ScaleSpec and Options structs
#import "errors.h" // For error codes and handling

// Function prototypes for utility functions
BOOL parseScaleSpec(const char *spec, ScaleSpec *scale);
NSData *readDataFromStdin(void);
NSData *readPDFData(NSString *inputPath, BOOL verbose); // Added verbose
CGFloat calculateScaleFactor(ScaleSpec *scale, CGRect pageRect);
CGImageRef renderPDFPageToImage(CGPDFPageRef pdfPage, CGFloat scaleFactor, BOOL transparentBackground, BOOL verbose); // Added transparentBackground and verbose
CGImageRef renderPDFPageToImageOptimized(CGPDFPageRef pdfPage, CGFloat scaleFactor, BOOL transparentBackground, BOOL verbose, CGColorSpaceRef colorSpace); // Optimized version with shared color space
BOOL writeImageAsPNG(CGImageRef image, NSFileHandle *output, int pngQuality, BOOL verbose); // Added pngQuality and verbose
BOOL writeImageToFile(CGImageRef image, NSString *outputPath, int pngQuality, BOOL verbose, BOOL dryRun, BOOL forceOverwrite); // Added pngQuality, verbose, dryRun and forceOverwrite
NSString *getOutputPrefix(Options *options);
void logMessage(BOOL verbose, NSString *format, ...);

// Text extraction and processing
NSString *extractTextFromPDFPage(CGPDFPageRef page);
NSString *performOCROnImage(CGImageRef image);
NSString *slugifyText(NSString *text, NSUInteger maxLength);

// Page range parsing
NSArray<NSNumber *> *parsePageRange(NSString *rangeSpec, NSUInteger totalPages);

// Naming pattern processing
NSString *formatFilenameWithPattern(NSString *pattern, NSString *basename, NSUInteger pageNum, 
                                   NSUInteger totalPages, NSString *extractedText);

// File overwrite protection
BOOL fileExists(NSString *path);
BOOL shouldOverwriteFile(NSString *path, BOOL interactive);
BOOL promptUserForOverwrite(NSString *path);

// Enhanced error reporting
void reportError(NSString *message, NSString *troubleshootingHint);
void reportWarning(NSString *message, NSString *troubleshootingHint);
NSString *getTroubleshootingHint(NSString *errorContext);

// File locking
int acquireFileLock(NSString *path, BOOL exclusive);
void releaseFileLock(int fd);
BOOL writeImageToFileWithLocking(CGImageRef image, NSString *outputPath, int pngQuality, BOOL verbose, BOOL dryRun, BOOL forceOverwrite);

#endif /* UTILS_H */
