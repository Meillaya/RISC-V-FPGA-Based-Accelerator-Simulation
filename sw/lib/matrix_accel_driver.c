/**
 * @file matrix_accel_driver.c
 * @brief Matrix Accelerator Driver Implementation
 * 
 * This file implements the matrix accelerator driver functions.
 * It provides a complete software interface to the hardware accelerator.
 */

#include "matrix_accel_driver.h"

// Internal helper functions
static void delay_cycles(uint32_t cycles);

matrix_accel_result_t matrix_accel_init(void) {
    // Reset the accelerator first
    hal_write_control(CONTROL_RESET_BIT);
    delay_cycles(10); // Give reset time to take effect
    
    // Clear reset and ensure start is not asserted
    hal_write_control(0);
    delay_cycles(10);
    
    // Configure the accelerator (set default matrix dimensions)
    // Config register format: [31:16] = P, [15:8] = N, [7:0] = M
    uint32_t config = (MATRIX_SIZE << 16) | (MATRIX_SIZE << 8) | MATRIX_SIZE;
    hal_write_config(config);
    
    // Verify we can read back the configuration
    uint32_t readback = hal_read_config();
    if (readback != config) {
        return MATRIX_ACCEL_ERROR_INVALID_PARAM;
    }
    
    return MATRIX_ACCEL_SUCCESS;
}

bool matrix_accel_is_ready(void) {
    uint32_t status = hal_read_status();
    return !(status & STATUS_BUSY_BIT);
}

bool matrix_accel_is_done(void) {
    uint32_t status = hal_read_status();
    return (status & STATUS_DONE_BIT) != 0;
}

matrix_accel_result_t matrix_accel_load_matrix_a(const matrix_input_t matrix) {
    if (!matrix_accel_is_ready()) {
        return MATRIX_ACCEL_ERROR_BUSY;
    }
    
    // Load matrix elements in row-major order
    int index = 0;
    for (int row = 0; row < MATRIX_SIZE; row++) {
        for (int col = 0; col < MATRIX_SIZE; col++) {
            hal_write_matrix_a_element(index, matrix[row][col]);
            index++;
        }
    }
    
    return MATRIX_ACCEL_SUCCESS;
}

matrix_accel_result_t matrix_accel_load_matrix_b(const matrix_input_t matrix) {
    if (!matrix_accel_is_ready()) {
        return MATRIX_ACCEL_ERROR_BUSY;
    }
    
    // Load matrix elements in row-major order
    int index = 0;
    for (int row = 0; row < MATRIX_SIZE; row++) {
        for (int col = 0; col < MATRIX_SIZE; col++) {
            hal_write_matrix_b_element(index, matrix[row][col]);
            index++;
        }
    }
    
    return MATRIX_ACCEL_SUCCESS;
}

matrix_accel_result_t matrix_accel_load_matrices(const matrix_input_t matrix_a, 
                                                  const matrix_input_t matrix_b) {
    matrix_accel_result_t result;
    
    result = matrix_accel_load_matrix_a(matrix_a);
    if (result != MATRIX_ACCEL_SUCCESS) {
        return result;
    }
    
    result = matrix_accel_load_matrix_b(matrix_b);
    if (result != MATRIX_ACCEL_SUCCESS) {
        return result;
    }
    
    return MATRIX_ACCEL_SUCCESS;
}

matrix_accel_result_t matrix_accel_start(void) {
    if (!matrix_accel_is_ready()) {
        return MATRIX_ACCEL_ERROR_BUSY;
    }
    
    // Pulse the start bit
    hal_write_control(CONTROL_START_BIT);
    
    // The hardware automatically clears the start bit after one cycle
    // But we can also clear it explicitly for safety
    delay_cycles(2);
    hal_write_control(0);
    
    return MATRIX_ACCEL_SUCCESS;
}

matrix_accel_result_t matrix_accel_wait_done(uint32_t timeout_cycles) {
    uint32_t cycles_waited = 0;
    
    while (!matrix_accel_is_done()) {
        if (timeout_cycles > 0 && cycles_waited >= timeout_cycles) {
            return MATRIX_ACCEL_ERROR_TIMEOUT;
        }
        delay_cycles(1);
        cycles_waited++;
    }
    
    return MATRIX_ACCEL_SUCCESS;
}

matrix_accel_result_t matrix_accel_read_result(matrix_output_t result) {
    if (!matrix_accel_is_done()) {
        return MATRIX_ACCEL_ERROR_BUSY;
    }
    
    // Read result matrix elements in row-major order
    int index = 0;
    for (int row = 0; row < MATRIX_SIZE; row++) {
        for (int col = 0; col < MATRIX_SIZE; col++) {
            result[row][col] = hal_read_matrix_c_element(index);
            index++;
        }
    }
    
    return MATRIX_ACCEL_SUCCESS;
}

matrix_accel_result_t matrix_accel_multiply(const matrix_input_t matrix_a,
                                             const matrix_input_t matrix_b,
                                             matrix_output_t result,
                                             uint32_t timeout_cycles) {
    matrix_accel_result_t status;
    
    // Load input matrices
    status = matrix_accel_load_matrices(matrix_a, matrix_b);
    if (status != MATRIX_ACCEL_SUCCESS) {
        return status;
    }
    
    // Start computation
    status = matrix_accel_start();
    if (status != MATRIX_ACCEL_SUCCESS) {
        return status;
    }
    
    // Wait for completion
    status = matrix_accel_wait_done(timeout_cycles);
    if (status != MATRIX_ACCEL_SUCCESS) {
        return status;
    }
    
    // Read results
    status = matrix_accel_read_result(result);
    if (status != MATRIX_ACCEL_SUCCESS) {
        return status;
    }
    
    return MATRIX_ACCEL_SUCCESS;
}

matrix_accel_result_t matrix_accel_reset(void) {
    // Assert reset
    hal_write_control(CONTROL_RESET_BIT);
    delay_cycles(10);
    
    // Deassert reset
    hal_write_control(0);
    delay_cycles(10);
    
    return MATRIX_ACCEL_SUCCESS;
}

matrix_accel_result_t matrix_accel_get_status(bool* is_busy, bool* is_done) {
    if (!is_busy || !is_done) {
        return MATRIX_ACCEL_ERROR_INVALID_PARAM;
    }
    
    uint32_t status = hal_read_status();
    *is_busy = (status & STATUS_BUSY_BIT) != 0;
    *is_done = (status & STATUS_DONE_BIT) != 0;
    
    return MATRIX_ACCEL_SUCCESS;
}

const char* matrix_accel_error_string(matrix_accel_result_t error) {
    switch (error) {
        case MATRIX_ACCEL_SUCCESS:
            return "Success";
        case MATRIX_ACCEL_ERROR_TIMEOUT:
            return "Operation timeout";
        case MATRIX_ACCEL_ERROR_BUSY:
            return "Accelerator busy";
        case MATRIX_ACCEL_ERROR_INVALID_PARAM:
            return "Invalid parameter";
        default:
            return "Unknown error";
    }
}

// Internal helper function for simple delay
static void delay_cycles(uint32_t cycles) {
    // Simple busy-wait loop
    // In a real implementation, this could use a timer or cycle counter
    volatile uint32_t i;
    for (i = 0; i < cycles * 10; i++) {
        // Do nothing, just consume cycles
        __asm__ volatile ("nop");
    }
} 