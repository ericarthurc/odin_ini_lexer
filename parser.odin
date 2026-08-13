package ini

import "base:runtime"
import "core:encoding/json"
import "core:fmt"

Parser :: struct {
	ini_map:         map[string]map[string]string,
	current_sub_map: map[string]string,
	current_section: string,
	previous_text:   string,
	allocator:       runtime.Allocator,
}


init_parser :: proc(allocator: runtime.Allocator, loc := #caller_location) -> Parser {
	top_map := make(map[string]map[string]string, allocator)

	p: Parser
	p.ini_map = top_map
	p.allocator = allocator

	return p
}

parse :: proc(
	data: string,
	allocator: runtime.Allocator = context.allocator,
	loc := #caller_location,
) -> Parser {
	l := init_lexer(data)
	p := init_parser(allocator)

	for {
		tok := next_token(&l)
		parse_token(tok, &p)
		if tok.type == .EOF do break
	}

	return p
}


parse_token :: proc(t: Token, p: ^Parser) {
	// not matching all token types
	#partial switch t.type {
	case .Section:
		p.current_section = t.text
		if t.text not_in p.ini_map {
			p.ini_map[t.text] = make(map[string]string, p.allocator)
		}

	case .Key:
		if p.current_section == "" {
			p.current_section = "global"
		}

		if existing, ok := p.ini_map[p.current_section]; ok {
			p.current_sub_map = existing
		} else {
			p.current_sub_map = make(map[string]string, p.allocator)
		}

		p.current_sub_map[t.text] = ""
		p.previous_text = t.text
		p.ini_map[p.current_section] = p.current_sub_map

	case .Value:
		p.current_sub_map[p.previous_text] = t.text
	}
}


map_to_json :: proc(p: ^Parser) -> string {
	data, _ := json.marshal(p.ini_map, {}, p.allocator)
	return string(data)
}
