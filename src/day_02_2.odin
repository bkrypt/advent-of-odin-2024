#+private file
package aoc24

import "core:container/small_array"
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
day_02_2 :: proc() {
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
		if report_is_safe(report.levels[:]) {
			num_safe_reports += 1
		} else {
			levels_less_one: small_array.Small_Array(32, i32)
			assert(len(report.levels) < 32)
			for drop_index := 0; drop_index < len(report.levels); drop_index += 1 {
				small_array.clear(&levels_less_one)
				for level, level_index in report.levels {
					if level_index != drop_index {
						small_array.append(&levels_less_one, level)
					}
				}

				if report_is_safe(small_array.slice(&levels_less_one)) {
					num_safe_reports += 1
					break
				}
			}
		}
	}

	fmt.println("Day 02.2: ", num_safe_reports)
}

report_is_safe :: proc(levels: []i32) -> (is_valid := true) {
	trend := Trend.None
	for i := 1; is_valid && i < len(levels); i += 1 {
		delta := levels[i] - levels[i - 1]
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
	return
}
