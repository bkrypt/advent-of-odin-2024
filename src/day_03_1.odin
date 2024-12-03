#+private file
package aoc24

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:unicode"

LEN_MUL_NAME :: len("mul")
LEN_MUL_ARGS :: len("(123,456)")
LEN_MUL :: LEN_MUL_NAME + LEN_MUL_ARGS

@(private)
day_03_1 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_03.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	memory := string(data)
	memory_loc := 0

	mul_sum := 0

	for memory_loc < len(memory) {
		// look for "mul"
		if memory_loc < len(memory) - LEN_MUL &&
		   strings.compare(memory[memory_loc:memory_loc + LEN_MUL_NAME], "mul") == 0 {
			// check if it is followed by '('
			start := memory_loc + LEN_MUL_NAME
			if start < len(memory) && memory[start] == '(' {
				end := start + 1
				// find closing ')'
				end_max := start + LEN_MUL_ARGS
				for end < end_max && memory[end] != ')' {
					end += 1
				}
				// closing ')' found
				if end < end_max {
					args := strings.split(memory[start + 1:end], ",")
					defer delete(args)
					// extract, validate and process arguments
					if len(args) == 2 && is_all_digits(args[0]) && is_all_digits(args[1]) {
						lhs := strconv.atoi(args[0])
						rhs := strconv.atoi(args[1])
						mul_sum += lhs * rhs
					}
					memory_loc = end
				}
			}
		}

		memory_loc += 1
	}

	fmt.println("Day 03.1: ", mul_sum)
}

is_all_digits :: proc(input: string) -> bool {
	for c in input {
		if !unicode.is_digit(c) {
			return false
		}
	}
	return true
}
