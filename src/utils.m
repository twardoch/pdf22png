#import "utils.h"

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
            fprintf(stderr, "Error: Scale percentage must be positive.\n");
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
            fprintf(stderr, "Error: DPI value must be positive.\n");
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
    BOOL scaleXSet = NO, scaleYSet = NO;

    if (scale->hasWidth && pageRect.size.width > 0) {
        scaleX = scale->maxWidth / pageRect.size.width;
        scaleXSet = YES;
    }

    if (scale->hasHeight && pageRect.size.height > 0) {
        scaleY = scale->maxHeight / pageRect.size.height;
        scaleYSet = YES;
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

    logMessage(verbose, @"Rendering PDF page with scale factor: %.2f", scaleFactor);

    // Get page dimensions
    CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
    size_t width = (size_t)round(pageRect.size.width * scaleFactor);
    size_t height = (size_t)round(pageRect.size.height * scaleFactor);

    if (width == 0 || height == 0) {
        fprintf(stderr, "Error: Calculated image dimensions are zero (width: %zu, height: %zu). Check scale factor and PDF page size.\n", width, height);
        return NULL;
    }

    // Create bitmap context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace,
                                                kCGImageAlphaPremultipliedLast); // Changed to PremultipliedLast for better transparency handling
    CGColorSpaceRelease(colorSpace);

    if (!context) {
        fprintf(stderr, "Failed to create bitmap context\n");
        return NULL;
    }

    // Set background
    if (!transparentBackground) {
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0); // White
        CGContextFillRect(context, CGRectMake(0, 0, width, height));
    } else {
        CGContextClearRect(context, CGRectMake(0, 0, width, height)); // Transparent
    }

    // Save context state
    CGContextSaveGState(context);

    // Scale and translate for PDF rendering
    CGContextScaleCTM(context, scaleFactor, scaleFactor);
    // CGContextTranslateCTM(context, -pageRect.origin.x, -pageRect.origin.y); // This might be needed if cropbox/mediabox origin is not 0,0

    // Draw PDF page
    CGContextDrawPDFPage(context, pdfPage);

    // Restore context state
    CGContextRestoreGState(context);

    // Create image from context
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    logMessage(verbose, @"Page rendered to CGImageRef successfully.");
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

BOOL writeImageToFile(CGImageRef image, NSString *outputPath, int pngQuality, BOOL verbose) {
    if (!image || !outputPath) return NO;

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
