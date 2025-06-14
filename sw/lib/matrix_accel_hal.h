/**
 * @file matrix_accel_hal.h
 * @brief Hardware Abstraction Layer for Matrix Multiplication Accelerator
 * 
 * This file provides low-level hardware access functions for the memory-mapped
 * matrix multiplication accelerator. It defines register addresses, bit fields,
 * and basic read/write operations.
 * 
 * Memory Map:
 * 0x10000000: CONTROL   [bit 0: start, bit 1: reset]
 * 0x10000004: STATUS    [bit 0: done, bit 1: busy] 
 * 0x10000008: CONFIG    [matrix dimensions]
 * 0x10000100: Matrix A  [4x4 matrix, 8-bit elements]
 * 0x10000200: Matrix B  [4x4 matrix, 8-bit elements]
 * 0x10000300: Matrix C  [4x4 matrix, 32-bit results]
 */

#ifndef MATRIX_ACCEL_HAL_H
#define MATRIX_ACCEL_HAL_H

#include <stdint.h>

// Base address of matrix accelerator
#define MATRIX_ACCEL_BASE       0x10000000UL

// Register offsets
#define CONTROL_REG_OFFSET      0x00000000UL
#define STATUS_REG_OFFSET       0x00000004UL
#define CONFIG_REG_OFFSET       0x00000008UL
#define MATRIX_A_BASE_OFFSET    0x00000100UL
#define MATRIX_B_BASE_OFFSET    0x00000200UL
#define MATRIX_C_BASE_OFFSET    0x00000300UL

// Register addresses
#define CONTROL_REG_ADDR        (MATRIX_ACCEL_BASE + CONTROL_REG_OFFSET)
#define STATUS_REG_ADDR         (MATRIX_ACCEL_BASE + STATUS_REG_OFFSET)
#define CONFIG_REG_ADDR         (MATRIX_ACCEL_BASE + CONFIG_REG_OFFSET)
#define MATRIX_A_BASE_ADDR      (MATRIX_ACCEL_BASE + MATRIX_A_BASE_OFFSET)
#define MATRIX_B_BASE_ADDR      (MATRIX_ACCEL_BASE + MATRIX_B_BASE_OFFSET)
#define MATRIX_C_BASE_ADDR      (MATRIX_ACCEL_BASE + MATRIX_C_BASE_OFFSET)

// Control register bit definitions
#define CONTROL_START_BIT       (1 << 0)
#define CONTROL_RESET_BIT       (1 << 1)

// Status register bit definitions
#define STATUS_DONE_BIT         (1 << 0)
#define STATUS_BUSY_BIT         (1 << 1)

// Matrix dimensions (fixed for this implementation)
#define MATRIX_SIZE             4
#define MATRIX_ELEMENTS         (MATRIX_SIZE * MATRIX_SIZE)

// Data type definitions
typedef uint8_t  matrix_element_t;    // Input matrix element type
typedef uint32_t matrix_result_t;     // Output matrix element type

/**
 * @brief Read a 32-bit value from a memory-mapped register
 * @param addr Register address
 * @return Register value
 */
static inline uint32_t hal_read_reg32(volatile uint32_t* addr) {
    return *addr;
}

/**
 * @brief Write a 32-bit value to a memory-mapped register
 * @param addr Register address
 * @param value Value to write
 */
static inline void hal_write_reg32(volatile uint32_t* addr, uint32_t value) {
    *addr = value;
}

/**
 * @brief Read control register
 * @return Control register value
 */
static inline uint32_t hal_read_control(void) {
    return hal_read_reg32((volatile uint32_t*)CONTROL_REG_ADDR);
}

/**
 * @brief Write control register
 * @param value Control register value
 */
static inline void hal_write_control(uint32_t value) {
    hal_write_reg32((volatile uint32_t*)CONTROL_REG_ADDR, value);
}

/**
 * @brief Read status register
 * @return Status register value
 */
static inline uint32_t hal_read_status(void) {
    return hal_read_reg32((volatile uint32_t*)STATUS_REG_ADDR);
}

/**
 * @brief Read config register
 * @return Config register value
 */
static inline uint32_t hal_read_config(void) {
    return hal_read_reg32((volatile uint32_t*)CONFIG_REG_ADDR);
}

/**
 * @brief Write config register
 * @param value Config register value
 */
static inline void hal_write_config(uint32_t value) {
    hal_write_reg32((volatile uint32_t*)CONFIG_REG_ADDR, value);
}

/**
 * @brief Write a single element to matrix A
 * @param index Element index (0-15 for 4x4 matrix)
 * @param value Element value
 */
static inline void hal_write_matrix_a_element(int index, matrix_element_t value) {
    volatile uint32_t* addr = (volatile uint32_t*)(MATRIX_A_BASE_ADDR + (index * 4));
    hal_write_reg32(addr, (uint32_t)value);
}

/**
 * @brief Write a single element to matrix B
 * @param index Element index (0-15 for 4x4 matrix)
 * @param value Element value
 */
static inline void hal_write_matrix_b_element(int index, matrix_element_t value) {
    volatile uint32_t* addr = (volatile uint32_t*)(MATRIX_B_BASE_ADDR + (index * 4));
    hal_write_reg32(addr, (uint32_t)value);
}

/**
 * @brief Read a single element from matrix C
 * @param index Element index (0-15 for 4x4 matrix)
 * @return Element value
 */
static inline matrix_result_t hal_read_matrix_c_element(int index) {
    volatile uint32_t* addr = (volatile uint32_t*)(MATRIX_C_BASE_ADDR + (index * 4));
    return (matrix_result_t)hal_read_reg32(addr);
}

#endif // MATRIX_ACCEL_HAL_H 