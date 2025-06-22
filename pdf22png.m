#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import <ImageIO/ImageIO.h>

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
} Options;

void printUsage(const char *programName) {
    fprintf(stderr, "Usage: %s [-s SCALE] [-p PAGE] [-i INPUT] [-o OUTPUT] [-d DIRECTORY]\n", programName);
    fprintf(stderr, "  Converts PDF to PNG image(s)\n");
    fprintf(stderr, "  -i INPUT: input PDF file (default: stdin)\n");
    fprintf(stderr, "  -o OUTPUT: output PNG file (default: stdout)\n");
    fprintf(stderr, "  -d DIRECTORY: output directory for batch mode (converts all pages)\n");
    fprintf(stderr, "                In batch mode, -p is ignored and -o becomes filename prefix\n");
    fprintf(stderr, "  -s SCALE: scaling specification (default: 100%%)\n");
    fprintf(stderr, "     NNN%%     - percentage scale (e.g. 100%%)\n");
    fprintf(stderr, "     HHHxWWW  - fit to height x width in pixels\n");
    fprintf(stderr, "     HHHx     - fit to height in pixels\n");
    fprintf(stderr, "     xWWW     - fit to width in pixels\n");
    fprintf(stderr, "     AAAdpi   - dots per inch\n");
    fprintf(stderr, "  -p PAGE: page number (default: 1, ignored in batch mode)\n");
}

BOOL parseScaleSpec(const char *spec, ScaleSpec *scale) {
    if (!spec || !scale) return NO;
    
    // Initialize scale
    memset(scale, 0, sizeof(ScaleSpec));
    scale->scaleFactor = 1.0;
    
    NSString *specStr = [NSString stringWithUTF8String:spec];
    
    // Check for percentage (NNN%)
    if ([specStr hasSuffix:@"%"]) {
        NSString *numStr = [specStr substringToIndex:[specStr length] - 1];
        scale->scaleFactor = [numStr doubleValue] / 100.0;
        scale->isPercentage = YES;
        return scale->scaleFactor > 0;
    }
    
    // Check for DPI (AAAdpi)
    if ([specStr hasSuffix:@"dpi"]) {
        NSString *numStr = [specStr substringToIndex:[specStr length] - 3];
        scale->dpi = [numStr doubleValue];
        scale->isDPI = YES;
        return scale->dpi > 0;
    }
    
    // Check for dimensions (HHHxWWW, HHHx, xWWW)
    NSRange xRange = [specStr rangeOfString:@"x"];
    if (xRange.location != NSNotFound) {
        NSString *heightStr = [specStr substringToIndex:xRange.location];
        NSString *widthStr = [specStr substringFromIndex:xRange.location + 1];
        
        if ([heightStr length] > 0) {
            scale->maxHeight = [heightStr doubleValue];
            scale->hasHeight = YES;
        }
        
        if ([widthStr length] > 0) {
            scale->maxWidth = [widthStr doubleValue];
            scale->hasWidth = YES;
        }
        
        return scale->hasHeight || scale->hasWidth;
    }
    
    return NO;
}

Options parseArguments(int argc, const char *argv[]) {
    Options options = {
        .scale = {.scaleFactor = 1.0, .isPercentage = YES},
        .pageNumber = 1,
        .inputPath = nil,
        .outputPath = nil,
        .outputDirectory = nil,
        .batchMode = NO
    };
    
    int opt;
    while ((opt = getopt(argc, (char * const *)argv, "s:p:i:o:d:h")) != -1) {
        switch (opt) {
            case 's':
                if (!parseScaleSpec(optarg, &options.scale)) {
                    fprintf(stderr, "Invalid scale specification: %s\n", optarg);
                    exit(1);
                }
                break;
            case 'p':
                options.pageNumber = atoi(optarg);
                if (options.pageNumber < 1) {
                    fprintf(stderr, "Invalid page number: %s\n", optarg);
                    exit(1);
                }
                break;
            case 'i':
                options.inputPath = [NSString stringWithUTF8String:optarg];
                break;
            case 'o':
                options.outputPath = [NSString stringWithUTF8String:optarg];
                break;
            case 'd':
                options.outputDirectory = [NSString stringWithUTF8String:optarg];
                options.batchMode = YES;
                break;
            case 'h':
                printUsage(argv[0]);
                exit(0);
            default:
                printUsage(argv[0]);
                exit(1);
        }
    }
    
    return options;
}

NSData *readDataFromStdin() {
    NSMutableData *data = [NSMutableData data];
    char buffer[4096];
    size_t bytesRead;
    
    while ((bytesRead = fread(buffer, 1, sizeof(buffer), stdin)) > 0) {
        [data appendBytes:buffer length:bytesRead];
    }
    
    if (ferror(stdin)) {
        fprintf(stderr, "Error reading from stdin\n");
        return nil;
    }
    
    return data;
}

NSData *readPDFData(NSString *inputPath) {
    if (inputPath) {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:inputPath options:0 error:&error];
        if (!data) {
            fprintf(stderr, "Error reading file %s: %s\n", 
                    [inputPath UTF8String], 
                    [[error localizedDescription] UTF8String]);
        }
        return data;
    } else {
        return readDataFromStdin();
    }
}

CGFloat calculateScaleFactor(ScaleSpec *scale, CGRect pageRect) {
    if (scale->isPercentage) {
        return scale->scaleFactor;
    }
    
    if (scale->isDPI) {
        // PDF points are 72 DPI by default
        return scale->dpi / 72.0;
    }
    
    CGFloat scaleX = 1.0, scaleY = 1.0;
    
    if (scale->hasWidth && pageRect.size.width > 0) {
        scaleX = scale->maxWidth / pageRect.size.width;
    }
    
    if (scale->hasHeight && pageRect.size.height > 0) {
        scaleY = scale->maxHeight / pageRect.size.height;
    }
    
    if (scale->hasWidth && scale->hasHeight) {
        // Fit within both dimensions
        return fmin(scaleX, scaleY);
    } else if (scale->hasWidth) {
        return scaleX;
    } else if (scale->hasHeight) {
        return scaleY;
    }
    
    return 1.0;
}

CGImageRef renderPDFPageToImage(CGPDFPageRef pdfPage, CGFloat scaleFactor) {
    if (!pdfPage) return NULL;
    
    // Get page dimensions
    CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
    size_t width = (size_t)(pageRect.size.width * scaleFactor);
    size_t height = (size_t)(pageRect.size.height * scaleFactor);
    
    // Create bitmap context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace,
                                                kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        fprintf(stderr, "Failed to create bitmap context\n");
        return NULL;
    }
    
    // Set white background
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    
    // Save context state
    CGContextSaveGState(context);
    
    // Scale and translate for PDF rendering
    CGContextScaleCTM(context, scaleFactor, scaleFactor);
    CGContextTranslateCTM(context, -pageRect.origin.x, -pageRect.origin.y);
    
    // Draw PDF page
    CGContextDrawPDFPage(context, pdfPage);
    
    // Restore context state
    CGContextRestoreGState(context);
    
    // Create image from context
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return image;
}

BOOL writeImageAsPNG(CGImageRef image, NSFileHandle *output) {
    if (!image || !output) return NO;
    
    // Create image destination for PNG
    NSMutableData *imageData = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)imageData,
                                                                        (__bridge CFStringRef)@"public.png", 1, NULL);
    if (!destination) {
        fprintf(stderr, "Failed to create image destination\n");
        return NO;
    }
    
    // Add image to destination
    CGImageDestinationAddImage(destination, image, NULL);
    
    // Finalize the destination
    if (!CGImageDestinationFinalize(destination)) {
        fprintf(stderr, "Failed to finalize image\n");
        CFRelease(destination);
        return NO;
    }
    
    CFRelease(destination);
    
    // Write to output
    [output writeData:imageData];
    
    return YES;
}

BOOL writeImageToFile(CGImageRef image, NSString *outputPath) {
    if (!image || !outputPath) return NO;
    
    NSURL *url = [NSURL fileURLWithPath:outputPath];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)url,
                                                                       (__bridge CFStringRef)@"public.png", 1, NULL);
    if (!destination) {
        fprintf(stderr, "Failed to create image destination for file\n");
        return NO;
    }
    
    // Add image to destination
    CGImageDestinationAddImage(destination, image, NULL);
    
    // Finalize the destination
    BOOL success = CGImageDestinationFinalize(destination);
    if (!success) {
        fprintf(stderr, "Failed to write image to file\n");
    }
    
    CFRelease(destination);
    return success;
}

NSString *getOutputPrefix(Options *options) {
    if (options->outputPath) {
        return options->outputPath;
    } else if (options->inputPath) {
        // Use basename of input file
        NSString *basename = [[options->inputPath lastPathComponent] stringByDeletingPathExtension];
        return basename;
    } else {
        return @"page";
    }
}

BOOL processSinglePage(CGPDFDocumentRef pdfDocument, Options *options) {
    // Check page count
    size_t pageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
    if (options->pageNumber > (NSInteger)pageCount) {
        fprintf(stderr, "Page %ld does not exist (document has %zu pages)\n", 
                (long)options->pageNumber, pageCount);
        return NO;
    }
    
    // Get the requested page
    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDocument, options->pageNumber);
    if (!pdfPage) {
        fprintf(stderr, "Failed to get page %ld\n", (long)options->pageNumber);
        return NO;
    }
    
    // Calculate scale factor based on scale specification
    CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
    CGFloat scaleFactor = calculateScaleFactor(&options->scale, pageRect);
    
    // Render page to image
    CGImageRef image = renderPDFPageToImage(pdfPage, scaleFactor);
    if (!image) {
        fprintf(stderr, "Failed to render PDF page\n");
        return NO;
    }
    
    BOOL success;
    if (options->outputPath) {
        success = writeImageToFile(image, options->outputPath);
    } else {
        NSFileHandle *stdoutHandle = [NSFileHandle fileHandleWithStandardOutput];
        success = writeImageAsPNG(image, stdoutHandle);
    }
    
    CGImageRelease(image);
    return success;
}

BOOL processBatchMode(CGPDFDocumentRef pdfDocument, Options *options) {
    // Create output directory if it doesn't exist
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager createDirectoryAtPath:options->outputDirectory 
                withIntermediateDirectories:YES 
                                 attributes:nil 
                                      error:&error]) {
        fprintf(stderr, "Failed to create output directory: %s\n", 
                [[error localizedDescription] UTF8String]);
        return NO;
    }
    
    size_t pageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
    NSString *prefix = getOutputPrefix(options);
    
    __block volatile BOOL overallSuccess = YES;
    NSObject *lock = [[NSObject alloc] init];

    dispatch_apply(pageCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        if (!overallSuccess) {
            return;
        }

        size_t pageNum = i + 1;
        
        @autoreleasepool {
            CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDocument, pageNum);
            if (!pdfPage) {
                fprintf(stderr, "Failed to get page %zu\n", pageNum);
                @synchronized(lock) {
                    overallSuccess = NO;
                }
                return;
            }
            
            // Calculate scale factor
            CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
            CGFloat scaleFactor = calculateScaleFactor(&options->scale, pageRect);
            
            // Render page to image
            CGImageRef image = renderPDFPageToImage(pdfPage, scaleFactor);
            if (!image) {
                fprintf(stderr, "Failed to render page %zu\n", pageNum);
                @synchronized(lock) {
                    overallSuccess = NO;
                }
                return;
            }
            
            // Generate output filename
            NSString *filename = [NSString stringWithFormat:@"%@-%03zu.png", prefix, pageNum];
            NSString *outputPath = [options->outputDirectory stringByAppendingPathComponent:filename];
            
            if (!writeImageToFile(image, outputPath)) {
                fprintf(stderr, "Failed to write page %zu\n", pageNum);
                @synchronized(lock) {
                    overallSuccess = NO;
                }
            }
            
            CGImageRelease(image);
        }
    });
    
    return overallSuccess;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        // Parse command line arguments
        Options options = parseArguments(argc, argv);
        
        // Read PDF data
        NSData *pdfData = readPDFData(options.inputPath);
        if (!pdfData || [pdfData length] == 0) {
            fprintf(stderr, "No PDF data received\n");
            return 1;
        }
        
        // Create PDF document
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)pdfData);
        CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithProvider(provider);
        CGDataProviderRelease(provider);
        
        if (!pdfDocument) {
            fprintf(stderr, "Failed to create PDF document\n");
            return 1;
        }
        
        BOOL success;
        if (options.batchMode) {
            success = processBatchMode(pdfDocument, &options);
        } else {
            success = processSinglePage(pdfDocument, &options);
        }
        
        // Cleanup
        CGPDFDocumentRelease(pdfDocument);
        
        return success ? 0 : 1;
    }
}