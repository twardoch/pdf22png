//
//  UtilsTests.m
//  PDF21PNG Tests
//
//  Tests for utility functions in utils.m
//

#import <XCTest/XCTest.h>
#import "../src/utils.h"

@interface UtilsTests : XCTestCase
@end

@implementation UtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Scale Parsing Tests

- (void)testParseScalePercentage {
    CGFloat scale = 0;
    BOOL hasDPI = NO;
    CGSize dimensions = CGSizeZero;
    
    // Test percentage scaling
    BOOL result = parseScale(@"150%", &scale, &hasDPI, &dimensions);
    XCTAssertTrue(result, @"Should parse percentage");
    XCTAssertEqualWithAccuracy(scale, 1.5, 0.001, @"150%% should be 1.5x scale");
    XCTAssertFalse(hasDPI, @"Should not have DPI");
    
    // Test percentage without %
    result = parseScale(@"200", &scale, &hasDPI, &dimensions);
    XCTAssertTrue(result, @"Should parse number as percentage");
    XCTAssertEqualWithAccuracy(scale, 2.0, 0.001, @"200 should be 2.0x scale");
}

- (void)testParseScaleDPI {
    CGFloat scale = 0;
    BOOL hasDPI = NO;
    CGSize dimensions = CGSizeZero;
    
    // Test DPI scaling
    BOOL result = parseScale(@"300dpi", &scale, &hasDPI, &dimensions);
    XCTAssertTrue(result, @"Should parse DPI");
    XCTAssertEqualWithAccuracy(scale, 300.0 / 72.0, 0.001, @"300dpi should scale correctly");
    XCTAssertTrue(hasDPI, @"Should have DPI");
    
    // Test uppercase DPI
    result = parseScale(@"150DPI", &scale, &hasDPI, &dimensions);
    XCTAssertTrue(result, @"Should parse uppercase DPI");
    XCTAssertEqualWithAccuracy(scale, 150.0 / 72.0, 0.001, @"150DPI should scale correctly");
}

- (void)testParseScaleDimensions {
    CGFloat scale = 0;
    BOOL hasDPI = NO;
    CGSize dimensions = CGSizeZero;
    
    // Test width only
    BOOL result = parseScale(@"800x", &scale, &hasDPI, &dimensions);
    XCTAssertTrue(result, @"Should parse width-only dimension");
    XCTAssertEqual(dimensions.width, 800, @"Width should be 800");
    XCTAssertEqual(dimensions.height, 0, @"Height should be 0");
    
    // Test height only
    result = parseScale(@"x600", &scale, &hasDPI, &dimensions);
    XCTAssertTrue(result, @"Should parse height-only dimension");
    XCTAssertEqual(dimensions.width, 0, @"Width should be 0");
    XCTAssertEqual(dimensions.height, 600, @"Height should be 600");
    
    // Test both dimensions
    result = parseScale(@"1024x768", &scale, &hasDPI, &dimensions);
    XCTAssertTrue(result, @"Should parse both dimensions");
    XCTAssertEqual(dimensions.width, 1024, @"Width should be 1024");
    XCTAssertEqual(dimensions.height, 768, @"Height should be 768");
}

- (void)testParseScaleInvalid {
    CGFloat scale = 0;
    BOOL hasDPI = NO;
    CGSize dimensions = CGSizeZero;
    
    // Test invalid input
    BOOL result = parseScale(@"invalid", &scale, &hasDPI, &dimensions);
    XCTAssertFalse(result, @"Should fail on invalid input");
    
    // Test empty string
    result = parseScale(@"", &scale, &hasDPI, &dimensions);
    XCTAssertFalse(result, @"Should fail on empty string");
    
    // Test negative values
    result = parseScale(@"-100%", &scale, &hasDPI, &dimensions);
    XCTAssertFalse(result, @"Should fail on negative percentage");
}

#pragma mark - Calculate Scale Tests

- (void)testCalculateScaleFromDPI {
    CGFloat resultScale = calculateScale(1.0, YES, CGSizeZero, CGSizeMake(612, 792));
    XCTAssertEqualWithAccuracy(resultScale, 1.0, 0.001, @"72 DPI should be 1.0x scale");
    
    resultScale = calculateScale(144.0 / 72.0, YES, CGSizeZero, CGSizeMake(612, 792));
    XCTAssertEqualWithAccuracy(resultScale, 2.0, 0.001, @"144 DPI should be 2.0x scale");
}

- (void)testCalculateScaleFromDimensions {
    // Test width-based scaling
    CGFloat resultScale = calculateScale(0, NO, CGSizeMake(800, 0), CGSizeMake(400, 600));
    XCTAssertEqualWithAccuracy(resultScale, 2.0, 0.001, @"800px width from 400px should be 2.0x");
    
    // Test height-based scaling
    resultScale = calculateScale(0, NO, CGSizeMake(0, 600), CGSizeMake(400, 300));
    XCTAssertEqualWithAccuracy(resultScale, 2.0, 0.001, @"600px height from 300px should be 2.0x");
    
    // Test fit within box (limited by width)
    resultScale = calculateScale(0, NO, CGSizeMake(800, 600), CGSizeMake(400, 300));
    XCTAssertEqualWithAccuracy(resultScale, 2.0, 0.001, @"Should scale to fit width");
    
    // Test fit within box (limited by height)
    resultScale = calculateScale(0, NO, CGSizeMake(800, 450), CGSizeMake(400, 300));
    XCTAssertEqualWithAccuracy(resultScale, 1.5, 0.001, @"Should scale to fit height");
}

#pragma mark - File Extension Tests

- (void)testHasPNGExtension {
    XCTAssertTrue(hasPNGExtension(@"image.png"), @"Should recognize .png");
    XCTAssertTrue(hasPNGExtension(@"image.PNG"), @"Should recognize .PNG");
    XCTAssertTrue(hasPNGExtension(@"path/to/image.png"), @"Should recognize .png in path");
    
    XCTAssertFalse(hasPNGExtension(@"image.jpg"), @"Should not recognize .jpg");
    XCTAssertFalse(hasPNGExtension(@"image"), @"Should not recognize no extension");
    XCTAssertFalse(hasPNGExtension(@""), @"Should handle empty string");
}

#pragma mark - Output Path Tests

- (void)testOutputPathForPage {
    // Test simple page number
    NSString *result = outputPathForPage(@"output.png", 5);
    XCTAssertEqualObjects(result, @"output-005.png", @"Should format page number");
    
    // Test without extension
    result = outputPathForPage(@"output", 10);
    XCTAssertEqualObjects(result, @"output-010", @"Should handle no extension");
    
    // Test with path
    result = outputPathForPage(@"/path/to/output.png", 1);
    XCTAssertEqualObjects(result, @"/path/to/output-001.png", @"Should handle full path");
    
    // Test large page number
    result = outputPathForPage(@"output.png", 999);
    XCTAssertEqualObjects(result, @"output-999.png", @"Should handle large page number");
}

#pragma mark - Print Error Tests

- (void)testPrintError {
    // These tests would normally capture stderr, but for now we just ensure they don't crash
    printError(@"Test error message");
    printError(@"Error with format: %d", 42);
    printError(@"");
    
    // Test with nil (should not crash)
    // Note: In real code, passing nil to printError would be a bug
    XCTAssertNoThrow(printError(@"Safe error message"), @"Should not throw");
}

@end