
# Longest Increasing Subsequence (LIS) Using MIPS Assembly

## Project Overview
This project implements the Longest Increasing Subsequence (LIS) algorithm using MIPS Assembly for the ENCS4370 Computer Architecture course.

The program reads integers from an input text file, calculates the longest increasing subsequence, and writes the result to an output text file.

## Features
- Reads integers from a text file.
- Validates input data.
- Handles file-opening errors.
- Calculates the length of the Longest Increasing Subsequence.
- Outputs the LIS length and subsequence to a text file.

## Input Format
The input file contains whitespace-separated signed 32-bit integers.

**Maximum input size:** 100 integers.

Example:
```text
3 10 2 1 20
```

## Output
The output file contains the length of the LIS and the subsequence found by the program.

Example:
```text
LIS Length: 3
LIS: 3 10 20
```

*The example above illustrates the expected format; actual output depends on the input.*

## Requirements
- MARS MIPS Simulator
- MIPS Assembly source file

## How to Run
1. Open the `.asm` source file in MARS.
2. Make sure the input and output file paths are configured correctly.
3. Assemble the program.
4. Run the program and follow any filename prompts.
5. Check the output text file for the result.

## Project Files
- `code A_B and C.asm` — MIPS Assembly source code.
- `input.txt` — Input integers.
- `output.txt` — Output file.
- `README.md` — Project documentation.

## Notes
- The input must contain no more than 100 integers.
- File paths may need to be updated for your computer.
- The program should be tested in MARS before submission.

## Course
**ENCS4370 — Computer Architecture**

