package aoc24

import "core:fmt"
import "core:mem"

AOC :: #config(AOC, "ALL")

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	when AOC == "ALL" || AOC == "DAY01_1" do day_01_1()
	when AOC == "ALL" || AOC == "DAY01_2" do day_01_2()
	when AOC == "ALL" || AOC == "DAY02_1" do day_02_1()
	when AOC == "ALL" || AOC == "DAY02_2" do day_02_2()
	when AOC == "ALL" || AOC == "DAY03_1" do day_03_1()
	when AOC == "ALL" || AOC == "DAY03_2" do day_03_2()
	when AOC == "ALL" || AOC == "DAY04_1" do day_04_1()
	when AOC == "ALL" || AOC == "DAY04_2" do day_04_2()
	when AOC == "ALL" || AOC == "DAY05_1" do day_05_1()
	when AOC == "ALL" || AOC == "DAY05_2" do day_05_2()
	when AOC == "ALL" || AOC == "DAY06_1" do day_06_1()
	when AOC == "ALL" || AOC == "DAY06_2" do day_06_2()
}
