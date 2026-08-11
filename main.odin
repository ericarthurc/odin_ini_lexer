package ini

import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"

// INI file
/*
[section]
key:value
hello=world
;comment here
[section]
foo=bar
*/

// JSON output
/*
{
  "section": {
    "key": "value",
    "hello": "world",
    "foo": "bar"
  }
}
*/


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

	arena: vmem.Arena
	arena_allocator := vmem.arena_allocator(&arena)

	// // reading from a file for now
	// data, err := os.read_entire_file_from_path("tests/test.ini", arena_allocator)
	// if err != nil {
	// 	panic("mc what")
	// }

	// // a new 'iter' header, but the underlying pointer is still the same as data
	// iter := string(data)

	// for line in strings.split_lines_iterator(&iter) {
	// 	fmt.println(line)
	// }

	vmem.arena_destroy(&arena)
}
