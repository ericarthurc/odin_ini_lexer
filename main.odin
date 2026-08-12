package ini

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


	l: Lexer

	arena: vmem.Arena
	arena_allocator := vmem.arena_allocator(&arena)


	data, err := os.read_entire_file_from_path("tests/test.ini", arena_allocator)
	if err != nil {
		panic("mc what")
	}

	init_lexer(&l, string(data))


	tokens := make([dynamic]Token, arena_allocator)

	for {
		tok := next_token(&l)
		// fmt.println(tok)
		if tok.type == .EOF do break

		append(&tokens, tok)
	}

	fmt.println(tokens[:])

	vmem.arena_destroy(&arena)
}
