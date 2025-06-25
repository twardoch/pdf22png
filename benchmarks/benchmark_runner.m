#import <Foundation/Foundation.h>
#import "benchmark.h"

// External benchmark functions
extern BenchmarkResult benchmarkObjCImplementation(BenchmarkConfig config);

// Import Swift bridge
#if __has_include("pdf22png-Swift.h")
#import "pdf22png-Swift.h"
#endif

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"PDF22PNG Benchmark Suite");
        NSLog(@"========================\n");
        
        // Parse command line arguments
        NSString *pdfPath = nil;
        NSInteger iterations = 10;
        BOOL exportCSV = NO;
        NSString *csvPath = @"benchmark_results.csv";
        
        for (int i = 1; i < argc; i++) {
            NSString *arg = [NSString stringWithUTF8String:argv[i]];
            
            if ([arg isEqualToString:@"-h"] || [arg isEqualToString:@"--help"]) {
                NSLog(@"Usage: %s <pdf_file> [options]", argv[0]);
                NSLog(@"Options:");
                NSLog(@"  -i, --iterations <n>  Number of iterations (default: 10)");
                NSLog(@"  -o, --output <path>   Export results to CSV file");
                NSLog(@"  -h, --help           Show this help message");
                return 0;
            } else if ([arg isEqualToString:@"-i"] || [arg isEqualToString:@"--iterations"]) {
                if (i + 1 < argc) {
                    iterations = [[NSString stringWithUTF8String:argv[++i]] integerValue];
                }
            } else if ([arg isEqualToString:@"-o"] || [arg isEqualToString:@"--output"]) {
                if (i + 1 < argc) {
                    exportCSV = YES;
                    csvPath = [NSString stringWithUTF8String:argv[++i]];
                }
            } else if (!pdfPath && ![arg hasPrefix:@"-"]) {
                pdfPath = arg;
            }
        }
        
        if (!pdfPath) {
            NSLog(@"Error: Please provide a PDF file path");
            NSLog(@"Usage: %s <pdf_file> [options]", argv[0]);
            return 1;
        }
        
        // Verify PDF exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:pdfPath]) {
            NSLog(@"Error: PDF file not found: %@", pdfPath);
            return 1;
        }
        
        // Define test configurations
        NSArray<NSDictionary *> *testConfigs = @[
            @{@"name": @"SinglePage_Default", @"pages": @1, @"scale": @1.0, @"dpi": @144, @"transparent": @NO},
            @{@"name": @"SinglePage_HighDPI", @"pages": @1, @"scale": @1.0, @"dpi": @300, @"transparent": @NO},
            @{@"name": @"SinglePage_Scaled", @"pages": @1, @"scale": @2.0, @"dpi": @144, @"transparent": @NO},
            @{@"name": @"SinglePage_Transparent", @"pages": @1, @"scale": @1.0, @"dpi": @144, @"transparent": @YES},
            @{@"name": @"MultiPage_5", @"pages": @5, @"scale": @1.0, @"dpi": @144, @"transparent": @NO},
            @{@"name": @"MultiPage_10", @"pages": @10, @"scale": @1.0, @"dpi": @144, @"transparent": @NO},
        ];
        
        NSMutableArray<BenchmarkReport *> *allReports = [NSMutableArray array];
        
        // Run benchmarks for each configuration
        for (NSDictionary *testConfig in testConfigs) {
            NSLog(@"\nRunning test: %@", testConfig[@"name"]);
            NSLog(@"Configuration: %ld pages, %.1fx scale, %.0f DPI, transparent: %@",
                  [testConfig[@"pages"] integerValue],
                  [testConfig[@"scale"] doubleValue],
                  [testConfig[@"dpi"] doubleValue],
                  [testConfig[@"transparent"] boolValue] ? @"YES" : @"NO");
            
            BenchmarkConfig config = {
                .name = testConfig[@"name"],
                .pdfPath = pdfPath,
                .pageCount = [testConfig[@"pages"] integerValue],
                .scaleFactor = [testConfig[@"scale"] doubleValue],
                .dpi = [testConfig[@"dpi"] doubleValue],
                .transparent = [testConfig[@"transparent"] boolValue],
                .iterations = iterations
            };
            
            // Benchmark Objective-C implementation
            NSLog(@"  Testing Objective-C implementation...");
            BenchmarkResult objcResult = benchmarkObjCImplementation(config);
            
            BenchmarkReport *objcReport = [[BenchmarkReport alloc] init];
            objcReport.implementation = @"Objective-C";
            objcReport.testName = testConfig[@"name"];
            objcReport.config = config;
            objcReport.result = objcResult;
            
            printBenchmarkReport(objcReport);
            [allReports addObject:objcReport];
            
            // Benchmark Swift implementation if available
#if __has_include("pdf22png-Swift.h")
            NSLog(@"  Testing Swift implementation...");
            BenchmarkResult swiftResult = [SwiftBenchmarkBridge benchmarkSwiftImplementationWithConfig:config];
            
            BenchmarkReport *swiftReport = [[BenchmarkReport alloc] init];
            swiftReport.implementation = @"Swift";
            swiftReport.testName = testConfig[@"name"];
            swiftReport.config = config;
            swiftReport.result = swiftResult;
            
            printBenchmarkReport(swiftReport);
            [allReports addObject:swiftReport];
            
            // Calculate performance difference
            if (objcResult.averageTime > 0 && swiftResult.averageTime > 0) {
                double speedup = objcResult.averageTime / swiftResult.averageTime;
                NSLog(@"Performance comparison: Swift is %.2fx %@ than Objective-C",
                      speedup > 1 ? speedup : 1/speedup,
                      speedup > 1 ? @"faster" : @"slower");
            }
#else
            NSLog(@"  Swift implementation not available (compile with Swift support)");
#endif
        }
        
        // Summary
        NSLog(@"\n=== BENCHMARK SUMMARY ===");
        NSLog(@"Total tests run: %lu", (unsigned long)allReports.count);
        
        // Group by implementation
        NSMutableDictionary *implStats = [NSMutableDictionary dictionary];
        
        for (BenchmarkReport *report in allReports) {
            NSMutableDictionary *stats = implStats[report.implementation];
            if (!stats) {
                stats = [NSMutableDictionary dictionary];
                stats[@"totalTime"] = @0;
                stats[@"successCount"] = @0;
                stats[@"totalCount"] = @0;
                implStats[report.implementation] = stats;
            }
            
            stats[@"totalTime"] = @([stats[@"totalTime"] doubleValue] + report.result.totalTime);
            stats[@"successCount"] = @([stats[@"successCount"] integerValue] + report.result.successCount);
            stats[@"totalCount"] = @([stats[@"totalCount"] integerValue] + 
                                    report.result.successCount + report.result.failureCount);
        }
        
        for (NSString *impl in implStats) {
            NSDictionary *stats = implStats[impl];
            NSLog(@"\n%@ Implementation:", impl);
            NSLog(@"  Total processing time: %.3f seconds", [stats[@"totalTime"] doubleValue]);
            NSLog(@"  Overall success rate: %.1f%%", 
                  100.0 * [stats[@"successCount"] doubleValue] / [stats[@"totalCount"] doubleValue]);
        }
        
        // Export results if requested
        if (exportCSV) {
            exportBenchmarkResults(allReports, csvPath);
        }
        
        NSLog(@"\nBenchmark completed!");
    }
    return 0;
}