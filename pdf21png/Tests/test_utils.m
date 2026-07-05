/*
 * test_utils.m
 * Unit tests for pdf21png utilities.
 *
 * Compiled as Objective-C (utils.h imports Foundation/Quartz). A tiny
 * assertion-macro harness keeps this independent of XCTest so it can run from a
 * plain shell script in CI. Tests target the real API declared in utils.h.
 */

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <math.h>

#include "../src/utils.h"

// Test framework
typedef struct {
    int total;
    int passed;
    int failed;
} TestStats;

static TestStats stats = {0, 0, 0};

#define TEST_ASSERT(condition, message) do { \
    stats.total++; \
    if (!(condition)) { \
        printf("FAIL: %s\n", message); \
        stats.failed++; \
    } else { \
        stats.passed++; \
    } \
} while(0)

#define TEST_ASSERT_EQUAL_FLOAT(expected, actual, tolerance, message) do { \
    stats.total++; \
    if (fabs((double)(expected) - (double)(actual)) > (tolerance)) { \
        printf("FAIL: %s (expected %.3f, got %.3f)\n", message, (double)(expected), (double)(actual)); \
        stats.failed++; \
    } else { \
        stats.passed++; \
    } \
} while(0)

// MARK: - parseScaleSpec

void test_parseScaleSpec_percentage(void) {
    printf("\nTesting parseScaleSpec with percentages...\n");
    ScaleSpec spec;

    TEST_ASSERT(parseScaleSpec("150%", &spec), "parseScaleSpec should succeed for '150%'");
    TEST_ASSERT(spec.isPercentage, "150% should set isPercentage");
    TEST_ASSERT_EQUAL_FLOAT(1.5, spec.scaleFactor, 0.001, "150% should be 1.5x scale");

    TEST_ASSERT(parseScaleSpec("50%", &spec), "parseScaleSpec should succeed for '50%'");
    TEST_ASSERT_EQUAL_FLOAT(0.5, spec.scaleFactor, 0.001, "50% should be 0.5x scale");
}

void test_parseScaleSpec_simpleFactor(void) {
    printf("\nTesting parseScaleSpec with plain scale factors...\n");
    ScaleSpec spec;

    TEST_ASSERT(parseScaleSpec("2.0", &spec), "parseScaleSpec should succeed for '2.0'");
    TEST_ASSERT(!spec.isPercentage, "2.0 should not be a percentage");
    TEST_ASSERT(!spec.isDPI, "2.0 should not be DPI");
    TEST_ASSERT_EQUAL_FLOAT(2.0, spec.scaleFactor, 0.001, "2.0 should be 2.0x scale");
}

void test_parseScaleSpec_dpi(void) {
    printf("\nTesting parseScaleSpec with DPI...\n");
    ScaleSpec spec;

    TEST_ASSERT(parseScaleSpec("300dpi", &spec), "parseScaleSpec should succeed for '300dpi'");
    TEST_ASSERT(spec.isDPI, "300dpi should set isDPI");
    TEST_ASSERT_EQUAL_FLOAT(300.0, spec.dpi, 0.001, "300dpi should store dpi=300");
}

void test_parseScaleSpec_dimensions(void) {
    printf("\nTesting parseScaleSpec with dimensions...\n");
    // NOTE: pdf21png uses a HEIGHTxWIDTH convention (the part before 'x' is the
    // height, the part after is the width). This differs from the Swift
    // pdf22png tool, which is width-first. Preserved here as battle-tested
    // behavior; the tests document the actual contract rather than change it.
    ScaleSpec spec;

    TEST_ASSERT(parseScaleSpec("800x600", &spec), "parseScaleSpec should succeed for '800x600'");
    TEST_ASSERT(spec.hasHeight, "800x600 should set hasHeight");
    TEST_ASSERT(spec.hasWidth, "800x600 should set hasWidth");
    TEST_ASSERT_EQUAL_FLOAT(800.0, spec.maxHeight, 0.001, "800x600: height should be 800");
    TEST_ASSERT_EQUAL_FLOAT(600.0, spec.maxWidth, 0.001, "800x600: width should be 600");

    // Height only: "800x"
    TEST_ASSERT(parseScaleSpec("800x", &spec), "parseScaleSpec should succeed for '800x'");
    TEST_ASSERT(spec.hasHeight && !spec.hasWidth, "800x should be height-only");

    // Width only: "x600"
    TEST_ASSERT(parseScaleSpec("x600", &spec), "parseScaleSpec should succeed for 'x600'");
    TEST_ASSERT(spec.hasWidth && !spec.hasHeight, "x600 should be width-only");
}

void test_parseScaleSpec_invalid(void) {
    printf("\nTesting parseScaleSpec with invalid input...\n");
    ScaleSpec spec;

    TEST_ASSERT(!parseScaleSpec("invalid", &spec), "parseScaleSpec should fail for 'invalid'");
    TEST_ASSERT(!parseScaleSpec("", &spec), "parseScaleSpec should fail for empty string");
    TEST_ASSERT(!parseScaleSpec("-50%", &spec), "parseScaleSpec should fail for negative percentage");
    TEST_ASSERT(!parseScaleSpec("0dpi", &spec), "parseScaleSpec should fail for zero DPI");
}

// MARK: - calculateScaleFactor

void test_calculateScaleFactor(void) {
    printf("\nTesting calculateScaleFactor...\n");
    CGRect page = CGRectMake(0, 0, 612, 792); // US Letter at 72 DPI

    ScaleSpec dpi72 = {0};
    dpi72.isDPI = YES; dpi72.dpi = 72;
    TEST_ASSERT_EQUAL_FLOAT(1.0, calculateScaleFactor(&dpi72, page), 0.001, "72 DPI should be 1.0x");

    ScaleSpec dpi144 = {0};
    dpi144.isDPI = YES; dpi144.dpi = 144;
    TEST_ASSERT_EQUAL_FLOAT(2.0, calculateScaleFactor(&dpi144, page), 0.001, "144 DPI should be 2.0x");

    ScaleSpec pct = {0};
    pct.isPercentage = YES; pct.scaleFactor = 0.5;
    TEST_ASSERT_EQUAL_FLOAT(0.5, calculateScaleFactor(&pct, page), 0.001, "50% should be 0.5x");

    // Width-limited: maxWidth 1224 over a 612pt-wide page -> 2.0x
    ScaleSpec widthOnly = {0};
    widthOnly.hasWidth = YES; widthOnly.maxWidth = 1224;
    TEST_ASSERT_EQUAL_FLOAT(2.0, calculateScaleFactor(&widthOnly, page), 0.001, "1224px width -> 2.0x");

    // Height-limited: maxHeight 1584 over a 792pt-tall page -> 2.0x
    ScaleSpec heightOnly = {0};
    heightOnly.hasHeight = YES; heightOnly.maxHeight = 1584;
    TEST_ASSERT_EQUAL_FLOAT(2.0, calculateScaleFactor(&heightOnly, page), 0.001, "1584px height -> 2.0x");

    // Fit within a box: choose the smaller of the two ratios.
    ScaleSpec box = {0};
    box.hasWidth = YES; box.maxWidth = 612; box.hasHeight = YES; box.maxHeight = 1584;
    TEST_ASSERT_EQUAL_FLOAT(1.0, calculateScaleFactor(&box, page), 0.001, "612x1584 box fits to width -> 1.0x");
}

// MARK: - parsePageRange

void test_parsePageRange(void) {
    printf("\nTesting parsePageRange...\n");
    @autoreleasepool {
        NSArray<NSNumber *> *single = parsePageRange(@"3", 10);
        TEST_ASSERT(single.count == 1 && single.firstObject.integerValue == 3,
                    "'3' should yield page [3]");

        NSArray<NSNumber *> *range = parsePageRange(@"2-4", 10);
        TEST_ASSERT(range.count == 3, "'2-4' should yield 3 pages");

        NSArray<NSNumber *> *mixed = parsePageRange(@"1,3,5-6", 10);
        TEST_ASSERT(mixed.count == 4, "'1,3,5-6' should yield 4 pages");
    }
}

// Main test runner
int main(int argc, const char *argv[]) {
        (void)argc; (void)argv;
    @autoreleasepool {
        printf("PDF21PNG Unit Tests\n");
        printf("===================\n");

        test_parseScaleSpec_percentage();
        test_parseScaleSpec_simpleFactor();
        test_parseScaleSpec_dpi();
        test_parseScaleSpec_dimensions();
        test_parseScaleSpec_invalid();
        test_calculateScaleFactor();
        test_parsePageRange();

        printf("\nTest Summary\n");
        printf("============\n");
        printf("Total:  %d\n", stats.total);
        printf("Passed: %d\n", stats.passed);
        printf("Failed: %d\n", stats.failed);

        if (stats.failed == 0) {
            printf("\nAll tests passed!\n");
            return 0;
        }
        printf("\nSome tests failed!\n");
        return 1;
    }
}
