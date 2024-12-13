#+private file
package aoc24

import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strings"

Vec2 :: [2]i32

Grid :: struct {
	width:     u8,
	height:    u8,
	grid_size: u32,
	grid:      []u8,
}

Region :: struct {
	plant_type: u8,
	plots:      [dynamic]Plot,
}

Plot :: struct {
	plant_type: u8,
	fences:     Fence_Location_Set,
}

Fence_Location :: enum (u8) {
	Top,
	Right,
	Bottom,
	Left,
}

Fence_Location_Set :: bit_set[Fence_Location]

@(private)
day_12_1 :: proc() {
	grid: Grid
	defer grid_destroy(&grid)
	{
		data, data_ok := os.read_entire_file("inputs/day_12.txt")
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
				grid.grid[grid_index] = u8(char)
			}
		}
	}

	directions := [4]Vec2{{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
	direction_fence_map := map[Vec2]Fence_Location {
		directions[0] = .Top,
		directions[1] = .Right,
		directions[2] = .Bottom,
		directions[3] = .Left,
	}

	visited_set := make([]bool, grid.grid_size)
	defer delete(visited_set)

	seed_queue: queue.Queue(Vec2)
	queue.init(&seed_queue)
	defer queue.destroy(&seed_queue)

	regions: [dynamic]Region
	defer {
		for region in regions do delete(region.plots)
		delete(regions)
	}

	queue.push_back(&seed_queue, Vec2{0, 0})
	for queue.len(seed_queue) > 0 {
		free_all(context.temp_allocator)

		seed_pos := queue.pop_back(&seed_queue)
		seed_index := grid_coord_to_index(grid, seed_pos)
		seed_plant_type := grid.grid[seed_index]

		region: Region
		region.plant_type = seed_plant_type
		region.plots = make([dynamic]Plot)
		append(&regions, region)

		flood_queue: queue.Queue(Vec2)
		queue.init(&flood_queue, queue.DEFAULT_CAPACITY, context.temp_allocator)
		queue.push_back(&flood_queue, seed_pos)
		for queue.len(flood_queue) > 0 {
			plot_pos := queue.pop_front(&flood_queue)
			plot_index := grid_coord_to_index(grid, plot_pos)
			visited_set[plot_index] = true

			plot: Plot

			for dir_vector in directions {
				neighbour_pos := plot_pos + dir_vector
				fence_side := direction_fence_map[dir_vector]

				if !grid_is_coord_in_bounds(grid, neighbour_pos) {
					plot.fences |= {fence_side}
					continue
				}
			}

			append(&region.plots, plot)
		}
	}

	fmt.println(regions)
}

grid_init :: proc(grid: ^Grid, width, height: u32) {
	grid.width = u8(width)
	grid.height = u8(height)
	grid.grid_size = width * height
	grid.grid = make([]u8, grid.grid_size)
}

grid_destroy :: proc(grid: ^Grid) {
	delete(grid.grid)
}

grid_coord_to_index :: #force_inline proc(grid: Grid, coord: Vec2) -> u32 {
	return u32(coord.y) * u32(grid.width) + u32(coord.x)
}

grid_index_to_coord :: #force_inline proc(grid: Grid, index: u32) -> Vec2 {
	x := index % u32(grid.width)
	y := index / u32(grid.width)
	return Vec2{i32(x), i32(y)}
}

grid_is_coord_in_bounds :: #force_inline proc(grid: Grid, coord: Vec2) -> bool {
	return coord.x >= 0 && u8(coord.x) < grid.width && coord.y >= 0 && u8(coord.y) < grid.height
}