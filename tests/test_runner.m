#import <Foundation/Foundation.h>
#import "../src/utils.h"
#import "../src/pdf22png.h"

// Simple test framework macros
#define TEST_ASSERT(condition, message) \
    if (!(condition)) { \
        NSLog(@"FAIL: %s - %@", __FUNCTION__, message); \
        return NO; \
    }

#define TEST_ASSERT_EQUAL(actual, expected, message) \
    if ((actual) != (expected)) { \
        NSLog(@"FAIL: %s - %@. Expected: %@, Actual: %@", __FUNCTION__, message, @(expected), @(actual)); \
        return NO; \
    }

#define TEST_ASSERT_EQUAL_FLOAT(actual, expected, accuracy, message) \
    if (fabs((actual) - (expected)) > (accuracy)) { \
        NSLog(@"FAIL: %s - %@. Expected: %f, Actual: %f", __FUNCTION__, message, (expected), (actual)); \
        return NO; \
    }

// Test function declarations
BOOL testParseScaleSpec_percentage(void);
BOOL testParseScaleSpec_factor(void);
BOOL testParseScaleSpec_dpi(void);
BOOL testParseScaleSpec_dimensions(void);
BOOL testParseScaleSpec_invalid(void);
BOOL testParsePageRange(void);
BOOL testExtractTextFromPDFPage(void);
BOOL testFileExists(void);
BOOL testShouldOverwriteFile(void);

// Test implementations
BOOL testParseScaleSpec_percentage(void) {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("150%", &scale);
    TEST_ASSERT(result, @"Parsing '150%' should succeed");
    TEST_ASSERT(scale.isPercentage, @"Scale should be percentage");
    TEST_ASSERT_EQUAL_FLOAT(scale.scaleFactor, 1.5, 0.001, @"Scale factor should be 1.5");
    TEST_ASSERT(!scale.isDPI, @"Scale should not be DPI");
    return YES;
}

BOOL testParseScaleSpec_factor(void) {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("2.0", &scale);
    TEST_ASSERT(result, @"Parsing '2.0' should succeed");
    TEST_ASSERT(!scale.isPercentage, @"Scale should not be percentage");
    TEST_ASSERT_EQUAL_FLOAT(scale.scaleFactor, 2.0, 0.001, @"Scale factor should be 2.0");
    return YES;
}

BOOL testParseScaleSpec_dpi(void) {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("300dpi", &scale);
    TEST_ASSERT(result, @"Parsing '300dpi' should succeed");
    TEST_ASSERT(scale.isDPI, @"Scale should be DPI");
    TEST_ASSERT_EQUAL_FLOAT(scale.dpi, 300.0, 0.001, @"DPI should be 300");
    return YES;
}

BOOL testParseScaleSpec_dimensions(void) {
    ScaleSpec scale;
    
    // Test height only (pattern: "heightx")
    BOOL result = parseScaleSpec("800x", &scale);
    TEST_ASSERT(result, @"Parsing '800x' should succeed");
    TEST_ASSERT(!scale.hasWidth, @"Should not have width");
    TEST_ASSERT(scale.hasHeight, @"Should have height");
    TEST_ASSERT_EQUAL_FLOAT(scale.maxHeight, 800.0, 0.001, @"Height should be 800");
    
    // Test width only (pattern: "xwidth")
    result = parseScaleSpec("x600", &scale);
    TEST_ASSERT(result, @"Parsing 'x600' should succeed");
    TEST_ASSERT(scale.hasWidth, @"Should have width");
    TEST_ASSERT(!scale.hasHeight, @"Should not have height");
    TEST_ASSERT_EQUAL_FLOAT(scale.maxWidth, 600.0, 0.001, @"Width should be 600");
    
    // Test both dimensions (pattern: "heightxwidth")
    result = parseScaleSpec("800x600", &scale);
    TEST_ASSERT(result, @"Parsing '800x600' should succeed");
    TEST_ASSERT(scale.hasWidth, @"Should have width");
    TEST_ASSERT(scale.hasHeight, @"Should have height");
    TEST_ASSERT_EQUAL_FLOAT(scale.maxHeight, 800.0, 0.001, @"Height should be 800");
    TEST_ASSERT_EQUAL_FLOAT(scale.maxWidth, 600.0, 0.001, @"Width should be 600");
    
    return YES;
}

BOOL testParseScaleSpec_invalid(void) {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("invalid", &scale);
    TEST_ASSERT(!result, @"Parsing 'invalid' should fail");
    return YES;
}

BOOL testParsePageRange(void) {
    // Test simple single page
    NSArray *pages = parsePageRange(@"5", 10);
    TEST_ASSERT(pages != nil, @"parsePageRange should return array");
    TEST_ASSERT_EQUAL(pages.count, 1, @"Should have 1 page");
    TEST_ASSERT_EQUAL([pages[0] integerValue], 5, @"Page should be 5");
    
    // Test range
    pages = parsePageRange(@"1-3", 10);
    TEST_ASSERT(pages != nil, @"parsePageRange should return array");
    TEST_ASSERT_EQUAL(pages.count, 3, @"Should have 3 pages");
    TEST_ASSERT_EQUAL([pages[0] integerValue], 1, @"First page should be 1");
    TEST_ASSERT_EQUAL([pages[2] integerValue], 3, @"Last page should be 3");
    
    // Test comma separated
    pages = parsePageRange(@"1,3,5", 10);
    TEST_ASSERT(pages != nil, @"parsePageRange should return array");
    TEST_ASSERT_EQUAL(pages.count, 3, @"Should have 3 pages");
    TEST_ASSERT_EQUAL([pages[1] integerValue], 3, @"Second page should be 3");
    
    // Test complex
    pages = parsePageRange(@"1-3,5,7-9", 10);
    TEST_ASSERT(pages != nil, @"parsePageRange should return array");
    TEST_ASSERT_EQUAL(pages.count, 7, @"Should have 7 pages");
    
    return YES;
}

BOOL testExtractTextFromPDFPage(void) {
    // This test would require a real PDF, so we'll just verify the function exists
    NSString *result = extractTextFromPDFPage(nil);
    TEST_ASSERT(result == nil, @"Should return nil for nil page");
    return YES;
}

BOOL testFileExists(void) {
    // Test with non-existent file
    TEST_ASSERT(!fileExists(@"/path/that/does/not/exist"), @"Should return NO for non-existent file");
    
    // Test with a file that should exist (create a temp file)
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_file.txt"];
    [@"test" writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    TEST_ASSERT(fileExists(tempPath), @"Should return YES for existing temp file");
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    
    return YES;
}

BOOL testShouldOverwriteFile(void) {
    // Test with non-existent file
    TEST_ASSERT(shouldOverwriteFile(@"/path/that/does/not/exist", NO), @"Should allow writing to non-existent file");
    TEST_ASSERT(shouldOverwriteFile(@"/path/that/does/not/exist", YES), @"Should allow writing to non-existent file");
    
    // Test with existing file in non-interactive mode
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_file2.txt"];
    [@"test" writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    TEST_ASSERT(!shouldOverwriteFile(tempPath, NO), @"Should not overwrite existing file in non-interactive mode");
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    
    return YES;
}

// Main test runner
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"Running pdf22png tests...");
        
        int passed = 0;
        int failed = 0;
        
        // Define test cases
        typedef BOOL (*TestFunction)(void);
        typedef struct {
            const char *name;
            TestFunction func;
        } TestCase;
        
        TestCase tests[] = {
            {"testParseScaleSpec_percentage", testParseScaleSpec_percentage},
            {"testParseScaleSpec_factor", testParseScaleSpec_factor},
            {"testParseScaleSpec_dpi", testParseScaleSpec_dpi},
            {"testParseScaleSpec_dimensions", testParseScaleSpec_dimensions},
            {"testParseScaleSpec_invalid", testParseScaleSpec_invalid},
            {"testParsePageRange", testParsePageRange},
            {"testExtractTextFromPDFPage", testExtractTextFromPDFPage},
            {"testFileExists", testFileExists},
            {"testShouldOverwriteFile", testShouldOverwriteFile},
        };
        
        int numTests = sizeof(tests) / sizeof(tests[0]);
        
        for (int i = 0; i < numTests; i++) {
            NSLog(@"Running %s...", tests[i].name);
            if (tests[i].func()) {
                NSLog(@"PASS: %s", tests[i].name);
                passed++;
            } else {
                failed++;
            }
        }
        
        NSLog(@"\n====================");
        NSLog(@"Test Results:");
        NSLog(@"  Passed: %d", passed);
        NSLog(@"  Failed: %d", failed);
        NSLog(@"  Total:  %d", passed + failed);
        NSLog(@"====================");
        
        return failed > 0 ? 1 : 0;
    }
}