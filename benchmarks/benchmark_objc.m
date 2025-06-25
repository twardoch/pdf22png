#import <Foundation/Foundation.h>
#import "benchmark.h"
#import "../src/pdf22png.h"
#import "../src/utils.h"

BenchmarkResult benchmarkObjCImplementation(BenchmarkConfig config) {
    BenchmarkResult result = {0};
    NSMutableArray<NSNumber *> *times = [NSMutableArray array];
    uint64_t initialMemory = getCurrentMemoryUsage();
    uint64_t peakMemory = initialMemory;
    
    @autoreleasepool {
        // Load PDF document once
        NSURL *pdfURL = [NSURL fileURLWithPath:config.pdfPath];
        CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfURL);
        
        if (!pdfDocument) {
            NSLog(@"Failed to load PDF: %@", config.pdfPath);
            result.failureCount = config.iterations;
            return result;
        }
        
        size_t pageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
        if (pageCount == 0) {
            NSLog(@"PDF has no pages");
            CGPDFDocumentRelease(pdfDocument);
            result.failureCount = config.iterations;
            return result;
        }
        
        // Create temporary output directory
        NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"pdf22png_benchmark_objc"];
        [[NSFileManager defaultManager] createDirectoryAtPath:tempDir 
                                  withIntermediateDirectories:YES 
                                                   attributes:nil 
                                                        error:nil];
        
        // Run benchmark iterations
        for (NSInteger i = 0; i < config.iterations; i++) {
            @autoreleasepool {
                double startTime = getCurrentTimeInSeconds();
                
                // Create options for conversion
                Options options = {0};
                options.scale.scaleFactor = config.scaleFactor;
                options.scale.dpi = config.dpi;
                options.scale.isDPI = (config.dpi > 0);
                options.transparentBackground = config.transparent;
                options.pngQuality = 6;
                options.verbose = NO;
                options.batchMode = (config.pageCount > 1);
                options.outputDirectory = tempDir;
                
                BOOL success = YES;
                
                if (config.pageCount == 1) {
                    // Single page conversion
                    options.pageNumber = 1;
                    options.outputPath = [tempDir stringByAppendingPathComponent:
                                         [NSString stringWithFormat:@"page_%ld.png", (long)i]];
                    
                    CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocument, 1);
                    if (page) {
                        CGImageRef image = renderPDFPageToImage(page, options.scale.scaleFactor, options.transparentBackground, options.verbose);
                        if (image) {
                            success = writeImageToFile(image, options.outputPath, options.pngQuality, options.verbose, NO, YES);
                            CGImageRelease(image);
                        } else {
                            success = NO;
                        }
                    } else {
                        success = NO;
                    }
                } else {
                    // Multi-page conversion
                    for (size_t pageNum = 1; pageNum <= MIN(pageCount, config.pageCount); pageNum++) {
                        CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocument, pageNum);
                        if (page) {
                            NSString *outputPath = [tempDir stringByAppendingPathComponent:
                                                   [NSString stringWithFormat:@"iter_%ld_page_%03zu.png", (long)i, pageNum]];
                            
                            CGImageRef image = renderPDFPageToImage(page, options.scale.scaleFactor, options.transparentBackground, options.verbose);
                            if (image) {
                                if (!writeImageToFile(image, outputPath, options.pngQuality, options.verbose, NO, YES)) {
                                    success = NO;
                                }
                                CGImageRelease(image);
                            } else {
                                success = NO;
                            }
                        } else {
                            success = NO;
                        }
                    }
                }
                
                double endTime = getCurrentTimeInSeconds();
                double elapsedTime = endTime - startTime;
                
                [times addObject:@(elapsedTime)];
                
                if (success) {
                    result.successCount++;
                } else {
                    result.failureCount++;
                }
                
                // Update peak memory
                uint64_t currentMemory = getCurrentMemoryUsage();
                if (currentMemory > peakMemory) {
                    peakMemory = currentMemory;
                }
                
                // Clean up generated files for this iteration
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tempDir error:nil];
                for (NSString *file in files) {
                    if ([file hasPrefix:[NSString stringWithFormat:@"iter_%ld_", (long)i]] ||
                        [file isEqualToString:[NSString stringWithFormat:@"page_%ld.png", (long)i]]) {
                        [[NSFileManager defaultManager] removeItemAtPath:[tempDir stringByAppendingPathComponent:file] error:nil];
                    }
                }
            }
        }
        
        CGPDFDocumentRelease(pdfDocument);
        
        // Clean up temp directory
        [[NSFileManager defaultManager] removeItemAtPath:tempDir error:nil];
    }
    
    // Calculate statistics
    result.memoryPeak = peakMemory;
    
    if (times.count > 0) {
        double sum = 0;
        result.minTime = DBL_MAX;
        result.maxTime = 0;
        
        for (NSNumber *time in times) {
            double t = time.doubleValue;
            sum += t;
            if (t < result.minTime) result.minTime = t;
            if (t > result.maxTime) result.maxTime = t;
        }
        
        result.totalTime = sum;
        result.averageTime = sum / times.count;
        result.stdDev = calculateStandardDeviation(times, result.averageTime);
    }
    
    return result;
}