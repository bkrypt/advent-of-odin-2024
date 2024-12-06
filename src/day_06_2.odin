#+private file
package aoc24

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

Vec2 :: [2]i32

Grid :: struct {
	width:        u8,
	height:       u8,
	cells:        []u8,
	cells_length: u32,
}

Direction :: enum (u8) {
	North,
	East,
	South,
	West,
}

Guard :: struct {
	position:  Vec2,
	direction: Direction,
	sprite:    u8,
}

Visit_State :: struct {
	cell_index: u32,
	direction:  Direction,
}

Context :: struct {
	grid:               Grid,
	guard:              Guard,
	distinct_pos_count: u32,
	distinct_obs_count: u32,
	visited_states:     map[Visit_State]bool,
	initial_grid_cells: []u8,
	initial_guard:      Guard,
}

@(private)
day_06_2 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_06.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	lines := strings.split_lines(string(data))
	defer delete(lines)

	ctx: Context
	context_init(&ctx, len(lines[0]), len(lines) - 1)
	defer context_destroy(&ctx)

	for line, y in lines {
		if len(line) == 0 do continue
		for x in 0 ..< len(line) {
			cell_index := grid_coords_to_index(ctx.grid, {i32(x), i32(y)})
			assert(cell_index < ctx.grid.cells_length)
			ctx.grid.cells[cell_index] = line[x]

			if line[x] == '^' {
				ctx.guard = Guard {
					position  = {i32(x), i32(y)},
					sprite    = '^',
					direction = .North,
				}
			}
		}
	}

	ctx.initial_guard = ctx.guard
	ctx.initial_grid_cells = slice.clone(ctx.grid.cells)

	obstruction_loop: for obstruction_index in 0 ..< ctx.grid.cells_length {
		if ctx.grid.cells[obstruction_index] == '^' || ctx.grid.cells[obstruction_index] == '#' {
			continue
		}

		ctx.grid.cells[obstruction_index] = '#'

		move_loop: for {
			next_step := guard_next_step_vector(ctx.guard)
			step_position := ctx.guard.position + next_step

			if step_position.x < 0 ||
			   step_position.y < 0 ||
			   step_position.x >= i32(ctx.grid.width) ||
			   step_position.y >= i32(ctx.grid.height) {
				break move_loop
			}

			step_cell_index := grid_coords_to_index(ctx.grid, step_position)

			if ctx.grid.cells[step_cell_index] == '#' {
				guard_rotate(&ctx.guard)
			} else if ctx.visited_states[{step_cell_index, ctx.guard.direction}] {
				ctx.distinct_obs_count += 1
				break move_loop
			} else {
				previous_cell_index := grid_coords_to_index(ctx.grid, ctx.guard.position)
				ctx.grid.cells[previous_cell_index] = 'X'
				ctx.grid.cells[step_cell_index] = ctx.guard.sprite
				ctx.guard.position = step_position
				ctx.visited_states[{step_cell_index, ctx.guard.direction}] = true
			}
		}

		context_reset(&ctx)
	}

	fmt.println("Day 06.2: ", ctx.distinct_obs_count)
}

context_init :: proc(ctx: ^Context, grid_width: int, grid_height: int) {
	ctx.distinct_pos_count = 1
	ctx.visited_states = make(map[Visit_State]bool)
	grid_init(&ctx.grid, i32(grid_width), i32(grid_height))
}

context_reset :: proc(ctx: ^Context) {
	ctx.guard = ctx.initial_guard
	ctx.distinct_pos_count = 0
	copy(ctx.grid.cells, ctx.initial_grid_cells)
	clear(&ctx.visited_states)
}

context_destroy :: proc(ctx: ^Context) {
	delete(ctx.visited_states)
	delete(ctx.initial_grid_cells)
	grid_destroy(&ctx.grid)
}

grid_init :: proc(grid: ^Grid, width: i32, height: i32) {
	grid.width = u8(width)
	grid.height = u8(height)
	grid.cells_length = u32(width) * u32(height)
	grid.cells = make([]u8, grid.cells_length)
}

grid_destroy :: proc(grid: ^Grid) {
	delete(grid.cells)
}

grid_coords_to_index :: proc(grid: Grid, coords: Vec2) -> u32 {
	return u32(grid.width) * u32(coords.y) + u32(coords.x)
}

grid_draw :: proc(grid: Grid) {
	for y in 0 ..< grid.height {
		for x in 0 ..< grid.width {
			index := grid_coords_to_index(grid, {i32(x), i32(y)})
			fmt.print(rune(grid.cells[index]))
		}
		fmt.println()
	}
}

guard_next_step_vector :: proc(guard: Guard) -> (step: Vec2) {
	switch guard.direction {
	case .North: step = {0, -1}
	case .East: step = {1, 0}
	case .South: step = {0, 1}
	case .West: step = {-1, 0}
	}
	return
}

guard_rotate :: proc(guard: ^Guard) {
	new_direction := u8(guard.direction) + 1
	if new_direction > u8(Direction.West) {
		new_direction = 0
	}
	guard.direction = Direction(new_direction)

	switch guard.direction {
	case .North: guard.sprite = '^'
	case .East: guard.sprite = '>'
	case .South: guard.sprite = 'V'
	case .West: guard.sprite = '<'
	}
}
