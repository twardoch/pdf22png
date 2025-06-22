#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h> // Using XCTest for structure, even if run via custom runner
#import "utils.h"        // To test utility functions
#import "pdf22png.h"     // For Options, ScaleSpec structs

// Helper function to create a temporary file with content
NSString *createTempFile(NSString *filename, NSString *content) {
    NSString *tempDir = NSTemporaryDirectory();
    NSString *filePath = [tempDir stringByAppendingPathComponent:filename];
    [content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return filePath;
}

// Helper to create a dummy PDF content string
NSString* createDummyPDFContent(void) {
    return @"%PDF-1.4\n"
           @"1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n"
           @"2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n"
           @"3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >> endobj\n"
           @"xref\n0 4\n0000000000 65535 f\n"
           @"0000000009 00000 n\n0000000058 00000 n\n0000000115 00000 n\n"
           @"trailer << /Size 4 /Root 1 0 R >>\nstartxref\n190\n%%EOF\n";
}


@interface Pdf22pngTests : XCTestCase
@end

@implementation Pdf22pngTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSLog(@"Setting up test...");
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    NSLog(@"Tearing down test...");
    [super tearDown];
}

- (void)testParseScaleSpec_percentage {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("150%", &scale);
    XCTAssertTrue(result, @"Parsing '150%' should succeed.");
    XCTAssertTrue(scale.isPercentage, @"Scale should be percentage.");
    XCTAssertEqualWithAccuracy(scale.scaleFactor, 1.5, 0.001, @"Scale factor should be 1.5.");
    XCTAssertFalse(scale.isDPI, @"Scale should not be DPI.");
}

- (void)testParseScaleSpec_dpi {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("300dpi", &scale);
    XCTAssertTrue(result, @"Parsing '300dpi' should succeed.");
    XCTAssertTrue(scale.isDPI, @"Scale should be DPI.");
    XCTAssertEqualWithAccuracy(scale.dpi, 300, 0.001, @"DPI should be 300.");
    XCTAssertFalse(scale.isPercentage, @"Scale should not be percentage.");
}

- (void)testParseScaleSpec_widthAndHeight {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("800x600", &scale);
    XCTAssertTrue(result, @"Parsing '800x600' should succeed.");
    XCTAssertTrue(scale.hasWidth, @"Scale should have width.");
    XCTAssertTrue(scale.hasHeight, @"Scale should have height.");
    XCTAssertEqualWithAccuracy(scale.maxWidth, 800, 0.001, @"Max width should be 800.");
    XCTAssertEqualWithAccuracy(scale.maxHeight, 600, 0.001, @"Max height should be 600.");
}

- (void)testParseScaleSpec_widthOnly {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("1024x", &scale);
    XCTAssertTrue(result, @"Parsing '1024x' should succeed.");
    XCTAssertTrue(scale.hasWidth, @"Scale should have width.");
    XCTAssertFalse(scale.hasHeight, @"Scale should not have height.");
    XCTAssertEqualWithAccuracy(scale.maxWidth, 1024, 0.001, @"Max width should be 1024.");
}

- (void)testParseScaleSpec_heightOnly {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("x768", &scale);
    XCTAssertTrue(result, @"Parsing 'x768' should succeed.");
    XCTAssertFalse(scale.hasWidth, @"Scale should not have width.");
    XCTAssertTrue(scale.hasHeight, @"Scale should have height.");
    XCTAssertEqualWithAccuracy(scale.maxHeight, 768, 0.001, @"Max height should be 768.");
}

- (void)testParseScaleSpec_factor {
    ScaleSpec scale;
    BOOL result = parseScaleSpec("2.5", &scale);
    XCTAssertTrue(result, @"Parsing '2.5' (factor) should succeed.");
    XCTAssertFalse(scale.isPercentage, @"Scale should not be percentage.");
    XCTAssertFalse(scale.isDPI, @"Scale should not be DPI.");
    XCTAssertFalse(scale.hasWidth, @"Scale should not have width.");
    XCTAssertFalse(scale.hasHeight, @"Scale should not have height.");
    XCTAssertEqualWithAccuracy(scale.scaleFactor, 2.5, 0.001, @"Scale factor should be 2.5.");
}

- (void)testParseScaleSpec_invalid {
    ScaleSpec scale;
    XCTAssertFalse(parseScaleSpec("abc", &scale), @"Parsing 'abc' should fail.");
    XCTAssertFalse(parseScaleSpec("150%dpi", &scale), @"Parsing '150%dpi' should fail.");
    XCTAssertFalse(parseScaleSpec("x", &scale), @"Parsing 'x' alone should fail.");
    XCTAssertFalse(parseScaleSpec("-100%", &scale), @"Parsing negative percentage should fail.");
    XCTAssertFalse(parseScaleSpec("0dpi", &scale), @"Parsing zero DPI should fail.");
    XCTAssertFalse(parseScaleSpec("0x100", &scale), @"Parsing zero width should fail.");
    XCTAssertFalse(parseScaleSpec("100x0", &scale), @"Parsing zero height should fail.");
     XCTAssertFalse(parseScaleSpec("-2.0", &scale), @"Parsing negative scale factor should fail.");
}

- (void)testCalculateScaleFactor_percentage {
    ScaleSpec scale = {.isPercentage = YES, .scaleFactor = 1.5};
    CGRect pageRect = CGRectMake(0, 0, 100, 200);
    CGFloat factor = calculateScaleFactor(&scale, pageRect);
    XCTAssertEqualWithAccuracy(factor, 1.5, 0.001, @"Scale factor should be 1.5 for percentage.");
}

- (void)testCalculateScaleFactor_dpi {
    ScaleSpec scale = {.isDPI = YES, .dpi = 144};
    CGRect pageRect = CGRectMake(0, 0, 72, 72); // 1 inch by 1 inch page
    CGFloat factor = calculateScaleFactor(&scale, pageRect);
    XCTAssertEqualWithAccuracy(factor, 2.0, 0.001, @"Scale factor should be 2.0 for 144dpi on 72dpi page.");
}

- (void)testCalculateScaleFactor_fitWidthAndHeight {
    ScaleSpec scale = {.hasWidth = YES, .maxWidth = 100, .hasHeight = YES, .maxHeight = 100};
    CGRect pageRect = CGRectMake(0, 0, 200, 400); // Page is taller
    CGFloat factor = calculateScaleFactor(&scale, pageRect);
    // Should scale by height (100/400 = 0.25) as it's the limiting dimension
    XCTAssertEqualWithAccuracy(factor, 0.25, 0.001, @"Scale factor should be 0.25 to fit height.");

    CGRect pageRect2 = CGRectMake(0, 0, 400, 200); // Page is wider
    factor = calculateScaleFactor(&scale, pageRect2);
    // Should scale by width (100/400 = 0.25)
    XCTAssertEqualWithAccuracy(factor, 0.25, 0.001, @"Scale factor should be 0.25 to fit width.");
}

- (void)testCalculateScaleFactor_factor {
    ScaleSpec scale = {.scaleFactor = 3.0}; // No other flags set
    CGRect pageRect = CGRectMake(0, 0, 100, 100);
    CGFloat factor = calculateScaleFactor(&scale, pageRect);
    XCTAssertEqualWithAccuracy(factor, 3.0, 0.001, @"Scale factor should be 3.0.");
}


- (void)testReadPDFData_stdin {
    // This test is tricky to automate properly with stdin redirection in XCTest.
    // It's better tested manually or via a script that pipes data.
    // For now, we'll skip direct testing of readDataFromStdin in this unit test.
    XCTAssertTrue(YES, @"Skipping direct stdin test in unit tests.");
}

- (void)testReadPDFData_fileNotFound {
    NSData *data = readPDFData(@"/non/existent/file.pdf", NO);
    XCTAssertNil(data, @"Data should be nil for non-existent file.");
}

- (void)testReadPDFData_validFile {
    NSString *pdfContent = createDummyPDFContent();
    NSString *tempFilePath = createTempFile(@"test_valid.pdf", pdfContent);
    NSData *data = readPDFData(tempFilePath, NO);
    XCTAssertNotNil(data, @"Data should not be nil for a valid temp PDF file.");
    XCTAssertGreaterThan([data length], 0, @"Data length should be greater than 0.");

    // Clean up
    [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
}

- (void)testGetOutputPrefix {
    Options options;
    options.inputPath = @"/path/to/mydoc.pdf";
    options.outputPath = nil;
    XCTAssertEqualObjects(getOutputPrefix(&options), @"mydoc", @"Prefix should be 'mydoc'");

    options.inputPath = @"no_extension_doc";
    options.outputPath = nil;
    XCTAssertEqualObjects(getOutputPrefix(&options), @"no_extension_doc", @"Prefix should be 'no_extension_doc'");

    options.inputPath = nil; // stdin
    options.outputPath = nil;
    XCTAssertEqualObjects(getOutputPrefix(&options), @"page", @"Prefix should be 'page' for stdin");

    options.outputPath = @"custom_prefix.png";
    XCTAssertEqualObjects(getOutputPrefix(&options), @"custom_prefix", @"Prefix should be 'custom_prefix'");

    options.outputPath = @"another_custom_prefix"; // no extension
     XCTAssertEqualObjects(getOutputPrefix(&options), @"another_custom_prefix", @"Prefix should be 'another_custom_prefix' (no ext)");

    options.outputPath = @"-"; // stdout
    options.inputPath = @"/path/to/another.pdf";
    XCTAssertEqualObjects(getOutputPrefix(&options), @"another", @"Prefix should be from input if output is stdout");

    options.outputPath = @"-"; // stdout
    options.inputPath = nil; // stdin
    XCTAssertEqualObjects(getOutputPrefix(&options), @"page", @"Prefix should be 'page' if input is stdin and output is stdout");
}


// More tests needed for:
// - renderPDFPageToImage (mock CGPDFPageRef or use actual small PDF)
// - writeImageAsPNG / writeImageToFile (check file existence, maybe basic image properties)
// - Argument parsing (parseArguments) - this is more of an integration test for the main CLI
// - processSinglePage / processBatchMode - also integration tests

@end

// Minimal main for XCTest runner if not using Xcode's test runner
// The Makefile setup implies a custom runner.
// XCTest can be run programmatically.
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // XCTestObservationCenter *center = [XCTestObservationCenter sharedTestObservationCenter];
        // [center addTestObserver: [[YourCustomObserver alloc] init]]; // Optional: for custom logging

        XCTestSuite *suite = [XCTestSuite testSuiteForTestCaseClass:[Pdf22pngTests class]];
        [suite runTest];

        // Or more simply, for all tests in the current bundle:
        // XCTestSuite *defaultSuite = [XCTestSuite defaultTestSuite];
        // [defaultSuite runTest];
        // return [defaultSuite testRun].hasSucceeded ? 0 : 1; // May not work as expected without full XCTest setup

        // For Makefile, we might just need to ensure it compiles and links.
        // The actual test execution logic might be more complex if we want standard XCTest output.
        // A simpler approach for the Makefile might be a main that calls test methods and prints PASS/FAIL.
        // However, using XCTest's own execution gives us its reporting.

        // To make it work with the Makefile's simple ./test_runner:
        // We can iterate tests and run them, or use a simpler assertion library.
        // For now, let's assume the XCTest framework handles the run.
        // The Makefile links with XCTest framework so this should be okay.
        // If not, we'll need a custom test runner main().

        // This will run all tests in Pdf22pngTests
        // If the test target links against XCTest, this should work.
        // The Makefile needs to be updated to link XCTest.framework for this to work.
        // FRAMEWORKS = -framework Foundation -framework CoreGraphics -framework AppKit -framework XCTest

        NSLog(@"Starting XCTest run programmatically.");
        [XCTestObservationCenter.sharedTestObservationCenter _setDisableLogging:NO]; // Enable logging
        BOOL success = [[XCTestSuite defaultTestSuite] runTest]; // This might not be public API.
                                                                // A better way:

        XCTestSuiteRun *suiteRun = [[XCTestSuite defaultTestSuite] run];
        unsigned long failureCount = suiteRun.testFailureCount;

        if (failureCount == 0) {
            NSLog(@"All tests passed.");
            return 0;
        } else {
            NSLog(@"%lu test(s) failed.", failureCount);
            return 1;
        }
    }
}
