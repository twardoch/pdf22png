#import "utils.h"
#import <Vision/Vision.h>
#import <fcntl.h>
#import <sys/file.h>

void logMessage(BOOL verbose, NSString *format, ...) {
    if (verbose) {
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        fprintf(stderr, "%s\n", [message UTF8String]);
    }
}

BOOL parseScaleSpec(const char *spec, ScaleSpec *scale) {
    if (!spec || !scale) return NO;

    // Initialize scale
    memset(scale, 0, sizeof(ScaleSpec));
    scale->scaleFactor = 1.0; // Default to 100% if not specified otherwise

    NSString *specStr = [NSString stringWithUTF8String:spec];

    // Check for percentage (NNN%)
    if ([specStr hasSuffix:@"%"]) {
        NSString *numStr = [specStr substringToIndex:[specStr length] - 1];
        scale->scaleFactor = [numStr doubleValue] / 100.0;
        scale->isPercentage = YES;
        if (scale->scaleFactor <= 0) {
            reportError(@"Scale percentage must be positive.",
                       getTroubleshootingHint(@"scale format"));
            return NO;
        }
        return YES;
    }

    // Check for DPI (AAAdpi)
    if ([specStr hasSuffix:@"dpi"]) {
        NSString *numStr = [specStr substringToIndex:[specStr length] - 3];
        scale->dpi = [numStr doubleValue];
        scale->isDPI = YES;
        if (scale->dpi <= 0) {
            reportError(@"DPI value must be positive.",
                       getTroubleshootingHint(@"scale format"));
            return NO;
        }
        return YES;
    }

    // Check for dimensions (HHHxWWW, HHHx, xWWW)
    NSRange xRange = [specStr rangeOfString:@"x" options:NSCaseInsensitiveSearch]; // Case insensitive 'x'
    if (xRange.location != NSNotFound) {
        NSString *heightStr = @"";
        if (xRange.location > 0) {
            heightStr = [specStr substringToIndex:xRange.location];
        }
        NSString *widthStr = @"";
        if (xRange.location < [specStr length] - 1) {
            widthStr = [specStr substringFromIndex:xRange.location + 1];
        }

        if ([heightStr length] > 0) {
            scale->maxHeight = [heightStr doubleValue];
            if (scale->maxHeight <= 0) {
                fprintf(stderr, "Error: Height dimension must be positive.\n");
                return NO;
            }
            scale->hasHeight = YES;
        }

        if ([widthStr length] > 0) {
            scale->maxWidth = [widthStr doubleValue];
            if (scale->maxWidth <= 0) {
                fprintf(stderr, "Error: Width dimension must be positive.\n");
                return NO;
            }
            scale->hasWidth = YES;
        }

        return scale->hasHeight || scale->hasWidth;
    }

    // If no known suffix or 'x' separator, try to parse as a simple number (scale factor)
    // This makes "-s 2.0" work as scale factor 2.0
    NSScanner *scanner = [NSScanner scannerWithString:specStr];
    double factor;
    if ([scanner scanDouble:&factor] && [scanner isAtEnd]) {
        if (factor <= 0) {
            fprintf(stderr, "Error: Scale factor must be positive.\n");
            return NO;
        }
        scale->scaleFactor = factor;
        scale->isPercentage = NO; // Explicitly not a percentage
        scale->isDPI = NO;
        scale->hasWidth = NO;
        scale->hasHeight = NO;
        return YES;
    }

    fprintf(stderr, "Error: Invalid scale specification format: %s\n", spec);
    return NO;
}

NSData *readDataFromStdin(void) {
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

NSData *readPDFData(NSString *inputPath, BOOL verbose) {
    logMessage(verbose, @"Reading PDF data from: %@", inputPath ? inputPath : @"stdin");
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

    // If only scaleFactor is set (e.g. from "-s 2.0")
    if (!scale->hasWidth && !scale->hasHeight && scale->scaleFactor > 0) {
        return scale->scaleFactor;
    }

    CGFloat scaleX = 1.0, scaleY = 1.0;

    if (scale->hasWidth && pageRect.size.width > 0) {
        scaleX = scale->maxWidth / pageRect.size.width;
    }

    if (scale->hasHeight && pageRect.size.height > 0) {
        scaleY = scale->maxHeight / pageRect.size.height;
    }

    if (scale->hasWidth && scale->hasHeight) { // HHHxWWW, fit to smallest
        return fmin(scaleX, scaleY);
    } else if (scale->hasWidth) { // xWWW
        return scaleX;
    } else if (scale->hasHeight) { // HHHx
        return scaleY;
    }

    return 1.0; // Default, should ideally be covered by isPercentage or direct scaleFactor
}

CGImageRef renderPDFPageToImage(CGPDFPageRef pdfPage, CGFloat scaleFactor, BOOL transparentBackground, BOOL verbose) {
    if (!pdfPage) return NULL;
    
    __block CGImageRef image = NULL;
    
    @autoreleasepool {
        logMessage(verbose, @"Rendering PDF page with scale factor: %.2f", scaleFactor);

        CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
        size_t width = (size_t)round(pageRect.size.width * scaleFactor);
        size_t height = (size_t)round(pageRect.size.height * scaleFactor);

        if (width == 0 || height == 0) {
            fprintf(stderr, "Error: Calculated image dimensions are zero (width: %zu, height: %zu). Check scale factor and PDF page size.\n", width, height);
            return NULL;
        }

        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CGBitmapInfo bitmapInfo = transparentBackground ? (CGBitmapInfo)kCGImageAlphaPremultipliedLast : (CGBitmapInfo)kCGImageAlphaNoneSkipLast;
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, bitmapInfo);
        CGColorSpaceRelease(colorSpace);

        if (!context) {
            fprintf(stderr, "Failed to create bitmap context\n");
            return NULL;
        }

        if (!transparentBackground) {
            CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
            CGContextFillRect(context, CGRectMake(0, 0, width, height));
        } else {
            CGContextClearRect(context, CGRectMake(0, 0, width, height));
        }

        CGContextSaveGState(context);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);

        CGContextDrawPDFPage(context, pdfPage);

        CGContextRestoreGState(context);

        image = CGBitmapContextCreateImage(context);
        CGContextRelease(context);

        logMessage(verbose, @"Page rendered to CGImageRef successfully.");
    }
    
    return image;
}

CGImageRef renderPDFPageToImageOptimized(CGPDFPageRef pdfPage, CGFloat scaleFactor, BOOL transparentBackground, BOOL verbose, CGColorSpaceRef colorSpace) {
    if (!pdfPage) return NULL;
    
    CGImageRef image = NULL;
    
    logMessage(verbose, @"Rendering PDF page with scale factor: %.2f (optimized)", scaleFactor);

    CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
    size_t width = (size_t)round(pageRect.size.width * scaleFactor);
    size_t height = (size_t)round(pageRect.size.height * scaleFactor);

    if (width == 0 || height == 0) {
        fprintf(stderr, "Error: Calculated image dimensions are zero (width: %zu, height: %zu). Check scale factor and PDF page size.\n", width, height);
        return NULL;
    }

    // Use shared color space instead of creating a new one
    CGBitmapInfo bitmapInfo = transparentBackground ? (CGBitmapInfo)kCGImageAlphaPremultipliedLast : (CGBitmapInfo)kCGImageAlphaNoneSkipLast;
    
    // Pre-allocate buffer for better memory management
    size_t bytesPerRow = (width * 4 + 15) & ~15; // 16-byte aligned for better performance
    void *bitmapData = calloc(height, bytesPerRow);
    if (!bitmapData) {
        fprintf(stderr, "Failed to allocate bitmap buffer\n");
        return NULL;
    }
    
    CGContextRef context = CGBitmapContextCreate(bitmapData, width, height, 8, bytesPerRow, colorSpace, bitmapInfo);

    if (!context) {
        fprintf(stderr, "Failed to create bitmap context\n");
        free(bitmapData);
        return NULL;
    }

    if (!transparentBackground) {
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(context, CGRectMake(0, 0, width, height));
    }

    CGContextSaveGState(context);
    CGContextScaleCTM(context, scaleFactor, scaleFactor);

    // Use high-quality rendering for better results
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    
    CGContextDrawPDFPage(context, pdfPage);

    CGContextRestoreGState(context);

    image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    free(bitmapData);

    logMessage(verbose, @"Page rendered to CGImageRef successfully (optimized).");
    
    return image;
}

BOOL writeImageAsPNG(CGImageRef image, NSFileHandle *output, int pngQuality, BOOL verbose) {
    if (!image || !output) return NO;

    logMessage(verbose, @"Writing image as PNG to stdout with quality: %d", pngQuality);

    NSMutableData *imageData = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData,
                                                                        kUTTypePNG, 1, NULL);
    if (!destination) {
        fprintf(stderr, "Failed to create image destination for stdout\n");
        return NO;
    }

    // PNG Quality/Compression
    // ImageIO uses a float from 0.0 (max compression) to 1.0 (lossless)
    // We need to map our 0-9 to this. Let's say 0 is max compression (0.0), 9 is min compression (0.9 for example)
    // Or, more simply, use kCGImageCompressionQuality which is what the quality parameter implies
    // For PNG, it's typically lossless, but some libraries might offer control over filter strategies or zlib level.
    // For now, let's assume higher 'pngQuality' means less compression effort (faster) if applicable,
    // or map to kCGImageDestinationLossyCompressionQuality if we were doing lossy.
    // Since PNG is lossless, this 'quality' might map to compression effort/speed.
    // The default is usually a good balance. Let's make it explicit if quality is not default (6).
    NSDictionary *props = nil;
    if (pngQuality >= 0 && pngQuality <= 9) { // Assuming 0-9, map to 0.0-1.0 for kCGImageDestinationLossyCompressionQuality if it were lossy
                                          // For PNG, this specific key might not do much, but let's keep it for future.
                                          // A value closer to 1.0 means less compression.
        // float compressionValue = (float)pngQuality / 9.0f;
        // props = @{(__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(compressionValue)};
        // For PNG, there isn't a direct "quality" setting like JPEG.
        // It's lossless. We can control things like interlace, filters, or zlib compression level,
        // but CGImageDestination doesn't expose these directly for PNGs.
        // So, pngQuality might be ignored here or we can log a message.
        logMessage(verbose, @"PNG quality setting (%d) is noted, but CoreGraphics offers limited control for PNG compression levels.", pngQuality);
    }


    CGImageDestinationAddImage(destination, image, (__bridge CFDictionaryRef)props);

    if (!CGImageDestinationFinalize(destination)) {
        fprintf(stderr, "Failed to finalize image for stdout\n");
        CFRelease(destination);
        return NO;
    }
    CFRelease(destination);

    @try {
        [output writeData:imageData];
    } @catch (NSException *exception) {
        fprintf(stderr, "Error writing PNG data to stdout: %s\n", [[exception reason] UTF8String]);
        return NO;
    }

    logMessage(verbose, @"Image written to stdout successfully.");
    return YES;
}

BOOL writeImageToFile(CGImageRef image, NSString *outputPath, int pngQuality, BOOL verbose, BOOL dryRun, BOOL forceOverwrite) {
    if (!image || !outputPath) return NO;

    if (dryRun) {
        // In dry-run mode, just report what would be created
        BOOL exists = fileExists(outputPath);
        fprintf(stdout, "[DRY-RUN] Would create: %s%s\n", [outputPath UTF8String], 
                exists ? " (overwrites existing)" : "");
        
        // Calculate approximate file size for the image
        size_t width = CGImageGetWidth(image);
        size_t height = CGImageGetHeight(image);
        size_t bitsPerPixel = CGImageGetBitsPerPixel(image);
        size_t estimatedSize = (width * height * bitsPerPixel) / 8 / 1024; // KB
        
        fprintf(stdout, "          Dimensions: %zux%zu, Estimated size: ~%zu KB\n", width, height, estimatedSize);
        return YES;
    }

    // Always overwrite files by default
    if (fileExists(outputPath) && verbose && forceOverwrite) {
        logMessage(verbose, @"Warning: Overwriting existing file: %@", outputPath);
    }

    logMessage(verbose, @"Writing image as PNG to file: %@ with quality: %d", outputPath, pngQuality);

    NSURL *url = [NSURL fileURLWithPath:outputPath];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)url,
                                                                       kUTTypePNG, 1, NULL);
    if (!destination) {
        fprintf(stderr, "Failed to create image destination for file: %s\n", [outputPath UTF8String]);
        return NO;
    }

    NSDictionary *props = nil;
     if (pngQuality >= 0 && pngQuality <= 9) {
        logMessage(verbose, @"PNG quality setting (%d) is noted, but CoreGraphics offers limited control for PNG compression levels.", pngQuality);
    }

    CGImageDestinationAddImage(destination, image, (__bridge CFDictionaryRef)props);

    BOOL success = CGImageDestinationFinalize(destination);
    if (!success) {
        fprintf(stderr, "Failed to write image to file: %s\n", [outputPath UTF8String]);
    }

    CFRelease(destination);
    logMessage(verbose, @"Image written to file %@ %s.", outputPath, success ? "successfully" : "failed");
    return success;
}

NSString *getOutputPrefix(Options *options) {
    if (options->outputPath && ![options->outputPath isEqualToString:@"-"]) { // Treat "-" as stdout for prefix
        // If output path is a full filename (e.g., "image.png"), use "image"
        // If it's just a prefix (e.g., "img_"), use it as is.
        // For batch mode, -o is always a prefix.
        return [[options->outputPath lastPathComponent] stringByDeletingPathExtension];
    } else if (options->inputPath) {
        // Use basename of input file
        NSString *basename = [[options->inputPath lastPathComponent] stringByDeletingPathExtension];
        return basename;
    } else {
        return @"page"; // Default prefix if input is stdin and no output path
    }
}

// PDF operator callbacks (forward declarations)
static void pdf_Tj(CGPDFScannerRef scanner, void *info);
static void pdf_TJ(CGPDFScannerRef scanner, void *info);
static void pdf_Quote(CGPDFScannerRef scanner, void *info);
static void pdf_DoubleQuote(CGPDFScannerRef scanner, void *info);

NSString *extractTextFromPDFPage(CGPDFPageRef page) {
    if (!page) return nil;
    
    NSMutableString *pageText = [NSMutableString string];
    
    // Create a PDF Scanner
    CGPDFScannerRef scanner = NULL;
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(page);
    if (contentStream) {
        CGPDFOperatorTableRef operatorTable = CGPDFOperatorTableCreate();
        
        // Set up operator callbacks for text extraction
        CGPDFOperatorTableSetCallback(operatorTable, "Tj", &pdf_Tj);
        CGPDFOperatorTableSetCallback(operatorTable, "TJ", &pdf_TJ);
        CGPDFOperatorTableSetCallback(operatorTable, "'", &pdf_Quote);
        CGPDFOperatorTableSetCallback(operatorTable, "\"", &pdf_DoubleQuote);
        
        scanner = CGPDFScannerCreate(contentStream, operatorTable, (__bridge void *)pageText);
        if (scanner) {
            CGPDFScannerScan(scanner);
            CGPDFScannerRelease(scanner);
        }
        
        CGPDFOperatorTableRelease(operatorTable);
        CGPDFContentStreamRelease(contentStream);
    }
    
    // Clean up the text
    NSString *cleanedText = [pageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    cleanedText = [cleanedText stringByReplacingOccurrencesOfString:@"\\s+" withString:@" " 
                                                           options:NSRegularExpressionSearch 
                                                             range:NSMakeRange(0, cleanedText.length)];
    
    return cleanedText.length > 0 ? cleanedText : nil;
}

// PDF operator callbacks
static void pdf_Tj(CGPDFScannerRef scanner, void *info) {
    CGPDFStringRef pdfString = NULL;
    if (CGPDFScannerPopString(scanner, &pdfString)) {
        NSString *string = (__bridge_transfer NSString *)CGPDFStringCopyTextString(pdfString);
        if (string) {
            NSMutableString *pageText = (__bridge NSMutableString *)info;
            [pageText appendString:string];
            [pageText appendString:@" "];
        }
    }
}

static void pdf_TJ(CGPDFScannerRef scanner, void *info) {
    CGPDFArrayRef array = NULL;
    if (CGPDFScannerPopArray(scanner, &array)) {
        size_t count = CGPDFArrayGetCount(array);
        NSMutableString *pageText = (__bridge NSMutableString *)info;
        
        for (size_t i = 0; i < count; i++) {
            CGPDFObjectRef object = NULL;
            if (CGPDFArrayGetObject(array, i, &object)) {
                CGPDFObjectType type = CGPDFObjectGetType(object);
                if (type == kCGPDFObjectTypeString) {
                    CGPDFStringRef pdfString = NULL;
                    if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &pdfString)) {
                        NSString *string = (__bridge_transfer NSString *)CGPDFStringCopyTextString(pdfString);
                        if (string) {
                            [pageText appendString:string];
                        }
                    }
                }
            }
        }
        [pageText appendString:@" "];
    }
}

static void pdf_Quote(CGPDFScannerRef scanner, void *info) {
    pdf_Tj(scanner, info);
}

static void pdf_DoubleQuote(CGPDFScannerRef scanner, void *info) {
    // Skip the two numeric parameters
    CGPDFReal tc, tw;
    CGPDFScannerPopNumber(scanner, &tc);
    CGPDFScannerPopNumber(scanner, &tw);
    pdf_Tj(scanner, info);
}

NSString *performOCROnImage(CGImageRef image) {
    if (!image) return nil;
    
    __block NSString *recognizedText = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    @autoreleasepool {
        // Create Vision request
        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
            if (error) {
                NSLog(@"OCR Error: %@", error.localizedDescription);
                dispatch_semaphore_signal(semaphore);
                return;
            }
            
            NSMutableString *fullText = [NSMutableString string];
            for (VNRecognizedTextObservation *observation in request.results) {
                VNRecognizedText *topCandidate = [observation topCandidates:1].firstObject;
                if (topCandidate) {
                    [fullText appendString:topCandidate.string];
                    [fullText appendString:@" "];
                }
            }
            
            recognizedText = [fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            dispatch_semaphore_signal(semaphore);
        }];
        
        request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
        request.recognitionLanguages = @[@"en-US"]; // Add more languages as needed
        request.usesLanguageCorrection = YES;
        
        // Create handler and perform request
        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image options:@{}];
        NSError *error = nil;
        [handler performRequests:@[request] error:&error];
        
        if (error) {
            NSLog(@"Failed to perform OCR: %@", error.localizedDescription);
            dispatch_semaphore_signal(semaphore);
        }
    }
    
    // Wait for OCR to complete (with timeout)
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
    
    return recognizedText;
}

NSString *slugifyText(NSString *text, NSUInteger maxLength) {
    if (!text || text.length == 0) return @"";
    
    // Convert to lowercase
    NSString *lowercased = [text lowercaseString];
    
    // Replace non-alphanumeric characters with hyphens
    NSMutableString *slugified = [NSMutableString string];
    NSCharacterSet *alphanumeric = [NSCharacterSet alphanumericCharacterSet];
    
    BOOL lastWasHyphen = NO;
    for (NSUInteger i = 0; i < lowercased.length && slugified.length < maxLength; i++) {
        unichar ch = [lowercased characterAtIndex:i];
        
        if ([alphanumeric characterIsMember:ch]) {
            [slugified appendFormat:@"%C", ch];
            lastWasHyphen = NO;
        } else if (!lastWasHyphen && slugified.length > 0) {
            [slugified appendString:@"-"];
            lastWasHyphen = YES;
        }
    }
    
    // Remove trailing hyphen if present
    if ([slugified hasSuffix:@"-"]) {
        [slugified deleteCharactersInRange:NSMakeRange(slugified.length - 1, 1)];
    }
    
    // Truncate to maxLength
    if (slugified.length > maxLength) {
        NSString *truncated = [slugified substringToIndex:maxLength];
        // Remove partial word at end
        NSRange lastHyphen = [truncated rangeOfString:@"-" options:NSBackwardsSearch];
        if (lastHyphen.location != NSNotFound && lastHyphen.location > maxLength * 0.7) {
            truncated = [truncated substringToIndex:lastHyphen.location];
        }
        return truncated;
    }
    
    return slugified;
}

NSArray<NSNumber *> *parsePageRange(NSString *rangeSpec, NSUInteger totalPages) {
    if (!rangeSpec || rangeSpec.length == 0) {
        return nil;
    }
    
    NSMutableSet *pageSet = [NSMutableSet set];
    NSArray *parts = [rangeSpec componentsSeparatedByString:@","];
    
    for (NSString *part in parts) {
        NSString *trimmedPart = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check if it's a range (contains hyphen)
        NSRange hyphenRange = [trimmedPart rangeOfString:@"-"];
        if (hyphenRange.location != NSNotFound) {
            // Split range into start and end
            NSArray *rangeParts = [trimmedPart componentsSeparatedByString:@"-"];
            if (rangeParts.count == 2) {
                NSInteger start = [rangeParts[0] integerValue];
                NSInteger end = [rangeParts[1] integerValue];
                
                // Validate range
                if (start < 1) start = 1;
                if (end > (NSInteger)totalPages) end = (NSInteger)totalPages;
                
                if (start <= end) {
                    for (NSInteger i = start; i <= end; i++) {
                        [pageSet addObject:@(i)];
                    }
                }
            }
        } else {
            // Single page number
            NSInteger pageNum = [trimmedPart integerValue];
            if (pageNum >= 1 && pageNum <= (NSInteger)totalPages) {
                [pageSet addObject:@(pageNum)];
            }
        }
    }
    
    // Convert set to sorted array
    NSArray *sortedPages = [[pageSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj1 compare:obj2];
    }];
    
    return sortedPages;
}

NSString *formatFilenameWithPattern(NSString *pattern, NSString *basename, NSUInteger pageNum, 
                                   NSUInteger totalPages, NSString *extractedText) {
    if (!pattern || pattern.length == 0) {
        // Default pattern if none specified
        if (extractedText && extractedText.length > 0) {
            return [NSString stringWithFormat:@"%@-%03zu--%@", basename, pageNum, extractedText];
        } else {
            return [NSString stringWithFormat:@"%@-%03zu", basename, pageNum];
        }
    }
    
    NSMutableString *result = [NSMutableString stringWithString:pattern];
    
    // Replace {basename} or {name}
    [result replaceOccurrencesOfString:@"{basename}" withString:basename 
                              options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"{name}" withString:basename 
                              options:0 range:NSMakeRange(0, result.length)];
    
    // Replace {page} with zero-padded page number
    NSUInteger digits = (NSUInteger)log10(totalPages > 0 ? totalPages : 1) + 1;
    if (digits < 3) digits = 3; // Minimum 3 digits
    NSString *pageStr = [NSString stringWithFormat:@"%0*zu", (int)digits, pageNum];
    [result replaceOccurrencesOfString:@"{page}" withString:pageStr 
                              options:0 range:NSMakeRange(0, result.length)];
    
    // Replace {page:03d} style formatting
    NSRegularExpression *pageFormatRegex = [NSRegularExpression regularExpressionWithPattern:@"\\{page:0?(\\d+)d\\}" 
                                                                                    options:0 error:nil];
    NSArray *matches = [pageFormatRegex matchesInString:result options:0 
                                               range:NSMakeRange(0, result.length)];
    
    // Process matches in reverse order to avoid index shifting
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSRange digitRange = [match rangeAtIndex:1];
        NSString *digitStr = [result substringWithRange:digitRange];
        int formatDigits = [digitStr intValue];
        NSString *formattedPage = [NSString stringWithFormat:@"%0*zu", formatDigits, pageNum];
        [result replaceCharactersInRange:match.range withString:formattedPage];
    }
    
    // Replace {text} with extracted text (if available)
    if (extractedText && extractedText.length > 0) {
        [result replaceOccurrencesOfString:@"{text}" withString:extractedText 
                                  options:0 range:NSMakeRange(0, result.length)];
    } else {
        [result replaceOccurrencesOfString:@"{text}" withString:@"" 
                                  options:0 range:NSMakeRange(0, result.length)];
    }
    
    // Replace {date} with current date in YYYYMMDD format
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    [result replaceOccurrencesOfString:@"{date}" withString:dateStr 
                              options:0 range:NSMakeRange(0, result.length)];
    
    // Replace {time} with current time in HHMMSS format  
    [dateFormatter setDateFormat:@"HHmmss"];
    NSString *timeStr = [dateFormatter stringFromDate:[NSDate date]];
    [result replaceOccurrencesOfString:@"{time}" withString:timeStr 
                              options:0 range:NSMakeRange(0, result.length)];
    
    // Replace {total} with total page count
    [result replaceOccurrencesOfString:@"{total}" withString:[NSString stringWithFormat:@"%zu", totalPages] 
                              options:0 range:NSMakeRange(0, result.length)];
    
    return result;
}

// File overwrite protection functions
BOOL fileExists(NSString *path) {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

BOOL shouldOverwriteFile(NSString *path, BOOL interactive) {
    if (!fileExists(path)) {
        return YES; // File doesn't exist, safe to write
    }
    
    // Always overwrite by default (changed behavior)
    return YES;
}

BOOL promptUserForOverwrite(NSString *path) {
    fprintf(stderr, "File '%s' already exists. Overwrite? (y/N): ", [path UTF8String]);
    fflush(stderr);
    
    char response[10];
    if (fgets(response, sizeof(response), stdin) == NULL) {
        return NO; // No input, default to no
    }
    
    // Check first character, case insensitive
    char first = response[0];
    return (first == 'y' || first == 'Y');
}

// Enhanced error reporting functions
void reportError(NSString *message, NSString *troubleshootingHint) {
    fprintf(stderr, "Error: %s\n", [message UTF8String]);
    if (troubleshootingHint) {
        fprintf(stderr, "Hint:  %s\n", [troubleshootingHint UTF8String]);
    }
}

void reportWarning(NSString *message, NSString *troubleshootingHint) {
    fprintf(stderr, "Warning: %s\n", [message UTF8String]);
    if (troubleshootingHint) {
        fprintf(stderr, "Hint:    %s\n", [troubleshootingHint UTF8String]);
    }
}

NSString *getTroubleshootingHint(NSString *errorContext) {
    if (!errorContext) return nil;
    
    NSString *context = [errorContext lowercaseString];
    
    // PDF-related errors
    if ([context containsString:@"pdf"] || [context containsString:@"document"]) {
        if ([context containsString:@"encrypted"] || [context containsString:@"password"]) {
            return @"PDF is password-protected. Try removing the password first using Preview or pdftk.";
        }
        if ([context containsString:@"corrupt"] || [context containsString:@"invalid"]) {
            return @"PDF file may be corrupted. Try opening it in Preview to verify it's readable.";
        }
        if ([context containsString:@"empty"] || [context containsString:@"no pages"]) {
            return @"PDF appears to be empty or has no pages to convert.";
        }
        return @"Verify the PDF file is valid and readable in Preview or other PDF viewers.";
    }
    
    // File I/O errors
    if ([context containsString:@"permission"] || [context containsString:@"denied"]) {
        return @"Check file permissions. You may need to use 'sudo' or change file ownership.";
    }
    if ([context containsString:@"not found"] || [context containsString:@"no such file"]) {
        return @"Verify the file path is correct and the file exists. Use absolute paths to avoid confusion.";
    }
    if ([context containsString:@"disk"] || [context containsString:@"space"]) {
        return @"Check available disk space. Large PDFs can require significant storage for conversion.";
    }
    
    // Memory errors
    if ([context containsString:@"memory"] || [context containsString:@"allocation"]) {
        return @"Try processing fewer pages at once or use a smaller scale factor to reduce memory usage.";
    }
    
    // Image/rendering errors
    if ([context containsString:@"image"] || [context containsString:@"render"]) {
        return @"Try using a smaller scale factor or lower DPI setting to reduce image complexity.";
    }
    
    // Scale/format errors
    if ([context containsString:@"scale"] || [context containsString:@"format"]) {
        return @"Use formats like '150%', '2.0', '800x600', or '300dpi'. See --help for examples.";
    }
    
    // Page range errors
    if ([context containsString:@"page"] || [context containsString:@"range"]) {
        return @"Use formats like '5' (single page), '1-10' (range), or '1,3,5-10' (list). Pages start at 1.";
    }
    
    return @"Run with -v/--verbose flag for more detailed information, or check --help for usage examples.";
}

// File locking implementation
int acquireFileLock(NSString *path, BOOL exclusive) {
    if (!path) return -1;
    
    // Create parent directory if needed
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if (![fm fileExistsAtPath:directory]) {
        if (![fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]) {
            fprintf(stderr, "Failed to create directory: %s\n", [error.localizedDescription UTF8String]);
            return -1;
        }
    }
    
    // Open the file (create if doesn't exist)
    int fd = open([path UTF8String], O_CREAT | O_WRONLY, 0644);
    if (fd == -1) {
        fprintf(stderr, "Failed to open file for locking: %s\n", strerror(errno));
        return -1;
    }
    
    // Try to acquire lock
    int lockType = exclusive ? LOCK_EX : LOCK_SH;
    if (flock(fd, lockType | LOCK_NB) == -1) {
        if (errno == EWOULDBLOCK) {
            fprintf(stderr, "File is locked by another process: %s\n", [path UTF8String]);
        } else {
            fprintf(stderr, "Failed to lock file: %s\n", strerror(errno));
        }
        close(fd);
        return -1;
    }
    
    return fd;
}

void releaseFileLock(int fd) {
    if (fd >= 0) {
        flock(fd, LOCK_UN);
        close(fd);
    }
}

BOOL writeImageToFileWithLocking(CGImageRef image, NSString *outputPath, int pngQuality, BOOL verbose, BOOL dryRun, BOOL forceOverwrite) {
    if (!image || !outputPath) return NO;
    
    if (dryRun) {
        // Original dry-run behavior
        BOOL exists = fileExists(outputPath);
        fprintf(stdout, "[DRY-RUN] Would create: %s%s\n", [outputPath UTF8String], 
                exists ? " (overwrites existing)" : "");
        
        size_t width = CGImageGetWidth(image);
        size_t height = CGImageGetHeight(image);
        size_t bitsPerPixel = CGImageGetBitsPerPixel(image);
        size_t estimatedSize = (width * height * bitsPerPixel) / 8 / 1024; // KB
        
        fprintf(stdout, "          Dimensions: %zux%zu, Estimated size: ~%zu KB\n", width, height, estimatedSize);
        return YES;
    }
    
    // Acquire exclusive lock before writing
    int lockFd = acquireFileLock(outputPath, YES);
    if (lockFd == -1) {
        reportError([NSString stringWithFormat:@"Cannot write to %@ - file is locked", outputPath],
                   @"Wait for other processes to finish or check file permissions");
        return NO;
    }
    
    // Check for overwrite protection (after acquiring lock)
    if (!forceOverwrite && fileExists(outputPath)) {
        // We need to release the lock before prompting
        releaseFileLock(lockFd);
        
        if (!shouldOverwriteFile(outputPath, YES)) {
            logMessage(verbose, @"Skipping %@ - file exists and overwrite denied", outputPath);
            return NO;
        }
        
        // Re-acquire lock after prompt
        lockFd = acquireFileLock(outputPath, YES);
        if (lockFd == -1) {
            reportError([NSString stringWithFormat:@"Lost lock on %@ after prompt", outputPath],
                       @"Another process may have acquired the file");
            return NO;
        }
    }
    
    // Now perform the actual write
    BOOL success = writeImageToFile(image, outputPath, pngQuality, verbose, NO, YES); // forceOverwrite=YES since we already checked
    
    // Release lock
    releaseFileLock(lockFd);
    
    return success;
}
