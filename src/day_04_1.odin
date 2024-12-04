#+private file
package aoc24

import "core:fmt"
import "core:os"
import "core:strings"

Direction :: enum (u8) {
	Left,
	Up,
	Right,
	Down,
}

Direction_Set :: bit_set[Direction]

@(private)
day_04_1 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_04.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	word_search := string(data)
	word_search_board := strings.split_lines(word_search)
	defer delete(word_search_board)

	xmas_count := 0

	for line, y in word_search_board {
		for char, x in line {
			if char == 'X' {
				if look_for_xmas(char, x, y, {.Left}, word_search_board) {
					xmas_count += 1
				}
				if look_for_xmas(char, x, y, {.Left, .Up}, word_search_board) {
					xmas_count += 1
				}
				if look_for_xmas(char, x, y, {.Up}, word_search_board) {
					xmas_count += 1
				}
				if look_for_xmas(char, x, y, {.Right, .Up}, word_search_board) {
					xmas_count += 1
				}
				if look_for_xmas(char, x, y, {.Right}, word_search_board) {
					xmas_count += 1
				}
				if look_for_xmas(char, x, y, {.Right, .Down}, word_search_board) {
					xmas_count += 1
				}
				if look_for_xmas(char, x, y, {.Down}, word_search_board) {
					xmas_count += 1
				}
				if look_for_xmas(char, x, y, {.Left, .Down}, word_search_board) {
					xmas_count += 1
				}
			}
		}
	}

	fmt.println("Day 04.1: ", xmas_count)
}

look_for_xmas :: proc(current_letter: rune, x, y: int, direction: Direction_Set, word_search_board: []string) -> bool {
	if current_letter == 'S' {
		return true
	}

	x_new := x
	y_new := y

	if Direction.Left in direction {
		x_new -= 1
	} else if Direction.Right in direction {
		x_new += 1
	}

	if Direction.Up in direction {
		y_new -= 1
	} else if Direction.Down in direction {
		y_new += 1
	}

	if x_new >= 0 && x_new < len(word_search_board[0]) && y_new >= 0 && y_new < len(word_search_board) {
		next_letter: rune
		switch current_letter {
		case 'X': next_letter = 'M'
		case 'M': next_letter = 'A'
		case 'A': next_letter = 'S'
		}

		if rune(word_search_board[y_new][x_new]) == next_letter {
			return look_for_xmas(next_letter, x_new, y_new, direction, word_search_board)
		}
	}

	return false
}
