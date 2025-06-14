/**
 * @file matrix_test.c
 * @brief Matrix Accelerator Test Application
 * 
 * This application tests the matrix multiplication accelerator with
 * various test cases to validate functionality and measure performance.
 */

#include "matrix_accel_driver.h"
#include <stdio.h>
#include <string.h>

// Test case definitions
typedef struct {
    const char* name;
    matrix_input_t matrix_a;
    matrix_input_t matrix_b;
    matrix_output_t expected_result;
} test_case_t;

// Function prototypes
static void print_matrix_input(const char* name, const matrix_input_t matrix);
static void print_matrix_output(const char* name, const matrix_output_t matrix);
static bool compare_matrices(const matrix_output_t result, const matrix_output_t expected);
static void run_test_case(const test_case_t* test);
static void run_performance_test(void);

// Test cases
static const test_case_t test_cases[] = {
    // Test Case 1: Identity matrix multiplication
    {
        .name = "Identity Matrix Test",
        .matrix_a = {
            {1, 2, 3, 4},
            {5, 6, 7, 8},
            {9, 10, 11, 12},
            {13, 14, 15, 16}
        },
        .matrix_b = {
            {1, 0, 0, 0},
            {0, 1, 0, 0},
            {0, 0, 1, 0},
            {0, 0, 0, 1}
        },
        .expected_result = {
            {1, 2, 3, 4},
            {5, 6, 7, 8},
            {9, 10, 11, 12},
            {13, 14, 15, 16}
        }
    },
    
    // Test Case 2: Simple multiplication
    {
        .name = "Simple Multiplication Test",
        .matrix_a = {
            {1, 2, 0, 0},
            {0, 1, 2, 0},
            {0, 0, 1, 2},
            {0, 0, 0, 1}
        },
        .matrix_b = {
            {2, 0, 0, 0},
            {1, 2, 0, 0},
            {0, 1, 2, 0},
            {0, 0, 1, 2}
        },
        .expected_result = {
            {4, 4, 0, 0},
            {1, 4, 4, 0},
            {0, 1, 4, 4},
            {0, 0, 1, 2}
        }
    },
    
    // Test Case 3: All ones
    {
        .name = "All Ones Test",
        .matrix_a = {
            {1, 1, 1, 1},
            {1, 1, 1, 1},
            {1, 1, 1, 1},
            {1, 1, 1, 1}
        },
        .matrix_b = {
            {1, 1, 1, 1},
            {1, 1, 1, 1},
            {1, 1, 1, 1},
            {1, 1, 1, 1}
        },
        .expected_result = {
            {4, 4, 4, 4},
            {4, 4, 4, 4},
            {4, 4, 4, 4},
            {4, 4, 4, 4}
        }
    }
};

#define NUM_TEST_CASES (sizeof(test_cases) / sizeof(test_cases[0]))

int main(void) {
    printf("=== Matrix Accelerator Test Suite ===\n\n");
    
    // Initialize the accelerator
    printf("Initializing matrix accelerator...\n");
    matrix_accel_result_t result = matrix_accel_init();
    if (result != MATRIX_ACCEL_SUCCESS) {
        printf("ERROR: Failed to initialize accelerator: %s\n", 
               matrix_accel_error_string(result));
        return -1;
    }
    printf("Accelerator initialized successfully!\n\n");
    
    // Check initial status
    bool is_busy, is_done;
    result = matrix_accel_get_status(&is_busy, &is_done);
    if (result == MATRIX_ACCEL_SUCCESS) {
        printf("Initial status - Busy: %s, Done: %s\n\n", 
               is_busy ? "Yes" : "No", is_done ? "Yes" : "No");
    }
    
    // Run all test cases
    int passed = 0;
    int failed = 0;
    
    for (int i = 0; i < NUM_TEST_CASES; i++) {
        printf("--- Running Test Case %d: %s ---\n", i + 1, test_cases[i].name);
        
        // Run the test
        matrix_output_t actual_result;
        result = matrix_accel_multiply(test_cases[i].matrix_a, 
                                       test_cases[i].matrix_b,
                                       actual_result,
                                       10000); // 10k cycle timeout
        
        if (result != MATRIX_ACCEL_SUCCESS) {
            printf("ERROR: Matrix multiplication failed: %s\n", 
                   matrix_accel_error_string(result));
            failed++;
            continue;
        }
        
        // Check results
        if (compare_matrices(actual_result, test_cases[i].expected_result)) {
            printf("PASS: Test case %d passed!\n", i + 1);
            passed++;
        } else {
            printf("FAIL: Test case %d failed!\n", i + 1);
            print_matrix_input("Matrix A", test_cases[i].matrix_a);
            print_matrix_input("Matrix B", test_cases[i].matrix_b);
            print_matrix_output("Expected", test_cases[i].expected_result);
            print_matrix_output("Actual", actual_result);
            failed++;
        }
        printf("\n");
    }
    
    // Print summary
    printf("=== Test Summary ===\n");
    printf("Total tests: %d\n", NUM_TEST_CASES);
    printf("Passed: %d\n", passed);
    printf("Failed: %d\n", failed);
    printf("Success rate: %.1f%%\n", (float)passed / NUM_TEST_CASES * 100.0f);
    
    if (failed == 0) {
        printf("\n🎉 All tests passed! Matrix accelerator is working correctly.\n");
        
        // Run performance test if all functional tests pass
        printf("\n--- Running Performance Test ---\n");
        run_performance_test();
    } else {
        printf("\n❌ Some tests failed. Please check the hardware implementation.\n");
    }
    
    return (failed == 0) ? 0 : -1;
}

static void print_matrix_input(const char* name, const matrix_input_t matrix) {
    printf("%s:\n", name);
    for (int row = 0; row < MATRIX_SIZE; row++) {
        printf("  [");
        for (int col = 0; col < MATRIX_SIZE; col++) {
            printf("%3d", matrix[row][col]);
            if (col < MATRIX_SIZE - 1) printf(", ");
        }
        printf("]\n");
    }
}

static void print_matrix_output(const char* name, const matrix_output_t matrix) {
    printf("%s:\n", name);
    for (int row = 0; row < MATRIX_SIZE; row++) {
        printf("  [");
        for (int col = 0; col < MATRIX_SIZE; col++) {
            printf("%6u", matrix[row][col]);
            if (col < MATRIX_SIZE - 1) printf(", ");
        }
        printf("]\n");
    }
}

static bool compare_matrices(const matrix_output_t result, const matrix_output_t expected) {
    for (int row = 0; row < MATRIX_SIZE; row++) {
        for (int col = 0; col < MATRIX_SIZE; col++) {
            if (result[row][col] != expected[row][col]) {
                return false;
            }
        }
    }
    return true;
}

static void run_performance_test(void) {
    // Simple performance test with larger values
    matrix_input_t perf_a = {
        {10, 20, 30, 40},
        {50, 60, 70, 80},
        {90, 100, 110, 120},
        {130, 140, 150, 160}
    };
    
    matrix_input_t perf_b = {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12},
        {13, 14, 15, 16}
    };
    
    matrix_output_t perf_result;
    
    printf("Running performance test with larger values...\n");
    print_matrix_input("Performance Matrix A", perf_a);
    print_matrix_input("Performance Matrix B", perf_b);
    
    // Measure performance (rough cycle count)
    uint32_t start_cycles = 0; // In real implementation, read cycle counter
    
    matrix_accel_result_t result = matrix_accel_multiply(perf_a, perf_b, perf_result, 50000);
    
    uint32_t end_cycles = 1000; // In real implementation, read cycle counter
    
    if (result == MATRIX_ACCEL_SUCCESS) {
        printf("Performance test completed successfully!\n");
        print_matrix_output("Performance Result", perf_result);
        printf("Estimated cycles: %u\n", end_cycles - start_cycles);
        printf("Note: Cycle counting not implemented in this test version\n");
    } else {
        printf("Performance test failed: %s\n", matrix_accel_error_string(result));
    }
} 