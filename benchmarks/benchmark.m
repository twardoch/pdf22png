#import "benchmark.h"

@implementation BenchmarkReport
@end

double getCurrentTimeInSeconds(void) {
    static mach_timebase_info_data_t timebase;
    if (timebase.denom == 0) {
        mach_timebase_info(&timebase);
    }
    
    uint64_t time = mach_absolute_time();
    return (double)time * timebase.numer / timebase.denom / 1e9;
}

uint64_t getCurrentMemoryUsage(void) {
    struct task_basic_info info;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    
    if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &infoCount) != KERN_SUCCESS) {
        return 0;
    }
    
    return info.resident_size;
}

double calculateStandardDeviation(NSArray<NSNumber *> *values, double mean) {
    if (values.count <= 1) return 0.0;
    
    double sumSquaredDiff = 0.0;
    for (NSNumber *value in values) {
        double diff = value.doubleValue - mean;
        sumSquaredDiff += diff * diff;
    }
    
    return sqrt(sumSquaredDiff / (values.count - 1));
}

void printBenchmarkReport(BenchmarkReport *report) {
    NSLog(@"\n=== Benchmark Report ===");
    NSLog(@"Implementation: %@", report.implementation);
    NSLog(@"Test Name: %@", report.testName);
    NSLog(@"PDF: %@", report.config.pdfPath);
    NSLog(@"Pages: %ld", (long)report.config.pageCount);
    NSLog(@"Scale: %.2fx, DPI: %.0f, Transparent: %@", 
          report.config.scaleFactor, 
          report.config.dpi,
          report.config.transparent ? @"YES" : @"NO");
    NSLog(@"Iterations: %ld", (long)report.config.iterations);
    NSLog(@"\nResults:");
    NSLog(@"  Total Time: %.3f seconds", report.result.totalTime);
    NSLog(@"  Average Time: %.3f seconds", report.result.averageTime);
    NSLog(@"  Min Time: %.3f seconds", report.result.minTime);
    NSLog(@"  Max Time: %.3f seconds", report.result.maxTime);
    NSLog(@"  Std Dev: %.3f seconds", report.result.stdDev);
    NSLog(@"  Peak Memory: %.2f MB", report.result.memoryPeak / (1024.0 * 1024.0));
    NSLog(@"  Success Rate: %ld/%ld (%.1f%%)", 
          (long)report.result.successCount,
          (long)(report.result.successCount + report.result.failureCount),
          100.0 * report.result.successCount / (report.result.successCount + report.result.failureCount));
    NSLog(@"=======================\n");
}

void exportBenchmarkResults(NSArray<BenchmarkReport *> *reports, NSString *outputPath) {
    NSMutableString *csv = [NSMutableString string];
    
    // CSV header
    [csv appendString:@"Implementation,Test,PDF,Pages,Scale,DPI,Transparent,Iterations,"];
    [csv appendString:@"TotalTime,AvgTime,MinTime,MaxTime,StdDev,PeakMemoryMB,SuccessRate\n"];
    
    // CSV data
    for (BenchmarkReport *report in reports) {
        [csv appendFormat:@"%@,%@,%@,%ld,%.2f,%.0f,%@,%ld,",
            report.implementation,
            report.testName,
            [report.config.pdfPath lastPathComponent],
            (long)report.config.pageCount,
            report.config.scaleFactor,
            report.config.dpi,
            report.config.transparent ? @"YES" : @"NO",
            (long)report.config.iterations];
        
        [csv appendFormat:@"%.3f,%.3f,%.3f,%.3f,%.3f,%.2f,%.1f\n",
            report.result.totalTime,
            report.result.averageTime,
            report.result.minTime,
            report.result.maxTime,
            report.result.stdDev,
            report.result.memoryPeak / (1024.0 * 1024.0),
            100.0 * report.result.successCount / (report.result.successCount + report.result.failureCount)];
    }
    
    NSError *error = nil;
    [csv writeToFile:outputPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error writing benchmark results: %@", error);
    } else {
        NSLog(@"Benchmark results exported to: %@", outputPath);
    }
}