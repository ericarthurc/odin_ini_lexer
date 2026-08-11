package ini

import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import "vendor:vulkan"

Token_Type :: enum {
	Section,
	Key,
	Assign,
	Value,
	Comment,
	Illegal,
	EOF,
}

Token :: struct {
	type: Token_Type,
	text: string,
	line: int,
}

Lexer :: struct {
	src:  string,
	pos:  int,
	line: int,
}

// this is assuming a standard size, should be moved to utf8 decoding
peek :: proc(l: ^Lexer) -> u8 {
	if l.pos >= len(l.src) do return 0
	return l.src[l.pos]
}

step :: proc(l: ^Lexer) -> u8 {
	c := peek(l)
	l.pos += 1
	return c
}

scan_until :: proc(l: ^Lexer, check: ..rune) -> int {
	end_pos: int

	for v, i in l.src[l.pos:] {
		if v == '\n' {
			end_pos = l.pos + i
			l.line += 1
			return end_pos
		}

		for c in check {
			if v == c {
				end_pos = l.pos + i
				return end_pos
			}
		}
	}

	end_pos = len(l.src)

	return end_pos

}

next_token :: proc(l: ^Lexer) -> Token {
	t: Token

	// check for unicode whitespace characters
	for unicode.is_space(rune(peek(l))) {
		step(l)
	}

	start := l.pos
	c := peek(l)

	// this needs to be handled differently, like with a \n check
	t.line = l.line

	switch {
	case c == 0:
		t.type = .EOF
		t.text = ""

	case c == '[':
		t.type = .Section
		t.text = l.src[start:l.pos]
		step(l)

	case c == '=' || c == ':':
		t.type = .Assign
		t.text = l.src[start:l.pos]
		step(l)

	case unicode.is_letter(rune(c)) || c == '"' || c == '\'':
		t.type = .Value
		if c == '"' || c == '\'' {
			// end := scan_until(l, '"', '\'')
			// l.pos = end
			// t.text = l.src[start:end]
		} else {
			end := scan_until(l, '=', ':')
			l.pos = end - 1 // rest the cursor to the symbol
			t.text = l.src[start:end]
		}
		step(l)

	case:
		t.type = .Illegal
		t.text = l.src[start:l.pos]
		step(l)
	}

	return t
}


// main :: proc() {

// 	t := Lexer {
// 		src = `food=sda
// 		hotdog=pizza
// 		taco=waffle`,
// 	}

// 	for {
// 		tok := next_token(&t)
// 		fmt.println(tok)
// 		if tok.type == .EOF do break
// 	}
// }
