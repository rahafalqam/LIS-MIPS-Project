.data

# ==========================================
# Shared Variables
# ==========================================

input_array:   .space 400
result_array:  .space 400

n_count:       .word 0
lis_length:    .word 0

dp_array:      .space 400
prev_array:    .space 400

file_buffer:   .space 2049
fname_buffer:  .space 128
bytes_read:    .word 0
num_buffer: .space 12        #max. num. of digit = 12 , 11 char.+ 0\


# ==========================================
# Messages
# ==========================================

prompt_msg:    .asciiz "Enter input file name/path: "
success_msg:   .asciiz "File opened successfully.\n"

done_msg:      .asciiz "Done. Output written to output.txt\n"

err1_msg:      .asciiz "Error: cannot open/read/write file.\n"
err2_msg:      .asciiz "Error: input file contains invalid data.\n"
err3_msg:      .asciiz "Error: input file is empty.\n"
err4_msg:      .asciiz "Error: more than 100 integers.\n"

length_msg:    .asciiz "Length of Longest Increasing Subsequence: "
lis_msg:       .asciiz "Longest Increasing Subsequence:\n"

newline_msg:   .asciiz "\n"
space_msg:     .asciiz " "

output_fname: .asciiz "C:\\Users\\Rahaf\\Desktop\\ArchProject\\output.txt"


.align 2
err_table:
    .word 0
    .word err1_msg
    .word err2_msg
    .word err3_msg
    .word err4_msg


.text
.globl main


# ==========================================
# MAIN
# ==========================================

main:

    # Student A - Read input file
    jal readFile
    bnez $v1, program_exit

    # Student B - Parse and validate input
    jal parseInput
    bnez $v1, program_exit
    
  
    # Student C - Find LIS
    jal findLIS
    bnez $v1, program_exit

    # Student A - Write result to output file
    jal writeOutput


program_exit:

    # If status = 0, program completed successfully
    beqz $v1, exit_ok

    # Find error message using error code
    sll $t0, $v1, 2
    la $t1, err_table
    add $t1, $t1, $t0
    lw $a0, 0($t1)

    # Print error message
    li $v0, 4
    syscall

    j exit_now


exit_ok:

    # Print completion message
    li $v0, 4
    la $a0, done_msg
    syscall


exit_now:

    # Exit program
    li $v0, 10
    syscall



# ==========================================
# Student A - Read Input File
# ==========================================

readFile:

    # Print prompt
    li $v0, 4
    la $a0, prompt_msg
    syscall

    # Read file name
    li $v0, 8              # 8 = Read String
    la $a0, fname_buffer
    li $a1, 128
    syscall

    # Remove newline \n or \r from file name
    la $t0, fname_buffer


remove_newline:

    # Read current byte
    lb $t1, 0($t0)

    # If we reach \0, finish removing
    beq $t1, $zero, done_remove

    # Check for \n (ASCII 10)
    li $t2, 10
    beq $t1, $t2, replace_newline

    # Check for \r (ASCII 13)
    li $t2, 13
    beq $t1, $t2, replace_newline

    # Move to next byte
    addi $t0, $t0, 1
    j remove_newline


replace_newline:

    # Replace \n or \r with \0
    sb $zero, 0($t0)


done_remove:

    # Open input file
    li $v0, 13
    la $a0, fname_buffer
    li $a1, 0              # read only
    li $a2, 0
    syscall

    # Check if opening failed
    bltz $v0, read_open_error

    # Save input file descriptor
    move $t0, $v0

    # Read file content
    li $v0, 14
    move $a0, $t0
    la $a1, file_buffer
    li $a2, 2048
    syscall

    # Check if reading failed
    bltz $v0, read_after_open_error

    # Save number of bytes read
    sw $v0, bytes_read

    # Add \0 at end of buffer
    # so we know where the text ends
    la $t1, file_buffer
    lw $t2, bytes_read
    add $t1, $t1, $t2
    sb $zero, 0($t1)

    # Close input file
    li $v0, 16
    move $a0, $t0
    syscall

    # Print success message
    li $v0, 4
    la $a0, success_msg
    syscall

    # 0 = OK
    li $v1, 0

    # Return to main
    jr $ra


read_after_open_error:

    # Close file because it was opened successfully
    li $v0, 16
    move $a0, $t0
    syscall


read_open_error:

    # 1 = File error
    li $v1, 1

    # Return to main
    jr $ra



# ==========================================
# Student B - Parsing & Validation
# ==========================================

parseInput:

    # INPUT:
    # file_buffer = raw file content
    # bytes_read  = number of bytes read
    #
    # OUTPUT:
    # input_array = parsed integers
    # n_count     = number of integers
    #
    # Error codes:
    # 0 = OK
    # 2 = Invalid data
    # 3 = Empty file
    # 4 = More than 100 integers


    # ------------------------------------------
    # Initialize pointers and counter
    # ------------------------------------------

    la $t0, file_buffer        # $t0 points to current character in file_buffer
    la $t1, input_array        # $t1 points to next location in input_array
    li $t2, 0                 # $t2 = number of integers parsed
    sw $zero, n_count         # Initialize n_count to 0


    # ------------------------------------------
    # Skip whitespace between numbers
    # Space = 32, newline = 10
    # Tab = 9, carriage return = 13
    # ------------------------------------------

parse_skip_spaces:

    lb $t3, 0($t0)            # Load current character

    # End of file/string
    beq $t3, $zero, parse_finished

    # Space
    li $t4, 32
    beq $t3, $t4, parse_skip_one

    # Newline
    li $t4, 10
    beq $t3, $t4, parse_skip_one

    # Tab
    li $t4, 9
    beq $t3, $t4, parse_skip_one

    # Carriage return
    li $t4, 13
    beq $t3, $t4, parse_skip_one

    # Not whitespace -> start reading a number
    j parse_check_sign


parse_skip_one:

    addi $t0, $t0, 1          # Move to next character
    j parse_skip_spaces


    # ------------------------------------------
    # Check optional sign
    # $t5 = 0 -> positive
    # $t5 = 1 -> negative
    # ------------------------------------------

parse_check_sign:

    li $t5, 0                 # Assume positive number

    # Check for '-' ASCII = 45
    li $t4, 45
    bne $t3, $t4, parse_check_plus

    li $t5, 1                 # Mark number as negative
    addi $t0, $t0, 1          # Skip '-'
    j parse_require_digit


parse_check_plus:

    # Check for '+' ASCII = 43
    li $t4, 43
    bne $t3, $t4, parse_require_digit

    addi $t0, $t0, 1          # Skip '+'


    # ------------------------------------------
    # Make sure the number has at least one digit
    # Valid ASCII digits are 48 ('0') to 57 ('9')
    # ------------------------------------------

parse_require_digit:

    lb $t3, 0($t0)

    # Character < '0' -> invalid
    slti $t4, $t3, 48
    bne $t4, $zero, parse_invalid

    # Character >= ':' means > '9' -> invalid
    slti $t4, $t3, 58
    beq $t4, $zero, parse_invalid

    li $t6, 0                 # $t6 stores the integer value


    # ------------------------------------------
    # Read digits and build the integer
    # Formula: number = number * 10 + digit
    # ------------------------------------------

parse_digit_loop:

    lb $t3, 0($t0)            # Load current character

    # If character < '0', number is finished
    slti $t4, $t3, 48
    bne $t4, $zero, parse_number_done

    # If character > '9', number is finished
    slti $t4, $t3, 58
    beq $t4, $zero, parse_number_done

    # Convert ASCII digit to numeric digit
    # Example: '7' = 55 -> 55 - 48 = 7
    addi $t7, $t3, -48


    # ------------------------------------------
    # Check signed 32-bit overflow
    #
    # Maximum positive =  2147483647
    # Minimum negative = -2147483648
    # ------------------------------------------

    li $t8, 214748364

    # If current value > 214748364 -> overflow
    sltu $t9, $t8, $t6
    bne $t9, $zero, parse_invalid

    # If less than 214748364, current digit is safe
    bne $t6, $t8, parse_digit_safe

    # If equal to 214748364:
    # positive number can end with max digit 7
    li $t8, 7

    # negative number can end with max digit 8
    beq $t5, $zero, parse_check_last_digit
    li $t8, 8


parse_check_last_digit:

    # If digit > allowed last digit -> overflow
    sltu $t9, $t8, $t7
    bne $t9, $zero, parse_invalid


parse_digit_safe:

    # number * 10
    # number * 8 + number * 2 = number * 10
    sll $t8, $t6, 3
    sll $t9, $t6, 1
    addu $t6, $t8, $t9

    # number = number + digit
    addu $t6, $t6, $t7

    # Move to next character
    addi $t0, $t0, 1

    j parse_digit_loop


    # ------------------------------------------
    # Number finished
    # The next character must be whitespace
    # or the end of the file
    # ------------------------------------------

parse_number_done:

    # End of string
    beq $t3, $zero, parse_delimiter_ok

    # Space
    li $t4, 32
    beq $t3, $t4, parse_delimiter_ok

    # Newline
    li $t4, 10
    beq $t3, $t4, parse_delimiter_ok

    # Tab
    li $t4, 9
    beq $t3, $t4, parse_delimiter_ok

    # Carriage return
    li $t4, 13
    beq $t3, $t4, parse_delimiter_ok

    # Example: 12abc -> invalid
    j parse_invalid


    # ------------------------------------------
    # Check maximum input size
    # Maximum = 100 integers
    # ------------------------------------------

parse_delimiter_ok:

    slti $t4, $t2, 101
    beq $t4, $zero, parse_too_many


    # ------------------------------------------
    # Apply negative sign if needed
    # ------------------------------------------

    beq $t5, $zero, parse_store_number

    # value = 0 - value
    subu $t6, $zero, $t6


    # ------------------------------------------
    # Store parsed integer in input_array
    # ------------------------------------------

parse_store_number:

    sw $t6, 0($t1)            # Store integer in input_array

    addi $t1, $t1, 4          # Move to next integer location
                               # Each integer = 4 bytes

    addi $t2, $t2, 1          # Increment number counter

    # Search for next number
    j parse_skip_spaces


    # ------------------------------------------
    # Parsing completed successfully
    # ------------------------------------------

parse_finished:

    # If no integers were read -> empty file
    beq $t2, $zero, parse_empty

    # Save total number of integers
    sw $t2, n_count

    # Status 0 = success
    li $v1, 0
    jr $ra


    # ------------------------------------------
    # Error: invalid data
    # ------------------------------------------

parse_invalid:

    li $v1, 2
    jr $ra


    # ------------------------------------------
    # Error: empty file
    # ------------------------------------------

parse_empty:

    li $v1, 3
    jr $ra


    # ------------------------------------------
    # Error: more than 100 integers
    # ------------------------------------------

parse_too_many:

    li $v1, 4
    jr $ra

# ==========================================
# Student C - LIS Algorithm
# ==========================================


findLIS:
    addi $sp, $sp, -32
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $s6, 24($sp)
    sw $s7, 28($sp)

    la $t0, input_array
    lw $t1, n_count
    la $t2, dp_array
    la $t3, prev_array

    # dp[i] = 1, prev[i] = -1 for all i
    li $t4, 0
init_loop:
    bge $t4, $t1, init_done
    sll $t6, $t4, 2
    li $t5, 1
    add $t7, $t2, $t6
    sw $t5, 0($t7)
    li $t5, -1
    add $t7, $t3, $t6
    sw $t5, 0($t7)
    addi $t4, $t4, 1
    j init_loop
init_done:

    # main DP loops
    li $s0, 1
outer_loop:
    bge $s0, $t1, outer_done
    li $s1, 0
inner_loop:
    bge $s1, $s0, inner_done
    sll $t6, $s1, 2
    add $t7, $t0, $t6
    lw $s2, 0($t7)
    sll $t6, $s0, 2
    add $t7, $t0, $t6
    lw $s3, 0($t7)
    slt $t8, $s2, $s3
    beq $t8, $zero, inner_next
    sll $t6, $s1, 2
    add $t7, $t2, $t6
    lw $s4, 0($t7)
    addi $s4, $s4, 1
    sll $t6, $s0, 2
    add $t7, $t2, $t6
    lw $s5, 0($t7)
    slt $t8, $s5, $s4
    beq $t8, $zero, inner_next
    sw $s4, 0($t7)
    sll $t6, $s0, 2
    add $t7, $t3, $t6
    sw $s1, 0($t7)
inner_next:
    addi $s1, $s1, 1
    j inner_loop
inner_done:
    addi $s0, $s0, 1
    j outer_loop
outer_done:

    # find max dp[i]
    li $s0, 0
    li $s6, 0
    lw $s7, dp_array
find_max_loop:
    bge $s0, $t1, find_max_done
    sll $t6, $s0, 2
    add $t7, $t2, $t6
    lw $t8, 0($t7)
    slt $t9, $s7, $t8
    beq $t9, $zero, find_max_next
    move $s7, $t8
    move $s6, $s0
find_max_next:
    addi $s0, $s0, 1
    j find_max_loop
find_max_done:
    sw $s7, lis_length

    # backtrack using prev[] to build result
    move $s0, $s6
    lw $s1, lis_length
    la $s2, result_array
reconstruct_loop:
    beq $s1, $zero, reconstruct_done
    addi $s1, $s1, -1
    sll $t6, $s0, 2
    add $t7, $t0, $t6
    lw $t8, 0($t7)
    sll $t6, $s1, 2
    add $t7, $s2, $t6
    sw $t8, 0($t7)
    sll $t6, $s0, 2
    add $t7, $t3, $t6
    lw $s0, 0($t7)
    j reconstruct_loop
reconstruct_done:

    li $v1, 0
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $s6, 24($sp)
    lw $s7, 28($sp)
    addi $sp, $sp, 32
    jr $ra

# ==========================================
# Student A - Write Output File
# ==========================================

writeOutput:

    # Save $ra because this function uses jal
    # Save $s1 because it will hold output file descriptor
    addi $sp, $sp, -20
    sw $s1, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)
    sw $s4, 12($sp)
    sw $ra, 16($sp)

    # Open output file
    li $v0, 13
    la $a0, output_fname
    li $a1, 1              # write mode
    li $a2, 0
    syscall

    # Check if opening failed
    bltz $v0, write_file_error

    # Save output file descriptor
    move $s1, $v0


    # ------------------------------------------
    # Write length message
    # ------------------------------------------

    la $a0, length_msg
    jal strlen

    # $v0 = string length
    move $a2, $v0

    li $v0, 15
    move $a0, $s1
    la $a1, length_msg
    syscall

    # Check if writing failed
    bltz $v0, write_file_error_open


    # ==========================================
    # LIS LENGTH GOES HERE
    # lis_length is produced by Student C
    # Student B's intToString can be used here
    lw $a0, lis_length
    la $a1, num_buffer
    jal intToString

    move $a2, $v0
    li $v0, 15
    move $a0, $s1
    la $a1, num_buffer
    syscall
    bltz $v0, write_file_error_open

    li $v0, 15
    move $a0, $s1
    la $a1, newline_msg
    li $a2, 1
    syscall
    bltz $v0, write_file_error_open
    # ==========================================


    # ------------------------------------------
    # Write LIS title
    # ------------------------------------------

    la $a0, lis_msg
    jal strlen

    # $v0 = string length
    move $a2, $v0

    li $v0, 15
    move $a0, $s1
    la $a1, lis_msg
    syscall

    # Check if writing failed
    bltz $v0, write_file_error_open


    # ==========================================
    # LIS RESULT GOES HERE
    # result_array and lis_length are produced
    # by Student C
    # Write result_array elements here
    la $s2, result_array
    lw $s3, lis_length
    li $s4, 0

write_lis_loop:
    beq $s4, $s3, write_lis_done

    lw $a0, 0($s2)
    la $a1, num_buffer
    jal intToString

    move $a2, $v0
    li $v0, 15
    move $a0, $s1
    la $a1, num_buffer
    syscall
    bltz $v0, write_file_error_open

    addi $t0, $s4, 1
    beq $t0, $s3, write_lis_newline

    li $v0, 15
    move $a0, $s1
    la $a1, space_msg
    li $a2, 1
    syscall
    bltz $v0, write_file_error_open
    j write_lis_next

write_lis_newline:
    li $v0, 15
    move $a0, $s1
    la $a1, newline_msg
    li $a2, 1
    syscall
    bltz $v0, write_file_error_open

write_lis_next:
    addi $s2, $s2, 4
    addi $s4, $s4, 1
    j write_lis_loop

write_lis_done:
    # ==========================================


    # Close output file
    li $v0, 16
    move $a0, $s1
    syscall

    # 0 = OK
    li $v1, 0

    j write_output_return


write_file_error_open:

    # Close output file if it was already opened
    li $v0, 16
    move $a0, $s1
    syscall


write_file_error:

    # 1 = File error
    li $v1, 1


write_output_return:

    # Restore saved registers
    lw $s1, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    lw $s4, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20

    # Return to main
    jr $ra



# ==========================================
# Helper Function - strlen
# ==========================================
strlen:

    # INPUT:
    # $a0 = address of string
    #
    # OUTPUT:
    # $v0 = string length
    #
    # $a0 is not changed

    li $v0, 0
    move $t8, $a0

strlen_loop:

    lb $t9, 0($t8)
    beq $t9, $zero, strlen_done

    addi $v0, $v0, 1
    addi $t8, $t8, 1

    j strlen_loop

strlen_done:

    jr $ra
   
  # ==========================================
# Student B - Integer to String
# ==========================================

intToString:

    # INPUT:
    # $a0 = signed integer value
    # $a1 = address of output buffer
    #
    # OUTPUT:
    # $v0 = number of characters
    #
    # Example:
    # 123  -> "123"
    # -45  -> "-45"
    # 0    -> "0"


    # ------------------------------------------
    # Initialize
    # ------------------------------------------

    move $t0, $a0             # $t0 = integer value
    move $t1, $a1             # $t1 = output buffer pointer
    li $t2, 0                 # $t2 = number of output characters


    # Special case: number = 0
    beq $t0, $zero, int_zero

    # Check if number is negative
    bltz $t0, int_negative

    # Positive number
    move $t3, $t0
    j int_make_digits


    # ------------------------------------------
    # Handle negative number
    # ------------------------------------------

int_negative:

    # Store '-' sign
    li $t4, 45                # ASCII '-' = 45
    sb $t4, 0($t1)

    addi $t1, $t1, 1          # Move output pointer
    addi $t2, $t2, 1          # Count '-' character

    # Get unsigned magnitude
    # Works also for -2147483648 with divu
    subu $t3, $zero, $t0


    # ------------------------------------------
    # Convert number into decimal digits
    # ------------------------------------------

int_make_digits:

    # Reserve temporary stack space
    # Maximum decimal digits = 10
    addi $sp, $sp, -16

    move $t4, $sp             # $t4 = temporary digit pointer
    li $t5, 0                 # $t5 = number of digits
    li $t6, 10                # Divisor = 10


int_digit_loop:

    # Divide number by 10
    divu $t3, $t6

    # Remainder = current digit
    mfhi $t7

    # Quotient = remaining number
    mflo $t3

    # Convert numeric digit to ASCII
    addi $t7, $t7, 48

    # Store digit temporarily
    # Digits are generated in reverse order
    sb $t7, 0($t4)

    addi $t4, $t4, 1
    addi $t5, $t5, 1

    # Continue until quotient becomes zero
    bne $t3, $zero, int_digit_loop


    # Point to last stored digit
    addi $t4, $t4, -1


    # ------------------------------------------
    # Reverse digits into output buffer
    # Example:
    # temporary = 3 2 1
    # output    = 1 2 3
    # ------------------------------------------

int_reverse_loop:

    beq $t5, $zero, int_done

    # Read digit from temporary stack
    lb $t7, 0($t4)

    # Store digit in output buffer
    sb $t7, 0($t1)

    addi $t4, $t4, -1
    addi $t1, $t1, 1

    addi $t5, $t5, -1
    addi $t2, $t2, 1

    j int_reverse_loop


    # ------------------------------------------
    # Finish string
    # ------------------------------------------

int_done:

    # Add null terminator '\0'
    sb $zero, 0($t1)

    # Restore stack
    addi $sp, $sp, 16

    # Return number of characters
    move $v0, $t2

    jr $ra


    # ------------------------------------------
    # Special case: integer = 0
    # ------------------------------------------

int_zero:

    li $t4, 48                # ASCII '0' = 48
    sb $t4, 0($t1)

    addi $t1, $t1, 1

    # Add null terminator
    sb $zero, 0($t1)

    # String length = 1
    li $v0, 1

    jr $ra
