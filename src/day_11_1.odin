#+private file
package aoc24

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

BLINKS :: 25

@(private)
day_11_1 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_11.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	stones: [dynamic]u64
	defer delete(stones)

	it := string(data)
	for num_str in strings.fields_iterator(&it) {
		number := u64(strconv.atoi(num_str))
		append(&stones, number)
	}

	for _ in 0 ..< BLINKS {
		for i := 0; i < len(stones); i += 1 {
			if stones[i] == 0 {
				stones[i] = 1
			} else if int_num_digits(stones[i]) % 2 == 0 {
				lhs, rhs := int_split_half(stones[i])
				stones[i] = lhs
				inject_at(&stones, i + 1, rhs)
				i += 1
			} else {
				stones[i] = stones[i] * 2024
			}
		}
	}

	fmt.println("Day 11.1: ", len(stones))
}

int_num_digits :: proc(number: u64) -> (count: u8 = 1) {
	temp := number / 10
	for temp != 0 {
		count += 1
		temp /= 10
	}
	return
}

int_split_half :: proc(number: u64) -> (lhs: u64, rhs: u64) {
	num_digits := int_num_digits(number)
	assert(num_digits % 2 == 0)
	half_num_digits := num_digits / 2
	order_of_magnitute := u64(1)
	for _ in 0 ..< half_num_digits {
		order_of_magnitute *= 10
	}
	lhs = number / order_of_magnitute
	rhs = number - lhs * order_of_magnitute
	return
}
