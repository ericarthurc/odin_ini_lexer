package main

import ini ".."
import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"

main :: proc() {
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
