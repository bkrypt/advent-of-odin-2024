#+private file
package aoc24

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

Block_Type :: enum (u8) {
	File,
	Free_Space,
}

EMPTY_BLOCK :: ~u16(0)

@(private)
day_09_1 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_09.txt")
	if !data_ok do panic("faile to load input")
	defer delete(data)

	disk := make([dynamic]u16)
	defer delete(disk)

	disk_map := string(data)
	if disk_map[len(disk_map) - 1] == '\n' {
		disk_map = disk_map[:len(disk_map) - 1]
	}

	block_type := Block_Type.File
	file_id := ~u16(0)

	map_loop: for char, i in disk_map {
		block_length := u8(char) - '0'
		switch block_type {
		case .File:
			file_id += 1
			for _ in 0 ..< block_length {
				append(&disk, file_id)
			}
		case .Free_Space:
			for _ in 0 ..< block_length {
				append(&disk, EMPTY_BLOCK)
			}
		}
		block_type_toggle(&block_type)
	}

	head_index := 0
	tail_index := len(disk) - 1
	defrag_loop: for {
		for disk[head_index] != EMPTY_BLOCK {
			head_index += 1
		}
		for disk[tail_index] == EMPTY_BLOCK {
			tail_index -= 1
		}
		if head_index >= tail_index {
			break defrag_loop
		}
		temp := disk[head_index]
		disk[head_index] = disk[tail_index]
		disk[tail_index] = temp
	}

	checksum := u64(0)

	for i: u64 = 0; disk[i] != EMPTY_BLOCK; i += 1 {
		checksum += u64(disk[i]) * i
	}

	fmt.println("Day 09.1: ", checksum)
}

block_type_toggle :: #force_inline proc(block_type: ^Block_Type) {
	switch block_type^ {
	case .File: block_type^ = .Free_Space
	case .Free_Space: block_type^ = .File
	}
}
