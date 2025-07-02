.global _main
.align 2
.data
    message: .asciz "Guess a number between 1 and 10.\n"
    invalid_message: .asciz "Invalid input.\n"
    less_message: .asciz "You guessed too high.\n"
    more_message: .asciz "You guessed too low.\n"
    success_message: .asciz "You guessed correctly.\n"
    generated_number: .int 0
    input_buf: .space 1024

.text
_main:
    bl _generate_number
    bl _run_guess
    b _exit

// Generates the number to be guessed. Uses the linear congruential generator 
// algorithm to get a pseudorandom number. The algorithm is described by the
// following recurrence relation:
//  X_n+1 = (a X_n + c) mod m
// Where:
//  "Modulus (m)"    0 < m
//  "Multiplier (a)" 0 < a < m
//  "Increment (c)"  0 <= c < m
//  "Seed (X_0)"     0 <= X_0 < m
_generate_number:
    // Get unix epoch for the seed.
    sub sp, sp, #16                         // Allocate space on stack
    mov x0, sp                              // Point register to space on stack
    mov x16, #116                           // Load gettimeofday syscall
    svc #0x80                               // Syscall
    ldr x0, [sp]                            // Load value from stack pointer
    add sp, sp, #16                         // Deallocate stack space

    // Perform calculation. Note the seed should be set to the result of the 
    // calculation for successive generations, but there is no need as the game
    // currently only has one guessing loop.
    mov x3, x0                              // Set seed
    mov x0, x3                              // Set m
    add x0, x0, #9                          // Increment. m must be greater than seed
    mov x1, #20                             // Set a less than m
    mov x2, #43                             // Set c less than m
    
    // perform X_n+1 = (a X_n + c) mod m
    mul x1, x1, x3                          // X_n+1 = (x1 + c) mod m
    add x1, x1, x2                          // X_n+1 = (x1) mod m

    // Mod is multiple steps for example
    // a % b
    // c = a / b
    // d = c * b
    // result = a - d
    udiv x4, x1, x0                         // x4 = x1 / x0
    mul x5, x4, x0                          // x5 = x4 * x0
    sub x1, x1, x5                          // x1 = x1 - x5

    // mod again by 10 to get number 0-9
    mov x7, #10
    udiv x4, x1, x7                         // x4 = x1 / x7
    mul x5, x4, x7                          // x5 = x4 * x7
    sub x1, x1, x5                          // x1 = x1 - x5
    add x1, x1, #1                          // Add 1 to get 1-10

    // Store in generated_number for later use
    adrp x6, generated_number@PAGE          // Load page for generated number
    add x6, x6, generated_number@PAGEOFF    // Get offset
    str w1, [x6]                            // Store calculated number
    ret

// Runs through guess sequence. Used to loop until a guess is correct.
_run_guess:
    bl _write_message
    bl _read_guess
    bl _ascii_to_int
    bl _with_input
    ret

// Write message
_write_message:
    mov x0, #1                      // Set descriptor to 1 for stdout
    adrp x1, message@PAGE           // Load page address into register 1
    add x1, x1, message@PAGEOFF     // Add offset to address
    mov x2, #33                     // Set length of message
    mov x16, #4                     // Load sys_write
    svc #0x80                       // Execute system call
    ret                             // Return to call site

// Read user guess
_read_guess:
    mov x0, #0                      // Set descriptor to 0 for stdin
    adrp x1, input_buf@PAGE         // Load buffer page
    add x1, x1, input_buf@PAGEOFF   // Get offset for buffer
    mov x2, #1024                   // Set buffer length
    mov x16, #3                     // Load sys_read
    svc #0x80                       // Execute system call
    ret                             // Return to call site

// Convert ascii buffer to integer
_ascii_to_int:
    adrp x1, input_buf@PAGE         // Load buffer page
    add x1, x1, input_buf@PAGEOFF   // Get offset for buffer
    ldrb w0, [x1]                   // Load character from input buffer into w0
    cmp w0, #'0'                    // Compare ascii with lower bound
    b.lt _invalid_input             // Branch when less
    cmp w0, #'9'                    // Compare ascii with upper bound
    b.gt _invalid_input             // Branch when more
    sub w0, w0, #'0'                // Subtract to get integer value
    // Setup registers to store final integer in x8
    mov x8, x0                      // Initialize x8
    add x1, x1, #1                  // Move to next character in buffer
    mov x4, #10                     // Will need 10 for multiplying later
    b _ascii_to_int_next

_ascii_to_int_next:
    ldrb w0, [x1]                   // Load character from input buffer into w0
    cmp w0, #0x0A                   // Compare with ASCII LF for end of input
    b.eq _ascii_to_int_return       // Branch for end of input
    cmp w0, #'0'                    // Compare ascii with lower bound
    b.lt _invalid_input             // Branch when less
    cmp w0, #'9'                    // Compare ascii with upper bound
    b.gt _invalid_input             // Branch when more
    sub w0, w0, #'0'                // Subtract to get integer value
    mul x8, x8, x4                  // Multiply by 10 to add digit
    add x8, x8, x0                  // Add character to result
    add x1, x1, #1                  // Move to next character in buffer
    b _ascii_to_int_next            // Loop

_ascii_to_int_return:
    cmp x8, #1                      // Compare input with 1
    b.lt _invalid_input             // Invalid branch when less than 1
    cmp x8, #10                     // Compare input with 10
    b.gt _invalid_input             // Invalid branch when greater than 10
    ret

// Print invalid input message and re-prompt
_invalid_input:
    mov x0, #1                          // Set descriptor to 1 for stdout
    adrp x1, invalid_message@PAGE       // Load page address into register 1
    add x1, x1, invalid_message@PAGEOFF // Add offset to address
    mov x2, #15                         // Set length of message
    mov x16, #4                         // Load sys_write
    svc #0x80                           // Execute system call
    b _run_guess

// have input as int at x8
_with_input:
    adrp x9, generated_number@PAGE        // Address of generated number page
    add  x9, x9, generated_number@PAGEOFF // Generated number offset
    ldr  w9, [x9]                         // Load gen number into register
    cmp x9, x8                            // Compare generated and input
    b.lt _print_less                      // Branch less
    b.gt _print_more                      // Branch more 
    b _print_success                      // Branch success
    b _exit

// Print less message
_print_less:
    mov x0, #1                          // Set descriptor to 1 for stdout
    adrp x1, less_message@PAGE          // Load page address into register 1
    add x1, x1, less_message@PAGEOFF    // Add offset to address
    mov x2, #22                         // Set length of message
    mov x16, #4                         // Load sys_write
    svc #0x80                           // Execute system call
    b _run_guess

// Print more message
_print_more:
    mov x0, #1                          // Set descriptor to 1 for stdout
    adrp x1, more_message@PAGE          // Load page address into register 1
    add x1, x1, more_message@PAGEOFF    // Add offset to address
    mov x2, #21                         // Set length of message
    mov x16, #4                         // Load sys_write
    svc #0x80                           // Execute system call
    b _run_guess

// Print success message
_print_success:
    mov x0, #1                          // Set descriptor to 1 for stdout
    adrp x1, success_message@PAGE       // Load page address into register 1
    add x1, x1, success_message@PAGEOFF // Add offset to address
    mov x2, #23                         // Set length of message
    mov x16, #4                         // Load sys_write
    svc #0x80                           // Execute system call

// Exit program successfully
_exit:
    mov x0, #0                          // Set exit code 0
    mov x16, #1                         // Load sys_exit
    svc #0x80                           // Execute system call
