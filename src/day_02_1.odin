#+private file
package aoc24

import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

Report :: struct {
	levels: [dynamic]i32,
}

Trend :: enum (u8) {
	None,
	Ascending,
	Descending,
}

LEVEL_DELTA_THRESHOLD :: 3

@(private)
day_02_1 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_02.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	reports: [dynamic]Report
	defer {
		for report in reports do delete(report.levels)
		delete(reports)
	}

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		fields := strings.fields(line)
		defer delete(fields)

		report: Report
		for level in fields {
			append(&report.levels, i32(strconv.atoi(level)))
		}
		append(&reports, report)
	}

	num_safe_reports := u32(0)

	for report in reports {
		trend := Trend.None
		is_valid := true

		for i := 1; is_valid && i < len(report.levels); i += 1 {
			delta := report.levels[i] - report.levels[i - 1]
			if delta > 0 {
				#partial switch trend {
				case .Descending: is_valid = false
				case .None: trend = .Ascending
				}
			} else if delta < 0 {
				#partial switch trend {
				case .Ascending: is_valid = false
				case .None: trend = .Descending
				}
			}

			if delta == 0 || math.abs(delta) > LEVEL_DELTA_THRESHOLD {
				is_valid = false
			}
		}

		if is_valid {
			num_safe_reports += 1
		}
	}

	fmt.println("Day 02.1: ", num_safe_reports)
}
