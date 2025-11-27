// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

//! Test WASM modules for the Munition framework.
//!
//! This crate provides simple WASM functions for testing:
//! - Fuel consumption and exhaustion
//! - Memory isolation
//! - Trap handling and forensic capture
//! - Stateful computation

#![no_std]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// ============================================================================
// Basic Operations
// ============================================================================

/// Add two numbers
#[no_mangle]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a.wrapping_add(b)
}

/// Multiply two numbers
#[no_mangle]
pub extern "C" fn multiply(a: i32, b: i32) -> i32 {
    a.wrapping_mul(b)
}

/// Factorial (recursive, consumes more fuel)
#[no_mangle]
pub extern "C" fn factorial(n: i32) -> i64 {
    if n <= 1 {
        1
    } else {
        (n as i64).wrapping_mul(factorial(n - 1))
    }
}

// ============================================================================
// Fuel Consumption
// ============================================================================

/// Spin for a number of iterations, consuming fuel
#[no_mangle]
pub extern "C" fn spin(iterations: i32) -> i32 {
    let mut acc: i32 = 0;
    for i in 0..iterations {
        acc = acc.wrapping_add(i);
    }
    acc
}

/// Infinite loop - will always exhaust fuel
#[no_mangle]
pub extern "C" fn infinite_loop() -> i32 {
    let mut x: i32 = 0;
    loop {
        x = x.wrapping_add(1);
    }
}

/// Nested loops - consumes fuel quadratically
#[no_mangle]
pub extern "C" fn nested_loops(n: i32) -> i32 {
    let mut acc: i32 = 0;
    for i in 0..n {
        for j in 0..n {
            acc = acc.wrapping_add(i.wrapping_mul(j));
        }
    }
    acc
}

// ============================================================================
// Memory Operations
// ============================================================================

/// Static buffer for memory tests
static mut BUFFER: [u8; 1024] = [0u8; 1024];

/// Write a pattern to the buffer
#[no_mangle]
pub extern "C" fn write_pattern(pattern: u8, length: i32) -> i32 {
    let len = length.min(1024) as usize;
    unsafe {
        for i in 0..len {
            BUFFER[i] = pattern;
        }
    }
    len as i32
}

/// Read a byte from the buffer
#[no_mangle]
pub extern "C" fn read_buffer(index: i32) -> i32 {
    if index >= 0 && index < 1024 {
        unsafe { BUFFER[index as usize] as i32 }
    } else {
        -1
    }
}

/// Scan buffer for a pattern byte
#[no_mangle]
pub extern "C" fn scan_for_pattern(pattern: u8) -> i32 {
    unsafe {
        for i in 0..1024 {
            if BUFFER[i] == pattern {
                return i as i32;
            }
        }
    }
    -1
}

/// Fill buffer with incrementing values
#[no_mangle]
pub extern "C" fn fill_incrementing() -> i32 {
    unsafe {
        for i in 0..1024 {
            BUFFER[i] = (i % 256) as u8;
        }
    }
    1024
}

// ============================================================================
// Deliberate Crashes (Traps)
// ============================================================================

/// Trigger out of bounds memory access
#[no_mangle]
pub extern "C" fn trap_out_of_bounds() -> i32 {
    unsafe {
        let ptr = 0xFFFF_FFFF as *const i32;
        *ptr
    }
}

/// Trigger unreachable instruction
#[no_mangle]
pub extern "C" fn trap_unreachable() -> i32 {
    core::arch::wasm32::unreachable()
}

/// Division by zero (may or may not trap depending on WASM semantics)
#[no_mangle]
pub extern "C" fn trap_div_zero(a: i32) -> i32 {
    a / 0
}

// ============================================================================
// Stateful Computation (for forensic testing)
// ============================================================================

/// Global state counter
static mut STATE: i32 = 0;

/// History of state changes
static mut HISTORY: [i32; 100] = [0i32; 100];

/// Current history index
static mut HISTORY_INDEX: usize = 0;

/// Increment state and record in history
#[no_mangle]
pub extern "C" fn stateful_increment() -> i32 {
    unsafe {
        STATE = STATE.wrapping_add(1);
        if HISTORY_INDEX < 100 {
            HISTORY[HISTORY_INDEX] = STATE;
            HISTORY_INDEX += 1;
        }
        STATE
    }
}

/// Get current state value
#[no_mangle]
pub extern "C" fn get_state() -> i32 {
    unsafe { STATE }
}

/// Reset state to zero
#[no_mangle]
pub extern "C" fn reset_state() -> i32 {
    unsafe {
        STATE = 0;
        HISTORY_INDEX = 0;
        for i in 0..100 {
            HISTORY[i] = 0;
        }
    }
    0
}

/// Increment n times then crash
///
/// This is useful for forensic testing - we can verify that the
/// memory dump contains STATE = n after the crash
#[no_mangle]
pub extern "C" fn crash_after_n(n: i32) -> i32 {
    unsafe {
        for _ in 0..n {
            STATE = STATE.wrapping_add(1);
            if HISTORY_INDEX < 100 {
                HISTORY[HISTORY_INDEX] = STATE;
                HISTORY_INDEX += 1;
            }
        }
        // Now crash - forensics should show STATE = n
        core::arch::wasm32::unreachable()
    }
}

/// Increment until fuel exhaustion
///
/// Returns the state value at exhaustion point
#[no_mangle]
pub extern "C" fn increment_until_exhausted() -> i32 {
    unsafe {
        loop {
            STATE = STATE.wrapping_add(1);
            if HISTORY_INDEX < 100 {
                HISTORY[HISTORY_INDEX] = STATE;
                HISTORY_INDEX += 1;
            }
        }
    }
}

// ============================================================================
// Complex Computations
// ============================================================================

/// Fibonacci (exponential time without memoization)
#[no_mangle]
pub extern "C" fn fib(n: i32) -> i64 {
    if n <= 1 {
        n as i64
    } else {
        fib(n - 1).wrapping_add(fib(n - 2))
    }
}

/// Prime check (trial division)
#[no_mangle]
pub extern "C" fn is_prime(n: i32) -> i32 {
    if n <= 1 {
        return 0;
    }
    if n <= 3 {
        return 1;
    }
    if n % 2 == 0 || n % 3 == 0 {
        return 0;
    }
    let mut i = 5;
    while i * i <= n {
        if n % i == 0 || n % (i + 2) == 0 {
            return 0;
        }
        i += 6;
    }
    1
}

/// Count primes up to n (Sieve-ish)
#[no_mangle]
pub extern "C" fn count_primes(n: i32) -> i32 {
    let mut count = 0;
    for i in 2..=n {
        if is_prime(i) == 1 {
            count += 1;
        }
    }
    count
}
