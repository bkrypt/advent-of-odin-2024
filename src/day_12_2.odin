#+private file
package aoc24

import "core:container/queue"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"

Vec2 :: [2]i32

Grid :: struct {
	width:     u8,
	height:    u8,
	grid_size: u32,
	grid:      []Plot,
}

Region :: struct {
	plant_type: u8,
	plot_ids:   [dynamic]u32,
	area:       u32,
	perimeter:  u32,
	sides:      u32,
}

Plot :: struct {
	plant_type:    u8,
	fences:        Fence_Set,
	grid_index:    u32,
	grid_position: Vec2,
	neighbour_ids: [Direction]u32,
}

Direction :: enum (u8) {
	Up,
	Right,
	Down,
	Left,
}

direction_vector_map := [Direction]Vec2 {
	.Up    = {0, -1},
	.Right = {1, 0},
	.Down  = {0, 1},
	.Left  = {-1, 0},
}

Fence :: enum (u8) {
	Top,
	Right,
	Bottom,
	Left,
}

Fence_Set :: bit_set[Fence]

direction_fence_map := [Direction]Fence {
	.Up    = Fence.Top,
	.Right = Fence.Right,
	.Down  = Fence.Bottom,
	.Left  = Fence.Left,
}

Perimeter_Tracker :: struct {
	position:  Vec2,
	direction: Direction,
}

Walker :: struct {
	direction:        Direction,
	start_plot_index: u32,
	current_fences:   Fence_Set,
}

@(private)
day_12_2 :: proc() {
        grid: Grid
	defer grid_destroy(&grid)
	{
		data, data_ok := os.read_entire_file("inputs/day_12_test.txt")
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
				grid_position := Vec2{i32(x), i32(y)}
				grid_index := grid_coord_to_index(grid, grid_position)

				plot: Plot
				plot.plant_type = u8(char)
				plot.grid_index = grid_index
				plot.grid_position = grid_position
				slice.fill(slice.enumerated_array(&plot.neighbour_ids), ~u32(0))
				for direction in Direction {
					neighbour_position := grid_position + direction_vector_map[direction]
					if !grid_is_coord_in_bounds(grid, neighbour_position) {
						plot.fences |= {direction_fence_map[direction]}
					} else if lines[neighbour_position.y][neighbour_position.x] != plot.plant_type {
						plot.fences |= {direction_fence_map[direction]}
					} else {
						plot.neighbour_ids[direction] = grid_coord_to_index(
							grid,
							neighbour_position,
						)
					}
				}

				grid.grid[grid_index] = plot
			}
		}
	}

	regions: [dynamic]Region
	defer {
		for region in regions do delete(region.plot_ids)
		delete(regions)
	}
	{
		plot_visited_set: map[u32]bool
		defer delete(plot_visited_set)

		for plot_index in 0 ..< grid.grid_size {
			if plot_visited_set[plot_index] {
				continue
			}

			flood_queue: queue.Queue(u32)
			queue.init(&flood_queue, queue.DEFAULT_CAPACITY, context.temp_allocator)
			queue.push_back(&flood_queue, plot_index)
			plot_visited_set[plot_index] = true

			region: Region
			region.plant_type = grid.grid[plot_index].plant_type
			for queue.len(flood_queue) > 0 {
				index := queue.pop_front(&flood_queue)
				append(&region.plot_ids, index)
				plot := grid.grid[index]
				for direction in Direction {
					neighbour_index := plot.neighbour_ids[direction]
					if neighbour_index != ~u32(0) && !plot_visited_set[neighbour_index] {
						queue.push_back(&flood_queue, neighbour_index)
						plot_visited_set[neighbour_index] = true
					}
				}
			}
			region_compute_spatial_measurements(&region, grid)
                        region_compute_total_sides(&region, grid)
			append(&regions, region)

			free_all(context.temp_allocator)
		}
	}

	cost := u32(0)
	for region in regions {
		fmt.println(rune(region.plant_type), region.sides)
	}

	fmt.println("Day 12.2: ", cost)
}

grid_init :: proc(grid: ^Grid, width, height: u32) {
	grid.width = u8(width)
	grid.height = u8(height)
	grid.grid_size = width * height
	grid.grid = make([]Plot, grid.grid_size)
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

region_compute_spatial_measurements :: proc(region: ^Region, grid: Grid) {
	region.area = u32(len(region.plot_ids))
	for plot_index in region.plot_ids {
		region.perimeter += u32(card(grid.grid[plot_index].fences))
	}
}

region_compute_total_sides :: proc(region: ^Region, grid: Grid) {
        walker: Walker
	walker.direction = .Right
	walker.start_plot_index = region.plot_ids[0]

        visited_set: map[u32]bool
        defer delete(visited_set)

        visit_queue: queue.Queue(u32)
        queue.init(&visit_queue)
        defer queue.destroy(&visit_queue)

        queue.push_back(&visit_queue, walker.start_plot_index)
	contour_loop: for queue.len(visit_queue) > 0 {
                current_plot_index := queue.pop_back(&visit_queue)
                plot := grid.grid[current_plot_index]
                visited_set[plot.grid_index] = true

                if card(plot.fences) == 0 {
                        direction_turn_left(&walker.direction)
                        neighbour_plot := grid.grid[plot.neighbour_ids[walker.direction]]
                        queue.push_back(&visit_queue, neighbour_plot.grid_index)
                        continue
                }

                fence_diff := plot.fences - walker.current_fences
                walker.current_fences = plot.fences
                region.sides += u32(card(fence_diff))

                start_dir := walker.direction
                for plot.neighbour_ids[walker.direction] == ~u32(0) || visited_set[plot.neighbour_ids[walker.direction]] {
                        direction_turn_right(&walker.direction)
                        if walker.direction == start_dir {
                                break contour_loop
                        }
                }

                queue.push_back(&visit_queue, plot.neighbour_ids[walker.direction])
	}
}

direction_turn_left :: proc(direction: ^Direction) {
        switch direction^ {
        case .Up: direction^ = .Left
        case .Left: direction^ = .Down
        case .Down: direction^ = .Right
        case .Right: direction^ = .Up
        }
}

direction_turn_right :: proc(direction: ^Direction) {
        switch direction^ {
        case .Up: direction^ = .Right
        case .Right: direction^ = .Down
        case .Down: direction^ = .Left
        case .Left: direction^ = .Up
        }
}
