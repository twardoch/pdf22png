/*
 * test_utils.c
 * Unit tests for pdf21png utilities
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <CoreGraphics/CoreGraphics.h>

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
        printf("❌ FAIL: %s\n", message); \
        stats.failed++; \
    } else { \
        stats.passed++; \
    } \
} while(0)

#define TEST_ASSERT_EQUAL(expected, actual, message) do { \
    stats.total++; \
    if ((expected) != (actual)) { \
        printf("❌ FAIL: %s (expected %ld, got %ld)\n", message, (long)(expected), (long)(actual)); \
        stats.failed++; \
    } else { \
        stats.passed++; \
    } \
} while(0)

#define TEST_ASSERT_EQUAL_FLOAT(expected, actual, tolerance, message) do { \
    stats.total++; \
    if (fabs((expected) - (actual)) > (tolerance)) { \
        printf("❌ FAIL: %s (expected %.3f, got %.3f)\n", message, (expected), (actual)); \
        stats.failed++; \
    } else { \
        stats.passed++; \
    } \
} while(0)

#define TEST_ASSERT_STRING_EQUAL(expected, actual, message) do { \
    stats.total++; \
    if (strcmp((expected), (actual)) != 0) { \
        printf("❌ FAIL: %s (expected \"%s\", got \"%s\")\n", message, (expected), (actual)); \
        stats.failed++; \
    } else { \
        stats.passed++; \
    } \
} while(0)

// Include the actual header
#include "../src/utils.h"

// Helper functions to test the actual API
int parseScale(const char* scaleStr, CGFloat* scale, int* hasDPI, CGSize* dimensions) {
    ScaleSpec spec = {0};
    BOOL result = parseScaleSpec(scaleStr, &spec);
    if (result) {
        *scale = spec.value;
        *hasDPI = (spec.type == ScaleTypeDPI) ? 1 : 0;
        if (spec.type == ScaleTypeFixed) {
            dimensions->width = spec.width;
            dimensions->height = spec.height;
        }
    }
    return result ? 1 : 0;
}

CGFloat calculateScale(CGFloat scale, int hasDPI, CGSize dimensions, CGSize pageSize) {
    ScaleSpec spec = {0};
    if (hasDPI) {
        spec.type = ScaleTypeDPI;
        spec.value = scale;
    } else if (dimensions.width > 0 || dimensions.height > 0) {
        spec.type = ScaleTypeFixed;
        spec.width = dimensions.width;
        spec.height = dimensions.height;
    } else {
        spec.type = ScaleTypePercentage;
        spec.value = scale;
    }
    CGRect pageRect = CGRectMake(0, 0, pageSize.width, pageSize.height);
    return calculateScaleFactor(&spec, pageRect);
}

// Test functions
void test_parseScale_percentage() {
    printf("\n🧪 Testing parseScale with percentages...\n");
    
    CGFloat scale = 0;
    int hasDPI = 0;
    CGSize dimensions = CGSizeZero;
    
    // Test 150%
    int result = parseScale("150%", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 1, "parseScale should succeed for '150%'");
    TEST_ASSERT_EQUAL_FLOAT(1.5, scale, 0.001, "150% should be 1.5x scale");
    TEST_ASSERT(!hasDPI, "Should not have DPI flag");
    
    // Test 200 (without %)
    result = parseScale("200", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 1, "parseScale should succeed for '200'");
    TEST_ASSERT_EQUAL_FLOAT(2.0, scale, 0.001, "200 should be 2.0x scale");
    
    // Test 50%
    result = parseScale("50%", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 1, "parseScale should succeed for '50%'");
    TEST_ASSERT_EQUAL_FLOAT(0.5, scale, 0.001, "50% should be 0.5x scale");
}

void test_parseScale_dpi() {
    printf("\n🧪 Testing parseScale with DPI...\n");
    
    CGFloat scale = 0;
    int hasDPI = 0;
    CGSize dimensions = CGSizeZero;
    
    // Test 300dpi
    int result = parseScale("300dpi", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 1, "parseScale should succeed for '300dpi'");
    TEST_ASSERT_EQUAL_FLOAT(300.0 / 72.0, scale, 0.001, "300dpi should scale correctly");
    TEST_ASSERT(hasDPI == 1, "Should have DPI flag");
    
    // Test 144DPI (uppercase)
    result = parseScale("144DPI", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 1, "parseScale should succeed for '144DPI'");
    TEST_ASSERT_EQUAL_FLOAT(144.0 / 72.0, scale, 0.001, "144DPI should be 2.0x scale");
}

void test_parseScale_dimensions() {
    printf("\n🧪 Testing parseScale with dimensions...\n");
    
    CGFloat scale = 0;
    int hasDPI = 0;
    CGSize dimensions = CGSizeZero;
    
    // Test width only: 800x
    int result = parseScale("800x", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 1, "parseScale should succeed for '800x'");
    TEST_ASSERT_EQUAL(800, (int)dimensions.width, "Width should be 800");
    TEST_ASSERT_EQUAL(0, (int)dimensions.height, "Height should be 0");
    
    // Test height only: x600
    result = parseScale("x600", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 1, "parseScale should succeed for 'x600'");
    TEST_ASSERT_EQUAL(0, (int)dimensions.width, "Width should be 0");
    TEST_ASSERT_EQUAL(600, (int)dimensions.height, "Height should be 600");
    
    // Test both: 1024x768
    result = parseScale("1024x768", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 1, "parseScale should succeed for '1024x768'");
    TEST_ASSERT_EQUAL(1024, (int)dimensions.width, "Width should be 1024");
    TEST_ASSERT_EQUAL(768, (int)dimensions.height, "Height should be 768");
}

void test_parseScale_invalid() {
    printf("\n🧪 Testing parseScale with invalid input...\n");
    
    CGFloat scale = 0;
    int hasDPI = 0;
    CGSize dimensions = CGSizeZero;
    
    // Test invalid string
    int result = parseScale("invalid", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 0, "parseScale should fail for 'invalid'");
    
    // Test empty string
    result = parseScale("", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 0, "parseScale should fail for empty string");
    
    // Test negative percentage
    result = parseScale("-50%", &scale, &hasDPI, &dimensions);
    TEST_ASSERT(result == 0, "parseScale should fail for negative percentage");
}

void test_calculateScale() {
    printf("\n🧪 Testing calculateScale...\n");
    
    CGSize pageSize = CGSizeMake(612, 792); // US Letter at 72 DPI
    
    // Test DPI scaling
    CGFloat resultScale = calculateScale(1.0, 1, CGSizeZero, pageSize);
    TEST_ASSERT_EQUAL_FLOAT(1.0, resultScale, 0.001, "72 DPI should be 1.0x scale");
    
    resultScale = calculateScale(2.0, 1, CGSizeZero, pageSize);
    TEST_ASSERT_EQUAL_FLOAT(2.0, resultScale, 0.001, "144 DPI should be 2.0x scale");
    
    // Test dimension scaling (width only)
    resultScale = calculateScale(0, 0, CGSizeMake(1224, 0), pageSize);
    TEST_ASSERT_EQUAL_FLOAT(2.0, resultScale, 0.001, "1224px width should be 2.0x scale");
    
    // Test dimension scaling (height only)
    resultScale = calculateScale(0, 0, CGSizeMake(0, 1584), pageSize);
    TEST_ASSERT_EQUAL_FLOAT(2.0, resultScale, 0.001, "1584px height should be 2.0x scale");
    
    // Test fit within box
    resultScale = calculateScale(0, 0, CGSizeMake(800, 600), pageSize);
    TEST_ASSERT_EQUAL_FLOAT(600.0 / 792.0, resultScale, 0.001, "Should scale to fit height");
}

void test_hasPNGExtension() {
    printf("\n🧪 Testing hasPNGExtension...\n");
    
    TEST_ASSERT(hasPNGExtension("image.png") == 1, "Should recognize .png");
    TEST_ASSERT(hasPNGExtension("IMAGE.PNG") == 1, "Should recognize .PNG");
    TEST_ASSERT(hasPNGExtension("path/to/file.png") == 1, "Should recognize .png in path");
    TEST_ASSERT(hasPNGExtension("file.jpg") == 0, "Should not recognize .jpg");
    TEST_ASSERT(hasPNGExtension("noextension") == 0, "Should not recognize no extension");
}

void test_outputPathForPage() {
    printf("\n🧪 Testing outputPathForPage...\n");
    
    char* result;
    
    // Test simple case
    result = outputPathForPage("output.png", 5);
    TEST_ASSERT_STRING_EQUAL("output-005.png", result, "Should format page 5 correctly");
    free(result);
    
    // Test without extension
    result = outputPathForPage("output", 10);
    TEST_ASSERT_STRING_EQUAL("output-010", result, "Should handle no extension");
    free(result);
    
    // Test with path
    result = outputPathForPage("/path/to/output.png", 1);
    TEST_ASSERT_STRING_EQUAL("/path/to/output-001.png", result, "Should handle full path");
    free(result);
}

// Main test runner
int main(int argc, char* argv[]) {
    printf("🧪 PDF21PNG Unit Tests\n");
    printf("=====================\n");
    
    // Run all tests
    test_parseScale_percentage();
    test_parseScale_dpi();
    test_parseScale_dimensions();
    test_parseScale_invalid();
    test_calculateScale();
    test_hasPNGExtension();
    test_outputPathForPage();
    
    // Print summary
    printf("\n📊 Test Summary\n");
    printf("===============\n");
    printf("Total:  %d\n", stats.total);
    printf("Passed: %d ✅\n", stats.passed);
    printf("Failed: %d ❌\n", stats.failed);
    
    if (stats.failed == 0) {
        printf("\n🎉 All tests passed!\n");
        return 0;
    } else {
        printf("\n❌ Some tests failed!\n");
        return 1;
    }
}