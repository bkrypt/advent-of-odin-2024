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
day_08_2 :: proc() {
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

	unique_position_count := u32(0)
	position_set := make(map[Vec2]bool)
	defer delete(position_set)

	for _, group in antenna_groups {
		if len(group) == 1 {
			continue
		}
                if group[0].position not_in position_set {
                        position_set[group[0].position] = true
                        unique_position_count += 1
                }
		for antenna, index in group {
			for other_antenna in group[index + 1:] {
				position_delta := other_antenna.position - antenna.position

				pos_path_position := antenna.position + position_delta
				for grid_is_position_in_bounds(grid, pos_path_position) {
					if pos_path_position not_in position_set {
						if grid.cells[grid_coord_to_index(grid, pos_path_position)] == '.' {
							grid.cells[grid_coord_to_index(grid, pos_path_position)] = '#'
						}
						position_set[pos_path_position] = true
						unique_position_count += 1
					}
					pos_path_position += position_delta
				}

				neg_path_position := antenna.position - position_delta
				for grid_is_position_in_bounds(grid, neg_path_position) {
					if neg_path_position not_in position_set {
						if grid.cells[grid_coord_to_index(grid, neg_path_position)] == '.' {
							grid.cells[grid_coord_to_index(grid, neg_path_position)] = '#'
						}
						position_set[neg_path_position] = true
						unique_position_count += 1
					}
					neg_path_position -= position_delta
				}
			}
		}
	}

	fmt.println("Day 08.2: ", unique_position_count)
}

grid_init :: proc(grid: ^Grid, width: i8, height: i8) {
	grid.width = width
	grid.height = height
	grid.cells_total = u32(width) * u32(height)
	grid.cells = make([]u8, grid.cells_total)
}

grid_is_position_in_bounds :: proc(grid: Grid, position: Vec2) -> bool {
	return position.x >= 0 && position.x < grid.width && position.y >= 0 && position.y < grid.height
}

grid_destroy :: proc(grid: ^Grid) {
	delete(grid.cells)
}

grid_coord_to_index :: proc(grid: Grid, coord: Vec2) -> u32 {
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
