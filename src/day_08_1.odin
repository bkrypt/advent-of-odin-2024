#+private file
package aoc24

import "core:fmt"
import "core:os"
import "core:strings"

Vec2 :: [2]i8

Grid :: struct {
	width:       i8,
	height:      i8,
	cells_total: u32,
	cells:       []u8,
}

Antenna :: struct {
	frequency: u8,
	position:  Vec2,
}

@(private)
day_08_1 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_08.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	lines := strings.split_lines(string(data))
	defer delete(lines)
	assert(len(lines) > 0)

	grid_width := i8(len(lines[0]))
	grid_height := i8(len(lines) - 1)

	grid: Grid
	grid_init(&grid, grid_width, grid_height)
	defer grid_destroy(&grid)

	antenna_groups := make(map[u8][dynamic]Antenna)
	defer {
		for _, group in antenna_groups do delete(group)
		delete(antenna_groups)
	}

	position_set := make(map[Vec2]bool)
	defer delete(position_set)

	for row, y in lines {
		for cell, x in row {
			cell_index := grid_coord_to_index(grid, {i8(x), i8(y)})
			grid.cells[cell_index] = u8(cell)

			if (cell != '.') {
				frequency := u8(cell)
				if frequency not_in antenna_groups {
					antenna_groups[frequency] = {}
				}
				group := &antenna_groups[frequency]
				append(group, Antenna{frequency, {i8(x), i8(y)}})
			}
		}
	}

	antinode_sum := u32(0)

	for _, group in antenna_groups {
                if len(group) == 1 {
                        continue
                }
		for antenna, index in group {
			for other_antenna in group[index + 1:] {
				position_delta := other_antenna.position - antenna.position

				antinode_a_pos := antenna.position - position_delta
				if antinode_a_pos.x >= 0 &&
				   antinode_a_pos.x < grid.width &&
				   antinode_a_pos.y >= 0 &&
				   antinode_a_pos.y < grid.height {
					grid.cells[grid_coord_to_index(grid, antinode_a_pos)] = '#'
					if antinode_a_pos not_in position_set {
						position_set[antinode_a_pos] = true
						antinode_sum += 1
					}
				}

				antinode_b_pos := other_antenna.position + position_delta
				if antinode_b_pos.x >= 0 &&
				   antinode_b_pos.x < grid.width &&
				   antinode_b_pos.y >= 0 &&
				   antinode_b_pos.y < grid.height {
					grid.cells[grid_coord_to_index(grid, antinode_b_pos)] = '#'
					if antinode_b_pos not_in position_set {
						position_set[antinode_b_pos] = true
						antinode_sum += 1
					}
				}
			}
		}
	}

	fmt.println("Day 08.1: ", antinode_sum)
}

grid_init :: proc(grid: ^Grid, width: i8, height: i8) {
	grid.width = width
	grid.height = height
	grid.cells_total = u32(width) * u32(height)
	grid.cells = make([]u8, grid.cells_total)
}

grid_destroy :: proc(grid: ^Grid) {
	delete(grid.cells)
}

grid_coord_to_index :: proc(grid: Grid, coord: Vec2) -> u32 {
	// fmt.println(coord, "index", u32(coord.y) * u32(grid.width) + u32(coord.x))
	return u32(coord.y) * u32(grid.width) + u32(coord.x)
}

grid_draw :: proc(grid: Grid) {
	for y in 0 ..< grid.height {
		for x in 0 ..< grid.width {
			index := grid_coord_to_index(grid, {x, y})
			fmt.print(rune(grid.cells[index]))
		}
		fmt.println()
	}
}
