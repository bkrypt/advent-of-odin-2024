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

Block :: struct {
	id:    u16,
	size:  u8,
	index: u32,
}

EMPTY_BLOCK :: ~u16(0)

@(private)
day_09_2 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_09.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	disk_files := make([dynamic]Block)
	defer delete(disk_files)
	disk_free_space := make([dynamic]Block)
	defer delete(disk_free_space)

	disk_map := string(data)
	if disk_map[len(disk_map) - 1] == '\n' {
		disk_map = disk_map[:len(disk_map) - 1]
	}

	block_type := Block_Type.File
	block_index := u32(0)
	file_id := ~u16(0)

	map_loop: for char, i in disk_map {
		block_length := u8(char) - '0'
		switch block_type {
		case .File:
			file_id += 1
			append(&disk_files, Block{file_id, block_length, block_index})
		case .Free_Space:
			append(&disk_free_space, Block{EMPTY_BLOCK, block_length, block_index})
		}
		block_type_toggle(&block_type)
		block_index += u32(block_length)
	}

	file_loop: #reverse for &file in disk_files {
		for &free_space in disk_free_space {
			if free_space.index > file.index {
				continue file_loop
			}
			if free_space.size >= file.size {
				file.index = free_space.index
				free_space.index += u32(file.size)
				free_space.size -= file.size
				continue file_loop
			}
		}
	}

	checksum := u64(0)

	for file in disk_files {
		file_start := u64(file.index)
		file_end := u64(file.index + u32(file.size))
		for i: u64 = file_start; i < file_end; i += 1 {
			checksum += u64(file.id) * i
		}
	}

	fmt.println("Day 09.2: ", checksum)
}

block_type_toggle :: #force_inline proc(block_type: ^Block_Type) {
	switch block_type^ {
	case .File: block_type^ = .Free_Space
	case .Free_Space: block_type^ = .File
	}
}
