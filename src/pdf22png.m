#import "pdf22png.h"
#import "utils.h"
#import <getopt.h>
#import <signal.h>

// Global variable for signal handling
static volatile sig_atomic_t g_shouldTerminate = 0;

// Signal handler for graceful shutdown
void signalHandler(int sig) {
    g_shouldTerminate = 1;
    fprintf(stderr, "\nReceived signal %d, finishing current operations...\n", sig);
}

// Define long options for getopt_long
static struct option long_options[] = {
    {"page", required_argument, 0, 'p'},
    {"all", no_argument, 0, 'a'}, // New: for batch mode without needing -d
    {"resolution", required_argument, 0, 'r'}, // Maps to -s Ndpi
    {"scale", required_argument, 0, 's'},
    {"transparent", no_argument, 0, 't'},
    {"quality", required_argument, 0, 'q'},
    {"verbose", no_argument, 0, 'v'},
    {"name", no_argument, 0, 'n'}, // Include text in filename
    {"dry-run", no_argument, 0, 'D'}, // Preview operations without writing
    {"help", no_argument, 0, 'h'},
    {"output", required_argument, 0, 'o'}, // For consistency with other tools
    {"directory", required_argument, 0, 'd'}, // For batch output directory
    {0, 0, 0, 0}
};

void printUsage(const char *programName) {
    fprintf(stderr, "Usage: %s [OPTIONS] <input.pdf> [output.png | output_%%03d.png]\n", programName);
    fprintf(stderr, "Converts PDF documents to PNG images.\n\n");
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -p, --page <spec>       Page(s) to convert. Single page, range, or comma-separated.\n");
    fprintf(stderr, "                          Examples: 1 | 1-5 | 1,3,5-10 (default: 1)\n");
    fprintf(stderr, "                          In batch mode, only specified pages are converted.\n");
    fprintf(stderr, "  -a, --all               Convert all pages. If -d is not given, uses input filename as prefix.\n");
    fprintf(stderr, "                          Output files named <prefix>-<page_num>.png.\n");
    fprintf(stderr, "  -r, --resolution <dpi>  Set output DPI (e.g., 150dpi). Overrides -s if both used with numbers.\n");
    fprintf(stderr, "  -s, --scale <spec>      Scaling specification (default: 100%% or 1.0).\n");
    fprintf(stderr, "                            NNN%%: percentage (e.g., 150%%)\n");
    fprintf(stderr, "                            N.N:  scale factor (e.g., 1.5)\n");
    fprintf(stderr, "                            WxH:  fit to WxH pixels (e.g., 800x600)\n");
    fprintf(stderr, "                            Wx:   fit to width W pixels (e.g., 1024x)\n");
    fprintf(stderr, "                            xH:   fit to height H pixels (e.g., x768)\n");
    // fprintf(stderr, "                            Ndpi: dots per inch (e.g., 300dpi) - use -r for this\n");
    fprintf(stderr, "  -t, --transparent       Preserve transparency (default: white background).\n");
    fprintf(stderr, "  -q, --quality <n>       PNG compression quality (0-9, default: 6). Currently informational.\n");
    fprintf(stderr, "  -o, --output <path>     Output PNG file or prefix for batch mode.\n");
    fprintf(stderr, "                          If '-', output to stdout (single page mode only).\n");
    fprintf(stderr, "  -d, --directory <dir>   Output directory for batch mode (converts all pages).\n");
    fprintf(stderr, "                          If used, -o specifies filename prefix inside this directory.\n");
    fprintf(stderr, "  -v, --verbose           Verbose output.\n");
    fprintf(stderr, "  -n, --name              Include extracted text in output filename (batch mode only).\n");
    fprintf(stderr, "  -D, --dry-run           Preview operations without writing files.\n");
    fprintf(stderr, "  -h, --help              Show this help message and exit.\n\n");
    fprintf(stderr, "Arguments:\n");
    fprintf(stderr, "  <input.pdf>             Input PDF file. If '-', reads from stdin.\n");
    fprintf(stderr, "  [output.png]            Output PNG file. Required if not using -o or -d.\n");
    fprintf(stderr, "                          If input is stdin and output is not specified, output goes to stdout.\n");
    fprintf(stderr, "                          In batch mode (-a or -d), this is used as a prefix if -o is not set.\n");
}

Options parseArguments(int argc, const char *argv[]) {
    Options options = {
        .scale = {.scaleFactor = 1.0, .isPercentage = YES, .dpi = 144}, // Default DPI is 144 from README
        .pageNumber = 1,
        .inputPath = nil,
        .outputPath = nil,
        .outputDirectory = nil,
        .batchMode = NO,
        .transparentBackground = NO,
        .pngQuality = 6, // Default PNG quality
        .verbose = NO,
        .includeText = NO,
        .pageRange = nil,
        .dryRun = NO
    };

    int opt;
    int option_index = 0;
    BOOL scale_explicitly_set = NO;
    BOOL resolution_explicitly_set = NO;

    // Suppress getopt's default error messages
    // opterr = 0;

    while ((opt = getopt_long(argc, (char *const *)argv, "p:ar:s:tq:o:d:vnDh", long_options, &option_index)) != -1) {
        switch (opt) {
            case 'p': {
                options.pageRange = [NSString stringWithUTF8String:optarg];
                // For single page mode compatibility, try to parse as simple number
                NSScanner *scanner = [NSScanner scannerWithString:options.pageRange];
                NSInteger singlePage;
                if ([scanner scanInteger:&singlePage] && [scanner isAtEnd]) {
                    options.pageNumber = singlePage;
                    if (options.pageNumber < 1) {
                        fprintf(stderr, "Error: Invalid page number: %s. Must be >= 1.\n", optarg);
                        exit(1);
                    }
                } else {
                    // It's a range or list, will be parsed later
                    options.pageNumber = 0; // Indicates range mode
                }
                break;
            }
            case 'a':
                options.batchMode = YES;
                break;
            case 'r': {
                NSString* resStr = [NSString stringWithUTF8String:optarg];
                if (![resStr hasSuffix:@"dpi"]) { // Ensure it's passed as Ndpi, or assume dpi
                    resStr = [resStr stringByAppendingString:@"dpi"];
                }
                if (!parseScaleSpec([resStr UTF8String], &options.scale)) {
                    fprintf(stderr, "Error: Invalid resolution specification: %s\n", optarg);
                    printUsage(argv[0]);
                    exit(1);
                }
                resolution_explicitly_set = YES;
                break;
            }
            case 's':
                if (!parseScaleSpec(optarg, &options.scale)) {
                    fprintf(stderr, "Error: Invalid scale specification: %s\n", optarg);
                    printUsage(argv[0]);
                    exit(1);
                }
                scale_explicitly_set = YES;
                break;
            case 't':
                options.transparentBackground = YES;
                break;
            case 'q':
                options.pngQuality = atoi(optarg);
                if (options.pngQuality < 0 || options.pngQuality > 9) {
                    fprintf(stderr, "Error: Invalid PNG quality: %s. Must be between 0 and 9.\n", optarg);
                    exit(1);
                }
                break;
            case 'o':
                options.outputPath = [NSString stringWithUTF8String:optarg];
                break;
            case 'd':
                options.outputDirectory = [NSString stringWithUTF8String:optarg];
                options.batchMode = YES; // -d implies batch mode
                break;
            case 'v':
                options.verbose = YES;
                break;
            case 'n':
                options.includeText = YES;
                break;
            case 'D':
                options.dryRun = YES;
                break;
            case 'h':
                printUsage(argv[0]);
                exit(0);
            case '?': // Unknown option or missing argument
                // getopt_long already prints an error message if opterr is not 0
                // fprintf(stderr, "Error: Unknown option or missing argument.\n");
                printUsage(argv[0]);
                exit(1);
            default:
                // Should not happen
                abort();
        }
    }

    logMessage(options.verbose, @"Finished parsing options.");

    // Handle conflicting scale/resolution. Resolution (-r) takes precedence.
    if (resolution_explicitly_set && scale_explicitly_set && !options.scale.isDPI) {
        // If -r was set, options.scale is already DPI based.
        // If -s was also set but not as DPI, -r (DPI) wins.
        // If -s was also set as DPI, the last one parsed wins, which is fine.
        logMessage(options.verbose, @"Both -r (resolution) and -s (scale) were specified. Using resolution (-r %fdpi).", options.scale.dpi);
    } else if (!resolution_explicitly_set && !scale_explicitly_set) {
        // Neither -r nor -s set, use default DPI of 144
        logMessage(options.verbose, @"No scale or resolution specified, using default %fdpi.", options.scale.dpi);
        // Ensure scale is set to DPI based for default
        char defaultDpiStr[16];
        snprintf(defaultDpiStr, sizeof(defaultDpiStr), "%ddpi", (int)options.scale.dpi);
        parseScaleSpec(defaultDpiStr, &options.scale);
    }


    // Handle positional arguments (input and output files)
    int num_remaining_args = argc - optind;
    logMessage(options.verbose, @"Number of remaining arguments: %d", num_remaining_args);

    if (num_remaining_args == 0 && isatty(fileno(stdin))) {
         fprintf(stderr, "Error: Input PDF file required, or pipe from stdin.\n");
         printUsage(argv[0]);
         exit(1);
    }

    // Input file
    if (num_remaining_args > 0) {
        NSString* first_arg = [NSString stringWithUTF8String:argv[optind]];
        if ([first_arg isEqualToString:@"-"]) {
            options.inputPath = nil; // stdin
            logMessage(options.verbose, @"Input PDF: stdin");
        } else {
            options.inputPath = first_arg;
            logMessage(options.verbose, @"Input PDF: %@", options.inputPath);
        }
        optind++;
        num_remaining_args--;
    } else { // No positional args, input must be stdin
        options.inputPath = nil; // stdin
        logMessage(options.verbose, @"Input PDF: stdin (implied)");
    }


    // Output file / prefix
    if (options.outputPath == nil) { // if -o was not used
        if (num_remaining_args > 0) {
            options.outputPath = [NSString stringWithUTF8String:argv[optind]];
            logMessage(options.verbose, @"Output path (from argument): %@", options.outputPath);
            optind++;
            num_remaining_args--;
        } else {
            // No -o and no second positional argument
            if (options.inputPath == nil && !options.batchMode) { // Input is stdin, not batch mode
                options.outputPath = @"-"; // Default to stdout
                logMessage(options.verbose, @"Output path: stdout (implied for stdin input)");
            } else if (options.batchMode && options.outputDirectory == nil) {
                // Batch mode, no -d, no -o, no output arg. Use input filename as prefix.
                // This case is handled by getOutputPrefix if options.outputPath is nil.
                logMessage(options.verbose, @"Batch mode: Output prefix will be derived from input filename or default to 'page'.");
            } else if (!options.batchMode && options.inputPath != nil) {
                 fprintf(stderr, "Error: Output PNG file required when input is a file and not in batch mode.\n");
                 printUsage(argv[0]);
                 exit(1);
            }
        }
    } else {
        logMessage(options.verbose, @"Output path (from -o): %@", options.outputPath);
    }

    if (num_remaining_args > 0) {
        fprintf(stderr, "Error: Too many arguments.\n");
        printUsage(argv[0]);
        exit(1);
    }

    // Final checks for batch mode
    if (options.batchMode) {
        if ([options.outputPath isEqualToString:@"-"]) {
            fprintf(stderr, "Error: Cannot output to stdout in batch mode.\n");
            exit(1);
        }
        if (options.outputDirectory == nil) {
            // If -d is not specified, output to current directory
            options.outputDirectory = @".";
            logMessage(options.verbose, @"Batch mode: Output directory not specified, using current directory '.'");
        }
        // If outputPath was not set by -o or positional arg, getOutputPrefix will use input name or "page"
        // If outputPath was set, it's the prefix.
    } else { // Single page mode
        if (options.outputDirectory != nil) {
            fprintf(stderr, "Error: -d/--directory is only for batch mode (-a/--all).\n");
            exit(1);
        }
    }

    logMessage(options.verbose, @"Final Options: pageNumber=%ld, batchMode=%s, transparent=%s, quality=%d, verbose=%s",
        (long)options.pageNumber, options.batchMode?"YES":"NO",
        options.transparentBackground?"YES":"NO", options.pngQuality, options.verbose?"YES":"NO");
    logMessage(options.verbose, @"ScaleSpec: factor=%.2f, dpi=%.2f, w=%.0f, h=%.0f, %%=%s, dpi_set=%s, w_set=%s, h_set=%s",
        options.scale.scaleFactor, options.scale.dpi, options.scale.maxWidth, options.scale.maxHeight,
        options.scale.isPercentage?"YES":"NO", options.scale.isDPI?"YES":"NO",
        options.scale.hasWidth?"YES":"NO", options.scale.hasHeight?"YES":"NO");


    return options;
}


BOOL processSinglePage(CGPDFDocumentRef pdfDocument, Options *options) {
    @autoreleasepool {
        logMessage(options->verbose, @"Processing single page: %ld", (long)options->pageNumber);

        size_t pageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
        if (options->pageNumber < 1 || options->pageNumber > (NSInteger)pageCount) {
            fprintf(stderr, "Error: Page %ld does not exist (document has %zu pages).\n",
                    (long)options->pageNumber, pageCount);
            return NO;
        }

        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDocument, options->pageNumber);
        if (!pdfPage) {
            fprintf(stderr, "Error: Failed to get page %ld.\n", (long)options->pageNumber);
            return NO;
        }

        CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
        CGFloat scaleFactor = calculateScaleFactor(&options->scale, pageRect);
        logMessage(options->verbose, @"Calculated scale factor for page %ld: %.2f", (long)options->pageNumber, scaleFactor);

        CGImageRef image = renderPDFPageToImage(pdfPage, scaleFactor, options->transparentBackground, options->verbose);
        if (!image) {
            fprintf(stderr, "Error: Failed to render PDF page %ld.\n", (long)options->pageNumber);
            return NO;
        }

        BOOL success;
        if (options->outputPath && [options->outputPath isEqualToString:@"-"]) {
            if (options->dryRun) {
                size_t width = CGImageGetWidth(image);
                size_t height = CGImageGetHeight(image);
                fprintf(stdout, "[DRY-RUN] Would write PNG to stdout\n");
                fprintf(stdout, "          Page: %ld, Dimensions: %zux%zu\n", (long)options->pageNumber, width, height);
                success = YES;
            } else {
                logMessage(options->verbose, @"Writing image to stdout.");
                NSFileHandle *stdoutHandle = [NSFileHandle fileHandleWithStandardOutput];
                success = writeImageAsPNG(image, stdoutHandle, options->pngQuality, options->verbose);
            }
        } else if (options->outputPath) {
            logMessage(options->verbose, @"Writing image to file: %@", options->outputPath);
            success = writeImageToFile(image, options->outputPath, options->pngQuality, options->verbose, options->dryRun);
        } else {
            // This case should ideally be caught by argument parsing, means no output specified
            fprintf(stderr, "Error: Output path not specified for single page mode.\n");
            success = NO;
        }

        CGImageRelease(image);
        return success;
    }
}

BOOL processBatchMode(CGPDFDocumentRef pdfDocument, Options *options) {
    logMessage(options->verbose, @"Processing in batch mode. Output directory: %@", options->outputDirectory);

    if (options->dryRun) {
        fprintf(stdout, "[DRY-RUN] Would create directory: %s\n", [options->outputDirectory UTF8String]);
    } else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        if (![fileManager createDirectoryAtPath:options->outputDirectory
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error]) {
            fprintf(stderr, "Error: Failed to create output directory '%s': %s\n",
                    [options->outputDirectory UTF8String],
                    [[error localizedDescription] UTF8String]);
            return NO;
        }
    }

    size_t totalPageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
    NSString *prefix = getOutputPrefix(options); // Handles nil outputPath for prefix generation
    logMessage(options->verbose, @"Using output prefix: %@", prefix);
    
    // Determine which pages to process
    NSArray<NSNumber *> *pagesToProcess;
    if (options->pageRange) {
        pagesToProcess = parsePageRange(options->pageRange, totalPageCount);
        if (!pagesToProcess || pagesToProcess.count == 0) {
            fprintf(stderr, "Error: Invalid page range specification: %s\n", [options->pageRange UTF8String]);
            return NO;
        }
        logMessage(options->verbose, @"Processing %lu pages from range: %@", 
                   (unsigned long)pagesToProcess.count, options->pageRange);
    } else {
        // Process all pages
        NSMutableArray *allPages = [NSMutableArray arrayWithCapacity:totalPageCount];
        for (size_t i = 1; i <= totalPageCount; i++) {
            [allPages addObject:@(i)];
        }
        pagesToProcess = allPages;
        logMessage(options->verbose, @"Processing all %zu pages", totalPageCount);
    }

    __block volatile NSInteger successCount = 0;
    __block volatile NSInteger failCount = 0;
    __block volatile NSInteger processedCount = 0;
    NSObject *lock = [[NSObject alloc] init]; // For thread-safe modification of counters

    logMessage(options->verbose, @"Starting batch conversion of %lu pages...", 
               (unsigned long)pagesToProcess.count);

    dispatch_apply(pagesToProcess.count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        // Check for termination signal
        if (g_shouldTerminate) {
            return;
        }
        
        // Continue processing even if other pages fail
        size_t pageNum = [pagesToProcess[i] unsignedIntegerValue];
        logMessage(options->verbose, @"Starting processing for page %zu...", pageNum);

        @autoreleasepool {
            CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDocument, pageNum);
            if (!pdfPage) {
                fprintf(stderr, "Warning: Failed to get page %zu, skipping.\n", pageNum);
                @synchronized(lock) { 
                    failCount++; 
                    processedCount++;
                }
                return;
            }

            CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
            CGFloat scaleFactor = calculateScaleFactor(&options->scale, pageRect);
            logMessage(options->verbose, @"Calculated scale factor for page %zu: %.2f", pageNum, scaleFactor);

            CGImageRef image = renderPDFPageToImage(pdfPage, scaleFactor, options->transparentBackground, options->verbose);
            if (!image) {
                fprintf(stderr, "Warning: Failed to render page %zu, skipping.\n", pageNum);
                @synchronized(lock) { 
                    failCount++; 
                    processedCount++;
                }
                return;
            }

            NSString *filename;
            if (options->includeText) {
                // Extract text from PDF page first
                NSString *pageText = extractTextFromPDFPage(pdfPage);
                
                // If no text found, try OCR
                if (!pageText || pageText.length == 0) {
                    logMessage(options->verbose, @"No text extracted from PDF, attempting OCR for page %zu", pageNum);
                    pageText = performOCROnImage(image);
                }
                
                // Generate filename with text suffix
                if (pageText && pageText.length > 0) {
                    NSString *slug = slugifyText(pageText, 30);
                    filename = [NSString stringWithFormat:@"%@-%03zu--%@.png", prefix, pageNum, slug];
                    logMessage(options->verbose, @"Extracted text for page %zu: %@", pageNum, slug);
                } else {
                    filename = [NSString stringWithFormat:@"%@-%03zu.png", prefix, pageNum];
                    logMessage(options->verbose, @"No text found for page %zu", pageNum);
                }
            } else {
                filename = [NSString stringWithFormat:@"%@-%03zu.png", prefix, pageNum];
            }
            
            NSString *outputPath = [options->outputDirectory stringByAppendingPathComponent:filename];
            logMessage(options->verbose, @"Writing image for page %zu to file: %@", pageNum, outputPath);

            if (!writeImageToFile(image, outputPath, options->pngQuality, options->verbose, options->dryRun)) {
                fprintf(stderr, "Warning: Failed to write page %zu to '%s', skipping.\n", pageNum, [outputPath UTF8String]);
                @synchronized(lock) { 
                    failCount++; 
                    processedCount++;
                }
            } else {
                @synchronized(lock) { 
                    successCount++; 
                    processedCount++;
                }
            }

            CGImageRelease(image);
            
            // Progress reporting
            @synchronized(lock) {
                if (!options->verbose && processedCount % 10 == 0) {
                    fprintf(stderr, "\rProgress: %ld/%lu pages processed", 
                            (long)processedCount, (unsigned long)pagesToProcess.count);
                    fflush(stderr);
                }
            }
            
            logMessage(options->verbose, @"Finished processing for page %zu.", pageNum);
        }
    });
    
    // Clear progress line if not in verbose mode
    if (!options->verbose) {
        fprintf(stderr, "\r%*s\r", 50, ""); // Clear the progress line
    }
    
    // Report results
    if (options->dryRun) {
        fprintf(stdout, "\n[DRY-RUN] Would convert %lu pages to PNG files\n", 
                (unsigned long)pagesToProcess.count);
    } else if (g_shouldTerminate) {
        fprintf(stderr, "Batch processing interrupted: %ld pages converted before interruption, %ld pages failed.\n", 
                (long)successCount, (long)failCount);
    } else {
        fprintf(stderr, "Batch processing complete: %ld pages converted successfully, %ld pages failed.\n", 
                (long)successCount, (long)failCount);
    }
    
    // Return success only if at least one page was converted
    return successCount > 0;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        // Install signal handlers
        signal(SIGINT, signalHandler);
        signal(SIGTERM, signalHandler);
        
        Options options = parseArguments(argc, argv);

        logMessage(options.verbose, @"Starting pdf22png tool.");

        NSData *pdfData = readPDFData(options.inputPath, options.verbose);
        if (!pdfData || [pdfData length] == 0) {
            fprintf(stderr, "Error: No PDF data received or PDF data is empty.\n");
            return 1;
        }

        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)pdfData);
        if (!provider) {
            fprintf(stderr, "Error: Failed to create PDF data provider.\n");
            return 1;
        }
        CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithProvider(provider);
        CGDataProviderRelease(provider);

        if (!pdfDocument) {
            fprintf(stderr, "Error: Failed to create PDF document. Ensure the input is a valid PDF.\n");
            return 1;
        }

        // Validate PDF document
        if (CGPDFDocumentIsEncrypted(pdfDocument)) {
            fprintf(stderr, "Error: PDF document is encrypted. Password-protected PDFs are not currently supported.\n");
            CGPDFDocumentRelease(pdfDocument);
            return 1;
        }
        
        size_t pageCount = CGPDFDocumentGetNumberOfPages(pdfDocument);
        if (pageCount == 0) {
            fprintf(stderr, "Error: PDF document has no pages.\n");
            CGPDFDocumentRelease(pdfDocument);
            return 1;
        }

        logMessage(options.verbose, @"PDF document loaded successfully. Total pages: %zu", pageCount);

        BOOL success;
        if (options.batchMode) {
            success = processBatchMode(pdfDocument, &options);
        } else {
            success = processSinglePage(pdfDocument, &options);
        }

        CGPDFDocumentRelease(pdfDocument);
        logMessage(options.verbose, @"Processing finished. Success: %s", success ? "YES" : "NO");

        return success ? 0 : 1;
    }
}