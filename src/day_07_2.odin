#+private file
package aoc24

import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:testing"

Equation :: struct {
	test_value: u64,
	numbers:    []u32,
}

Equation_State :: struct {
	current_result: u64,
	index:          u8,
}

@(private)
day_07_2 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_07.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	equations: [dynamic]Equation
	defer {
		for e in equations do delete(e.numbers)
		delete(equations)
	}

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		fields := strings.fields(line)
		defer delete(fields)

		equation: Equation
		equation.test_value = u64(strconv.atoi(fields[0][:len(fields[0]) - 1]))
		equation.numbers = make([]u32, len(fields) - 1)
		for num_str, index in fields[1:] {
			equation.numbers[index] = u32(strconv.atoi(num_str))
		}
		append(&equations, equation)
	}

	sum := u64(0)

	op_queue: queue.Queue(Equation_State)
	queue.init(&op_queue)
	defer queue.destroy(&op_queue)

	equation_loop: for equation in equations {
		assert(len(equation.numbers) > 1)
		queue.push_back(&op_queue, Equation_State{u64(equation.numbers[0]), 1})
		number_loop: for queue.len(op_queue) > 0 {
			state := queue.pop_front(&op_queue)
			if state.index < u8(len(equation.numbers)) {
				add_result := state.current_result + u64(equation.numbers[state.index])
				if add_result <= equation.test_value {
					queue.push_back(&op_queue, Equation_State{add_result, state.index + 1})
				}
				mul_result := state.current_result * u64(equation.numbers[state.index])
				if mul_result <= equation.test_value {
					queue.push_back(&op_queue, Equation_State{mul_result, state.index + 1})
				}
				concat_result := int_concat(state.current_result, u64(equation.numbers[state.index]))
				if concat_result <= equation.test_value {
					queue.push_back(&op_queue, Equation_State{concat_result, state.index + 1})
				}
			} else if state.current_result == equation.test_value {
				sum += equation.test_value
				break number_loop
			}
		}
		queue.clear(&op_queue)
	}

	fmt.println("Day 07.2: ", sum)
}

int_concat :: proc(x: u64, y: u64) -> u64 {
	d := u64(10)
	temp_y := y
	for temp_y > 9 {
		temp_y /= 10
		d *= 10
	}
	return x * d + y
}

@(test)
int_concat_test :: proc(t: ^testing.T) {
	testing.expect_value(t, int_concat(20, 1), 201)
	testing.expect_value(t, int_concat(1, 1), 11)
	testing.expect_value(t, int_concat(3, 0), 30)
	testing.expect_value(t, int_concat(12345, 6789), 123456789)
}