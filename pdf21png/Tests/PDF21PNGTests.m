//
//  PDF21PNGTests.m
//  PDF21PNG Tests
//
//  Main test suite for pdf21png
//

#import <XCTest/XCTest.h>

@interface PDF21PNGTests : XCTestCase
@property (nonatomic, strong) NSString *testPDFPath;
@property (nonatomic, strong) NSString *outputPath;
@end

@implementation PDF21PNGTests

- (void)setUp {
    [super setUp];
    
    // Create a temporary directory for test files
    NSString *tempDir = NSTemporaryDirectory();
    NSString *testDir = [tempDir stringByAppendingPathComponent:@"pdf21png_tests"];
    [[NSFileManager defaultManager] createDirectoryAtPath:testDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    // Create a simple test PDF
    self.testPDFPath = [testDir stringByAppendingPathComponent:@"test.pdf"];
    [self createTestPDF:self.testPDFPath];
    
    self.outputPath = [testDir stringByAppendingPathComponent:@"output.png"];
}

- (void)tearDown {
    // Clean up test files
    NSString *testDir = [self.testPDFPath stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] removeItemAtPath:testDir error:nil];
    
    [super tearDown];
}

#pragma mark - Helper Methods

- (void)createTestPDF:(NSString *)path {
    // Create a simple PDF for testing
    CGRect mediaBox = CGRectMake(0, 0, 612, 792); // US Letter
    
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL,
                                                  (__bridge CFStringRef)path,
                                                  kCFURLPOSIXPathStyle,
                                                  false);
    
    CGContextRef pdfContext = CGPDFContextCreateWithURL(url, &mediaBox, NULL);
    CFRelease(url);
    
    // Page 1
    CGPDFContextBeginPage(pdfContext, NULL);
    CGContextSetRGBFillColor(pdfContext, 0.0, 0.0, 1.0, 1.0);
    CGContextFillRect(pdfContext, CGRectMake(100, 100, 200, 200));
    CGPDFContextEndPage(pdfContext);
    
    // Page 2
    CGPDFContextBeginPage(pdfContext, NULL);
    CGContextSetRGBFillColor(pdfContext, 1.0, 0.0, 0.0, 1.0);
    CGContextFillRect(pdfContext, CGRectMake(200, 200, 300, 300));
    CGPDFContextEndPage(pdfContext);
    
    CGPDFContextClose(pdfContext);
    CGContextRelease(pdfContext);
}

#pragma mark - PDF Loading Tests

- (void)testLoadPDF {
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL,
                                                  (__bridge CFStringRef)self.testPDFPath,
                                                  kCFURLPOSIXPathStyle,
                                                  false);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(url);
    CFRelease(url);
    
    XCTAssertNotEqual(document, NULL, @"Should load PDF document");
    
    size_t pageCount = CGPDFDocumentGetNumberOfPages(document);
    XCTAssertEqual(pageCount, 2, @"Test PDF should have 2 pages");
    
    CGPDFDocumentRelease(document);
}

- (void)testLoadNonExistentPDF {
    NSString *badPath = @"/nonexistent/path/to/file.pdf";
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL,
                                                  (__bridge CFStringRef)badPath,
                                                  kCFURLPOSIXPathStyle,
                                                  false);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(url);
    CFRelease(url);
    
    XCTAssertEqual(document, NULL, @"Should fail to load non-existent PDF");
}

#pragma mark - Page Access Tests

- (void)testGetPDFPage {
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL,
                                                  (__bridge CFStringRef)self.testPDFPath,
                                                  kCFURLPOSIXPathStyle,
                                                  false);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(url);
    CFRelease(url);
    
    // Test valid page numbers
    CGPDFPageRef page1 = CGPDFDocumentGetPage(document, 1);
    XCTAssertNotEqual(page1, NULL, @"Should get page 1");
    
    CGPDFPageRef page2 = CGPDFDocumentGetPage(document, 2);
    XCTAssertNotEqual(page2, NULL, @"Should get page 2");
    
    // Test invalid page numbers
    CGPDFPageRef page0 = CGPDFDocumentGetPage(document, 0);
    XCTAssertEqual(page0, NULL, @"Should fail for page 0");
    
    CGPDFPageRef page3 = CGPDFDocumentGetPage(document, 3);
    XCTAssertEqual(page3, NULL, @"Should fail for page 3");
    
    CGPDFDocumentRelease(document);
}

#pragma mark - Image Creation Tests

- (void)testCreateImageFromPDF {
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL,
                                                  (__bridge CFStringRef)self.testPDFPath,
                                                  kCFURLPOSIXPathStyle,
                                                  false);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(url);
    CFRelease(url);
    
    CGPDFPageRef page = CGPDFDocumentGetPage(document, 1);
    CGRect mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    
    // Create bitmap context
    size_t width = (size_t)(mediaBox.size.width * 2.0); // 2x scale
    size_t height = (size_t)(mediaBox.size.height * 2.0);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0,
                                                  colorSpace,
                                                  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    
    XCTAssertNotEqual(context, NULL, @"Should create bitmap context");
    
    // Render PDF to context
    CGContextScaleCTM(context, 2.0, 2.0);
    CGContextDrawPDFPage(context, page);
    
    // Create image
    CGImageRef image = CGBitmapContextCreateImage(context);
    XCTAssertNotEqual(image, NULL, @"Should create image from context");
    
    // Verify image dimensions
    XCTAssertEqual(CGImageGetWidth(image), width, @"Image width should match");
    XCTAssertEqual(CGImageGetHeight(image), height, @"Image height should match");
    
    CGImageRelease(image);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGPDFDocumentRelease(document);
}

#pragma mark - PNG Writing Tests

- (void)testWritePNGToFile {
    // Create a simple test image
    size_t width = 100;
    size_t height = 100;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0,
                                                  colorSpace,
                                                  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    
    // Draw something
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // Write to file
    CFURLRef outputURL = CFURLCreateWithFileSystemPath(NULL,
                                                        (__bridge CFStringRef)self.outputPath,
                                                        kCFURLPOSIXPathStyle,
                                                        false);
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(outputURL,
                                                                         kUTTypePNG,
                                                                         1, NULL);
    
    XCTAssertNotEqual(destination, NULL, @"Should create image destination");
    
    CGImageDestinationAddImage(destination, image, NULL);
    BOOL success = CGImageDestinationFinalize(destination);
    
    XCTAssertTrue(success, @"Should write PNG successfully");
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:self.outputPath],
                  @"PNG file should exist");
    
    CFRelease(destination);
    CFRelease(outputURL);
    CGImageRelease(image);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
}

#pragma mark - Transparency Tests

- (void)testTransparentBackground {
    size_t width = 100;
    size_t height = 100;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create context with alpha
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0,
                                                  colorSpace,
                                                  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    
    // Clear to transparent
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    // Draw semi-transparent rectangle
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.5);
    CGContextFillRect(context, CGRectMake(25, 25, 50, 50));
    
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // Verify alpha channel
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image);
    XCTAssertNotEqual(alphaInfo, kCGImageAlphaNone, @"Image should have alpha channel");
    
    CGImageRelease(image);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
}

#pragma mark - Performance Tests

- (void)testRenderingPerformance {
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL,
                                                  (__bridge CFStringRef)self.testPDFPath,
                                                  kCGURLPOSIXPathStyle,
                                                  false);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(url);
    CFRelease(url);
    
    CGPDFPageRef page = CGPDFDocumentGetPage(document, 1);
    
    [self measureBlock:^{
        @autoreleasepool {
            CGRect mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
            size_t width = (size_t)(mediaBox.size.width * 2.0);
            size_t height = (size_t)(mediaBox.size.height * 2.0);
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0,
                                                          colorSpace,
                                                          kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
            
            CGContextScaleCTM(context, 2.0, 2.0);
            CGContextDrawPDFPage(context, page);
            
            CGImageRef image = CGBitmapContextCreateImage(context);
            
            CGImageRelease(image);
            CGContextRelease(context);
            CGColorSpaceRelease(colorSpace);
        }
    }];
    
    CGPDFDocumentRelease(document);
}

@end