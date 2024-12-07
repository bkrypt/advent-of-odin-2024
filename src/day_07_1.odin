#+private file
package aoc24

import "core:fmt"
import "core:os"
import "core:strings"

@(private)
day_07_1 :: proc() {
        data, data_ok := os.read_entire_file("inputs/day_07.txt")
        if !data_ok do panic("failed to load input")
        defer delete(data)

        it := string(data)
        for line in strings.split_lines_iterator(&it) {
                fields := strings.fields(line)
                defer delete(fields)
        }
}
