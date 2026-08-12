package main

import ini ".."
import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"

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

	data, err := os.read_entire_file_from_path("config.ini", arena_allocator)
	if err != nil {
		switch err {
		case .Not_Exist:
			panic("config.ini doesn't exist")
		}
		panic("some error occured while reading config.ini")
	}

	p := ini.parse(string(data), arena_allocator)

	json := ini.map_to_json(&p)

	fmt.println(json)

	vmem.arena_destroy(&arena)
}
