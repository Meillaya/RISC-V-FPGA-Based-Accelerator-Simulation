/**
 * @file matrix_accel_driver.h
 * @brief Matrix Accelerator Driver Interface
 * 
 * This file provides mid-level driver functions for matrix operations.
 * It builds on the HAL to provide matrix-oriented operations with
 * error checking and status management.
 * 
 * Usage Pattern:
 * 1. matrix_accel_init() - Initialize the accelerator
 * 2. matrix_accel_load_matrices() - Load input matrices
 * 3. matrix_accel_start() - Start computation
 * 4. matrix_accel_wait_done() - Wait for completion
 * 5. matrix_accel_read_result() - Read results
 */

#ifndef MATRIX_ACCEL_DRIVER_H
#define MATRIX_ACCEL_DRIVER_H

#include "matrix_accel_hal.h"
#include <stdbool.h>

// Error codes
typedef enum {
    MATRIX_ACCEL_SUCCESS = 0,
    MATRIX_ACCEL_ERROR_TIMEOUT = -1,
    MATRIX_ACCEL_ERROR_BUSY = -2,
    MATRIX_ACCEL_ERROR_INVALID_PARAM = -3
} matrix_accel_result_t;

// Matrix type definitions for convenience
typedef matrix_element_t matrix_input_t[MATRIX_SIZE][MATRIX_SIZE];
typedef matrix_result_t  matrix_output_t[MATRIX_SIZE][MATRIX_SIZE];

/**
 * @brief Initialize the matrix accelerator
 * 
 * Performs hardware reset and configuration setup.
 * Must be called before any other driver functions.
 * 
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_init(void);

/**
 * @brief Check if accelerator is ready for new operation
 * @return true if ready, false if busy
 */
bool matrix_accel_is_ready(void);

/**
 * @brief Check if accelerator operation is complete
 * @return true if done, false if still computing
 */
bool matrix_accel_is_done(void);

/**
 * @brief Load matrix A into accelerator memory
 * @param matrix Pointer to 4x4 input matrix
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_load_matrix_a(const matrix_input_t matrix);

/**
 * @brief Load matrix B into accelerator memory
 * @param matrix Pointer to 4x4 input matrix
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_load_matrix_b(const matrix_input_t matrix);

/**
 * @brief Load both input matrices
 * @param matrix_a Pointer to matrix A
 * @param matrix_b Pointer to matrix B
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_load_matrices(const matrix_input_t matrix_a, 
                                                  const matrix_input_t matrix_b);

/**
 * @brief Start matrix multiplication operation
 * 
 * Triggers the accelerator to begin computation.
 * Matrices must be loaded first.
 * 
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_start(void);

/**
 * @brief Wait for operation to complete
 * @param timeout_cycles Maximum cycles to wait (0 = no timeout)
 * @return MATRIX_ACCEL_SUCCESS on success, MATRIX_ACCEL_ERROR_TIMEOUT on timeout
 */
matrix_accel_result_t matrix_accel_wait_done(uint32_t timeout_cycles);

/**
 * @brief Read result matrix from accelerator
 * @param result Pointer to output matrix buffer
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_read_result(matrix_output_t result);

/**
 * @brief Perform complete matrix multiplication operation
 * 
 * High-level function that performs the entire operation:
 * load matrices, start computation, wait for completion, read results.
 * 
 * @param matrix_a Input matrix A
 * @param matrix_b Input matrix B
 * @param result Output matrix C (A * B)
 * @param timeout_cycles Maximum cycles to wait for completion
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_multiply(const matrix_input_t matrix_a,
                                             const matrix_input_t matrix_b,
                                             matrix_output_t result,
                                             uint32_t timeout_cycles);

/**
 * @brief Reset the accelerator
 * 
 * Performs hardware reset to clear any stuck states.
 * 
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_reset(void);

/**
 * @brief Get accelerator status information
 * @param is_busy Pointer to store busy status
 * @param is_done Pointer to store done status
 * @return MATRIX_ACCEL_SUCCESS on success, error code otherwise
 */
matrix_accel_result_t matrix_accel_get_status(bool* is_busy, bool* is_done);

/**
 * @brief Convert error code to human-readable string
 * @param error Error code
 * @return String description of error
 */
const char* matrix_accel_error_string(matrix_accel_result_t error);

#endif // MATRIX_ACCEL_DRIVER_H 