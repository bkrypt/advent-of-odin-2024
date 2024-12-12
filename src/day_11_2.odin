#+private file
package aoc24

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

BLINKS :: 75

@(private)
day_11_2 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_11.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	stones := make(map[u64]u64)
	defer delete(stones)

	it := string(data)
	for num_str in strings.fields_iterator(&it) {
		number := u64(strconv.atoi(num_str))
		stones[number] += 1
	}

	for blink in 0 ..< BLINKS {
		snapshot, snapshot_err := slice.map_entries(stones)
		assert(snapshot_err == nil)
		defer delete(snapshot)

		for entry in snapshot {
			stone := entry.key
			count := entry.value

			if stone == 0 {
				stones[0] -= count
				stones[1] += count
			} else if int_num_digits(stone) % 2 == 0 {
				lhs, rhs := int_split_half(stone)
				stones[stone] -= count
				stones[lhs] += count
				stones[rhs] += count
			} else {
				stones[stone] -= count
				stones[stone * 2024] += count
			}

			if stones[stone] == 0 {
				delete_key(&stones, stone)
			}
		}
	}

	total_stones := u64(0)
	for stone, count in stones {
		total_stones += count
	}

	fmt.println("Day 11.1: ", total_stones)
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
