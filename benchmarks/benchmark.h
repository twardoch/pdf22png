#ifndef BENCHMARK_H
#define BENCHMARK_H

#import <Foundation/Foundation.h>
#import <mach/mach_time.h>

typedef struct {
    NSString *name;
    NSString *pdfPath;
    NSInteger pageCount;
    CGFloat scaleFactor;
    CGFloat dpi;
    BOOL transparent;
    NSInteger iterations;
} BenchmarkConfig;

typedef struct {
    double totalTime;
    double averageTime;
    double minTime;
    double maxTime;
    double stdDev;
    uint64_t memoryPeak;
    NSInteger successCount;
    NSInteger failureCount;
} BenchmarkResult;

@interface BenchmarkReport : NSObject
@property (nonatomic, strong) NSString *implementation;
@property (nonatomic, strong) NSString *testName;
@property (nonatomic) BenchmarkConfig config;
@property (nonatomic) BenchmarkResult result;
@property (nonatomic, strong) NSArray<NSNumber *> *individualTimes;
@end

// Benchmark utilities
double getCurrentTimeInSeconds(void);
uint64_t getCurrentMemoryUsage(void);
double calculateStandardDeviation(NSArray<NSNumber *> *values, double mean);
void printBenchmarkReport(BenchmarkReport *report);
void exportBenchmarkResults(NSArray<BenchmarkReport *> *reports, NSString *outputPath);

#endif /* BENCHMARK_H */