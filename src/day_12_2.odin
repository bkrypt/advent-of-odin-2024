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
	outer_fences:  Fence_Set,
	inner_fences:  Fence_Set,
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

fence_direction_map := [Fence]Direction {
	.Top    = Direction.Up,
	.Right  = Direction.Right,
	.Bottom = Direction.Down,
	.Left   = Direction.Left,
}

Edge_Walker :: struct {
	mode:          Walker_Mode,
	side:          Fence,
	direction:     Direction,
	index:         u32,
	loop_complete: bool,
}

Walker_Mode :: enum (u8) {
	Outside,
	Inside,
}

@(private)
day_12_2 :: proc() {
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
			region_count_edges(&region, grid)
			append(&regions, region)

			free_all(context.temp_allocator)
		}
	}

	cost := u32(0)

	for region in regions {
		cost += region.sides * region.area
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

region_count_edges :: proc(region: ^Region, grid: Grid) {
	visited_set: map[u32]bool
	defer delete(visited_set)

	walker: Edge_Walker
	edge_walker_reset(&walker)
	walker.mode = .Outside

	walker.index = region.plot_ids[0]
	walker.direction = Direction.Right

	start_plot_index := walker.index
	start_direction := walker.direction

	perimeter_loop: for !walker.loop_complete {
		plot := &grid.grid[walker.index]
		visited_set[plot.grid_index] = true

		turned_this_loop := false
		if walker.side not_in plot.fences {
			region.sides += 1
			edge_walker_turn_to_side(&walker)
			turned_this_loop = true
		} else if plot.neighbour_ids[walker.direction] == ~u32(0) {
			region.sides += 1
			plot.outer_fences |= {walker.side}
			edge_walker_turn_right(&walker)
			turned_this_loop = true
		}

		if turned_this_loop && walker.direction == start_direction && walker.index == start_plot_index {
			walker.loop_complete = true
		} else if plot.neighbour_ids[walker.direction] != ~u32(0) {
			if walker.side in plot.fences {
				plot.outer_fences |= {walker.side}
			}
			walker.index = plot.neighbour_ids[walker.direction]
		}
	}

	hole_loop: for plot_index in region.plot_ids {
		plot := grid.grid[plot_index]
		if card(plot.fences) > 0 && plot.outer_fences != plot.fences && plot.inner_fences == {} {
			edge_walker_reset(&walker)
			walker.mode = .Inside
			walker.index = plot_index
			walker.side = fence_set_first_set_fence(plot.fences - plot.outer_fences)
			switch walker.side {
			case .Top: walker.direction = .Left
			case .Right: walker.direction = .Up
			case .Bottom: walker.direction = .Right
			case .Left: walker.direction = .Down
			}
			start_plot_index = walker.index
			start_direction = walker.direction

			for !walker.loop_complete {
				plot := &grid.grid[walker.index]
				plot.inner_fences |= {walker.side}

				visited_set[plot.grid_index] = true

				turned_this_loop := false
				if walker.side not_in plot.fences {
					region.sides += 1
					edge_walker_turn_to_side(&walker)
					plot.inner_fences |= {walker.side}
					turned_this_loop = true
				} else if plot.neighbour_ids[walker.direction] == ~u32(0) {
					region.sides += 1
					if plot.neighbour_ids[fence_direction_map[walker.side]] == ~u32(0) {
						edge_walker_turn_left(&walker)
					} else {
						edge_walker_turn_right(&walker)
					}
					plot.inner_fences |= {walker.side}
					turned_this_loop = true
				}

				if turned_this_loop &&
				   walker.direction == start_direction &&
				   walker.index == start_plot_index {
					walker.loop_complete = true
				} else if plot.neighbour_ids[walker.direction] != ~u32(0) {
					walker.index = plot.neighbour_ids[walker.direction]

					if walker.direction == start_direction && walker.index == start_plot_index {
						walker.loop_complete = true
					}
				}
			}
		}
	}
}

edge_walker_reset :: proc(walker: ^Edge_Walker) {
	walker.mode = .Outside
	walker.direction = .Right
	walker.side = .Top
	walker.index = ~u32(0)
	walker.loop_complete = false
}

edge_walker_turn_to_side :: proc(walker: ^Edge_Walker) {
	walker.direction = fence_direction_map[walker.side]
	switch walker.mode {
	case .Outside:
		switch walker.direction {
		case .Up: walker.side = .Left
		case .Right: walker.side = .Top
		case .Down: walker.side = .Right
		case .Left: walker.side = .Bottom
		}
	case .Inside:
		switch walker.direction {
		case .Up: walker.side = .Right
		case .Right: walker.side = .Bottom
		case .Down: walker.side = .Left
		case .Left: walker.side = .Top
		}
	}
}

edge_walker_turn_right :: proc(walker: ^Edge_Walker) {
	switch walker.mode {
	case .Outside:
		switch walker.direction {
		case .Up:
			walker.direction = .Right
			walker.side = .Top
		case .Right:
			walker.direction = .Down
			walker.side = .Right
		case .Down:
			walker.direction = .Left
			walker.side = .Bottom
		case .Left:
			walker.direction = .Up
			walker.side = .Left
		}
	case .Inside:
		switch walker.direction {
		case .Up:
			walker.direction = .Right
			walker.side = .Bottom
		case .Right:
			walker.direction = .Down
			walker.side = .Left
		case .Down:
			walker.direction = .Left
			walker.side = .Top
		case .Left:
			walker.direction = .Up
			walker.side = .Right
		}
	}
}

edge_walker_turn_left :: proc(walker: ^Edge_Walker) {
	if walker.mode == .Outside {
		panic("walker should never turn left in Outside mode")
	}
	switch walker.direction {
	case .Up:
		walker.direction = .Left
		walker.side = .Top
	case .Right:
		walker.direction = .Up
		walker.side = .Right
	case .Down:
		walker.direction = .Right
		walker.side = .Bottom
	case .Left:
		walker.direction = .Down
		walker.side = .Left
	}
}

fence_set_first_set_fence :: proc(fences: Fence_Set) -> (fence: Fence) {
	if Fence.Top in fences {
		fence = .Top
	} else if Fence.Right in fences {
		fence = .Right
	} else if Fence.Bottom in fences {
		fence = .Bottom
	} else if Fence.Left in fences {
		fence = .Left
	}
	return
}
