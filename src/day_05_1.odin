#+private file
package aoc24

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

print_rules: map[u8]Print_Rule

Print_Rule :: struct {
	page:         u8,
	before_count: u8,
	after_count:  u8,
	page_order:   [dynamic]u8,
}

Manual_Update :: struct {
	pages: []u8,
}

Page_Order :: enum (u8) {
	Before,
	After,
}

@(private)
day_05_1 :: proc() {
	data, data_ok := os.read_entire_file("inputs/day_05.txt")
	if !data_ok do panic("failed to load input")
	defer delete(data)

	data_sections := strings.split(string(data), "\n\n")
	defer delete(data_sections)
	assert(len(data_sections) == 2)

	print_rules_input := data_sections[0]
	manual_updates_input := data_sections[1]

	print_rules = make(map[u8]Print_Rule)
	defer {
		for _, rule in print_rules {
			delete(rule.page_order)
		}
		delete(print_rules)
	}

	manual_updates: [dynamic]Manual_Update
	defer {
		for update in manual_updates {
			delete(update.pages)
		}
		delete(manual_updates)
	}

	for rule_pair in strings.split_lines_iterator(&print_rules_input) {
		pages := strings.split(rule_pair, "|")
		defer delete(pages)
		assert(len(pages) == 2)

		page_a := u8(strconv.atoi(pages[0]))
		page_b := u8(strconv.atoi(pages[1]))

		if page_a not_in print_rules {
			print_rules[page_a] = Print_Rule {
				page = page_a,
			}
		}

		page_a_rule := &print_rules[page_a]
		page_a_rule.after_count += 1
		append(&page_a_rule.page_order, page_b)

		if page_b not_in print_rules {
			print_rules[page_b] = Print_Rule {
				page = page_b,
			}
		}

		page_b_rule := &print_rules[page_b]
		page_b_rule.before_count += 1
		inject_at(&page_b_rule.page_order, 0, page_a)
	}

	for update_line in strings.split_lines_iterator(&manual_updates_input) {
		update_pages := strings.split(update_line, ",")
		defer delete(update_pages)

		pages := make([]u8, len(update_pages))
		append(&manual_updates, Manual_Update{pages})

		for page_str, page_index in update_pages {
			page := u8(strconv.atoi(page_str))
			assert(page in print_rules)
			pages[page_index] = page
		}
	}

	sum := u32(0)

	update_loop: for update, index in manual_updates {
		for page, page_index in update.pages {
			before_index := page_index - 1
			if (before_index >= 0) {
				before_pages := update.pages[:before_index]
				for other_page in before_pages {
					if !page_has_rule_for_other_page(page, other_page) ||
					   !page_order_satisfied(page, other_page, .Before) {
						continue update_loop
					}
				}
			}

			after_index := page_index + 1
			if (after_index < len(update.pages)) {
				after_pages := update.pages[after_index:]
				for other_page in after_pages {
					if !page_has_rule_for_other_page(page, other_page) ||
					   !page_order_satisfied(page, other_page, .After) {
						continue update_loop
					}
				}
			}
		}

		mid := update.pages[len(update.pages) / 2]
		sum += u32(mid)
	}

	fmt.println("Day 05.1: ", sum)
}

page_has_rule_for_other_page :: proc(page, other_page: u8) -> bool {
	rule := print_rules[page]
	return slice.contains(rule.page_order[:], other_page)
}

page_order_satisfied :: proc(page, other_page: u8, other_page_order: Page_Order) -> bool {
	rule := print_rules[page]
	page_order_slice: []u8
	switch other_page_order {
	case .Before: page_order_slice = rule.page_order[:rule.before_count]
	case .After: page_order_slice = rule.page_order[rule.before_count:]
	}
	return slice.contains(page_order_slice, other_page)
}
