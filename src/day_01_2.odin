package aoc24

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

day_01_2 :: proc() {
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

	total_similarity_score := i32(0)

	i_left := 0
	i_right := 0
	for i_left < len(list_left) && i_right < len(list_right) {
		if list_left[i_left] < list_right[i_right] {
			i_left += 1
		} else if list_left[i_left] > list_right[i_right] {
			i_right += 1
		} else {
			count := i32(0)
			for list_left[i_left] == list_right[i_right] {
				count += 1
				i_right += 1
			}
			similarity_score := list_left[i_left] * count
			total_similarity_score += similarity_score
			for list_left[i_left] == list_left[i_left + 1] {
				total_similarity_score += similarity_score
				i_left += 1
			}
			i_left += 1
		}
	}

	fmt.println("Day 01.2: ", total_similarity_score)
}
