#+private file
package aoc24

import "core:fmt"
import "core:os"
import "core:strings"

@(private)
day_04_2 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_04.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	xmas_board_str := string(data)
	xmas_board := strings.split_lines(xmas_board_str)
	defer delete(xmas_board)

	xmas_count := 0

	for line, y in xmas_board {
		for char, x in line {
			if char == 'A' {
				if x > 0 && x < len(line) - 1 && y > 0 && y < len(xmas_board) - 1 {
					ld := xmas_board[y + 1][x - 1]
					lu := xmas_board[y - 1][x - 1]
					ru := xmas_board[y - 1][x + 1]
					rd := xmas_board[y + 1][x + 1]

					if ((lu == 'M' && rd == 'S') || (lu == 'S' && rd == 'M')) &&
					   ((ld == 'M' && ru == 'S') || (ld == 'S' && ru == 'M')) {
						xmas_count += 1
					}
				}
			}
		}
	}

        fmt.println("Day 04.2: ", xmas_count)
}
