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
BOOL writeImageAsPNG(CGImageRef image, NSFileHandle *output, int pngQuality, BOOL verbose); // Added pngQuality and verbose
BOOL writeImageToFile(CGImageRef image, NSString *outputPath, int pngQuality, BOOL verbose); // Added pngQuality and verbose
NSString *getOutputPrefix(Options *options);
void logMessage(BOOL verbose, NSString *format, ...);

// Text extraction and processing
NSString *extractTextFromPDFPage(CGPDFPageRef page);
NSString *performOCROnImage(CGImageRef image);
NSString *slugifyText(NSString *text, NSUInteger maxLength);

// Page range parsing
NSArray<NSNumber *> *parsePageRange(NSString *rangeSpec, NSUInteger totalPages);

#endif /* UTILS_H */
