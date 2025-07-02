.global _main
.align 2
.data
    message: .asciz "Guess a number between 1 and 10.\n"
    invalid_message: .asciz "Invalid input.\n"
    less_message: .asciz "You guessed too high.\n"
    more_message: .asciz "You guessed too low.\n"
    success_message: .asciz "You guessed correctly.\n"
    generated_number: .int 8
    input_buf: .space 1024

.text
_main:
    bl _run_guess
    b _exit

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
    cmp x8, #1
    b.lt _invalid_input
    cmp x8, #10
    b.gt _invalid_input
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
    adrp x9, generated_number@PAGE          // Address of generated number page
    add  x9, x9, generated_number@PAGEOFF   // Generated number offset
    ldr  w9, [x9]                           // Load gen number into register
    cmp x9, x8                              // Compare generated and input
    b.lt _print_less                        // Branch less
    b.gt _print_more                        // Branch more 
    b _print_success                        // Branch success
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
    mov x0, #1                              // Set descriptor to 1 for stdout
    adrp x1, success_message@PAGE           // Load page address into register 1
    add x1, x1, success_message@PAGEOFF     // Add offset to address
    mov x2, #23                             // Set length of message
    mov x16, #4                             // Load sys_write
    svc #0x80                               // Execute system call

// Exit program successfully
_exit:
    mov x0, #0   // Set exit code 0
    mov x16, #1  // Load sys_exit
    svc #0x80    // Execute system call
