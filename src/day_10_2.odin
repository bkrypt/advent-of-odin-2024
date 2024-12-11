#+private file
package aoc24

import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Vec2 :: [2]i32

Grid :: struct {
	width:     u32,
	height:    u32,
	grid_size: u32,
	grid:      []u8,
}

@(private)
day_10_2 :: proc() {
	grid: Grid
	defer grid_destroy(&grid)
	{
		data, data_ok := os.read_entire_file("inputs/day_10.txt")
		if !data_ok do panic("failed to load input")
		defer delete(data)
		if data[len(data) - 1] == '\n' {
			data = data[:len(data) - 1]
		}

		lines := strings.split_lines(string(data))
		defer delete(lines)

		grid_width := u32(len(lines[0]))
		grid_height := u32(len(lines))
		grid_init(&grid, grid_width, grid_height)

		for line, y in lines {
			for char, x in line {
				grid_index := grid_coord_to_index(grid, {i32(x), i32(y)})
				grid.grid[grid_index] = u8(char) - '0'
			}
		}
	}

	trailheads: [dynamic]u32
	defer delete(trailheads)
	for height, index in grid.grid {
		if height == 9 {
			append(&trailheads, u32(index))
		}
	}

	traversal_queue: queue.Queue(u32)
	queue.init(&traversal_queue)
	defer queue.destroy(&traversal_queue)

	visited_set := make(map[Vec2]bool)
	defer delete(visited_set)

	travel_vectors := [4]Vec2{{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
	score := u32(0)

	for trailhead in trailheads {
		queue.push_back(&traversal_queue, trailhead)
		for queue.len(traversal_queue) > 0 {
			index := queue.pop_front(&traversal_queue)
			coord := grid_index_to_coord(grid, index)
			visited_set[coord] = true
			height := grid.grid[index]
			if height == 0 {
				score += 1
				continue
			}
			for travel_vector in travel_vectors {
				new_coord := coord + travel_vector
				if new_coord not_in visited_set && grid_coord_in_bounds(grid, new_coord) {
					new_coord_index := grid_coord_to_index(grid, new_coord)
					adjacent_height := grid.grid[new_coord_index]
					if adjacent_height == height - 1 {
						queue.push_back(&traversal_queue, new_coord_index)
					}
				}
			}
		}
		queue.clear(&traversal_queue)
		clear(&visited_set)
	}

	fmt.println("Day 10.1: ", score)
}

grid_init :: proc(grid: ^Grid, width, height: u32) {
	grid.width = width
	grid.height = height
	grid.grid_size = width * height
	grid.grid = make([]u8, grid.grid_size)
}

grid_destroy :: proc(grid: ^Grid) {
	delete(grid.grid)
}

grid_coord_to_index :: #force_inline proc(grid: Grid, coord: Vec2) -> u32 {
	return u32(coord.y) * grid.width + u32(coord.x)
}

grid_index_to_coord :: #force_inline proc(grid: Grid, index: u32) -> Vec2 {
	x := index % grid.width
	y := index / grid.width
	return Vec2{i32(x), i32(y)}
}

grid_coord_in_bounds :: #force_inline proc(grid: Grid, coord: Vec2) -> bool {
	return coord.x >= 0 && coord.x < i32(grid.width) && coord.y >= 0 && coord.y < i32(grid.height)
}

grid_draw :: proc(grid: Grid) {
	for y in 0 ..< grid.height {
		for x in 0 ..< grid.width {
			index := grid_coord_to_index(grid, {i32(x), i32(y)})
			fmt.print(grid.grid[index])
		}
		fmt.println()
	}
}
