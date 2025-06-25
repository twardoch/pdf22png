# PDF22PNG Benchmark Suite

This directory contains performance benchmarks comparing the Objective-C and Swift implementations of pdf22png.

## Overview

The benchmark suite measures:
- **Conversion Speed**: Time to convert PDF pages to PNG
- **Memory Usage**: Peak memory consumption during conversion
- **Scalability**: Performance with different page counts and settings
- **Quality Settings**: Impact of DPI, scaling, and transparency options

## Quick Start

```bash
# Build both implementations and run benchmarks
make benchmark

# Run benchmarks with a specific PDF
cd benchmarks
./run_benchmarks.sh -p /path/to/your.pdf -i 20 -o results.csv
```

## Building

### Option 1: Using Make (Recommended)
```bash
# From project root
make both          # Build both ObjC and Swift implementations
make benchmark     # Build benchmark tools
```

### Option 2: Direct Build
```bash
cd benchmarks
./run_benchmarks.sh --build-only
```

## Running Benchmarks

### Basic Usage
```bash
./run_benchmarks.sh -p sample.pdf
```

### Advanced Options
```bash
./run_benchmarks.sh -p document.pdf -i 50 -o benchmark_results.csv
```

Options:
- `-p, --pdf <file>`: PDF file to benchmark (required)
- `-i, --iterations <n>`: Number of iterations per test (default: 10)
- `-o, --output <file>`: Export results to CSV file
- `--build-only`: Only build, don't run benchmarks
- `-h, --help`: Show help message

## Test Configurations

The benchmark suite runs the following test scenarios:

1. **SinglePage_Default**: Basic single page conversion at 144 DPI
2. **SinglePage_HighDPI**: Single page at 300 DPI
3. **SinglePage_Scaled**: Single page with 2x scaling
4. **SinglePage_Transparent**: Single page with transparency
5. **MultiPage_5**: Convert 5 pages
6. **MultiPage_10**: Convert 10 pages

## Creating Test PDFs

If you need a test PDF:
```bash
./create_test_pdf.sh
```

This creates a 5-page PDF with various content types for benchmarking.

## Output Format

### Console Output
The benchmark displays:
- Real-time progress for each test
- Detailed statistics per implementation
- Performance comparison (e.g., "Swift is 1.5x faster than Objective-C")

### CSV Export
Results can be exported to CSV with columns:
- Implementation (Objective-C/Swift)
- Test name
- PDF file
- Page count
- Scale factor
- DPI
- Transparency setting
- Number of iterations
- Total time
- Average time
- Min/Max time
- Standard deviation
- Peak memory usage (MB)
- Success rate

## Interpreting Results

### Performance Metrics
- **Average Time**: Best indicator of typical performance
- **Standard Deviation**: Shows consistency (lower is better)
- **Min/Max Time**: Identifies outliers and best/worst cases
- **Peak Memory**: Maximum memory used during conversion

### Common Patterns
- Swift typically shows better performance for simple conversions
- Memory usage may vary based on implementation optimizations
- High DPI conversions are memory-intensive for both implementations
- Batch conversions benefit from parallelization

## Customizing Benchmarks

### Adding New Test Configurations
Edit `benchmark_runner.m` and add to the `testConfigs` array:
```objc
@{@"name": @"YourTest", @"pages": @1, @"scale": @1.0, @"dpi": @300, @"transparent": @YES}
```

### Modifying Iterations
Increase iterations for more accurate averages:
```bash
./run_benchmarks.sh -p file.pdf -i 100
```

## Troubleshooting

### Build Failures
- Ensure Xcode Command Line Tools are installed
- Check that Swift is available: `swift --version`
- Verify all source files are present

### Runtime Issues
- Confirm PDF file exists and is readable
- Check available disk space for output files
- Monitor system memory during large batch conversions

### Swift Interop Issues
If Swift/ObjC interop fails, the benchmark will fall back to ObjC-only mode.

## Implementation Details

### Objective-C Benchmark
- Uses native pdf22png implementation
- Direct CoreGraphics calls
- Minimal overhead

### Swift Benchmark
- Uses Swift port with same functionality
- Bridges to Objective-C benchmark framework
- Measures Swift-specific optimizations

### Fair Comparison
Both implementations:
- Use the same PDF loading mechanism
- Perform identical rendering operations
- Write to temporary directories
- Clean up after each iteration