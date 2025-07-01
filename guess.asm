.global _main
.align 2
.data
    message: .asciz "Guess a number between 1 and 10.\n"
    less_message: .asciz "Less\n"
    more_message: .asciz "More\n"
    success_message: .asciz "You guessed correctly\n"
    generated_number: .int 8
    input_buf: .space 1024

.text
_main:
    bl _write_message
    bl _read_guess
    bl _ascii_to_int
    bl _with_input
    b _exit

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
    // Reload buffer since syscall empties the register
    adrp x1, input_buf@PAGE         // Load buffer page
    add x1, x1, input_buf@PAGEOFF   // Get offset for buffer
    ldrb w0, [x1]                   // Load character from input buffer into w0
    cmp w0, #'0'                    // Compare ascii with lower bound
    b.lt _ascii_to_int_return       // Branch when less
    cmp w0, #'9'                    // Compare ascii with upper bound
    b.gt _ascii_to_int_return       // Branch when more
    sub w0, w0, #'0'                // Subtract to get integer value
    // Setup registers to store final integer in x8
    mov x8, x0                      // Initialize x8
    add x1, x1, #1                  // Move to next character in buffer
    mov x4, #10                     // Will need 10 for multiplying later
    b _ascii_to_int_next

_ascii_to_int_next:
    ldrb w0, [x1]                   // Load character from input buffer into w0
    cmp w0, #'0'                    // Compare ascii with lower bound
    b.lt _ascii_to_int_return       // Branch when less
    cmp w0, #'9'                    // Compare ascii with upper bound
    b.gt _ascii_to_int_return       // Branch when more
    sub w0, w0, #'0'                // Subtract to get integer value
    mul x8, x8, x4                  // Multiply by 10 to add digit
    add x8, x8, x0                  // Add character to result
    add x1, x1, #1                  // Move to next character in buffer
    b _ascii_to_int_next            // Loop

_ascii_to_int_return:
    ret

// have input as int at x8
_with_input:
    adrp x9, generated_number@PAGE          // Address of generated number page
    add  x9, x9, generated_number@PAGEOFF   // Generated number offset
    ldr  w9, [x9]                           // Load gen number into register
    cmp x9, x8                              // Compare generated and input
    b.lt _print_less                        // Branch less
    b.gt _print_more                        // Branch more 
    b _print_success                        // Branch success

// Print less message
_print_less:
    mov x0, #1                          // Set descriptor to 1 for stdout
    adrp x1, less_message@PAGE          // Load page address into register 1
    add x1, x1, less_message@PAGEOFF    // Add offset to address
    mov x2, #5                          // Set length of message
    mov x16, #4                         // Load sys_write
    svc #0x80                           // Execute system call
    ret

// Print more message
_print_more:
    mov x0, #1                          // Set descriptor to 1 for stdout
    adrp x1, more_message@PAGE          // Load page address into register 1
    add x1, x1, more_message@PAGEOFF    // Add offset to address
    mov x2, #5                          // Set length of message
    mov x16, #4                         // Load sys_write
    svc #0x80                           // Execute system call
    ret

// Print success message
_print_success:
    mov x0, #1                              // Set descriptor to 1 for stdout
    adrp x1, success_message@PAGE           // Load page address into register 1
    add x1, x1, success_message@PAGEOFF     // Add offset to address
    mov x2, #22                             // Set length of message
    mov x16, #4                             // Load sys_write
    svc #0x80                               // Execute system call
    ret

// Exit program successfully
_exit:
    mov x0, #0                      // Set exit code 0
    mov x16, #1                     // Load sys_exit
    svc #0x80                       // Execute system call
