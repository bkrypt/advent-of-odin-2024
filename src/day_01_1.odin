package aoc24

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

day_01_1 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_01.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	list_left: [dynamic]i32
	defer delete(list_left)

	list_right: [dynamic]i32
	defer delete(list_right)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		fields := strings.fields(line)
		defer delete(fields)
		assert(len(fields) == 2)

		left_value := i32(strconv.atoi(fields[0]))
		append(&list_left, left_value)

		right_value := i32(strconv.atoi(fields[1]))
		append(&list_right, right_value)
	}

	slice.sort(list_left[:])
	slice.sort(list_right[:])
	assert(len(list_left) == len(list_right))

	sum := u32(0)
	for i in 0..<len(list_left) {
		distance := u32(math.abs(list_left[i] - list_right[i]))
		sum += distance
	}

	fmt.println("Day 01.1: ", sum)
}
