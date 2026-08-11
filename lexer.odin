package ini

import "core:fmt"
import "core:log"
import "core:unicode"
import "core:unicode/utf8"

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
	ch:   u8, // consider rune here
}

// this is assuming a standard size, should be moved to utf8 rune decoding
lexer_read :: proc(l: ^Lexer) {
	if l.pos >= len(l.src) {
		l.ch = 0
		l.pos += 1
		return
	}

	l.ch = l.src[l.pos]

	l.pos += 1

	new_line_check(l)
}

init_lexer :: proc(l: ^Lexer, src: string) {
	l.src = src
	lexer_read(l)
}

new_line_check :: proc(l: ^Lexer) {
	if l.ch != '\n' {
		return
	}

	l.line += 1
}

white_space_check :: proc(l: ^Lexer) {
	for unicode.is_space(rune(l.ch)) {
		lexer_read(l)
	}
}

scan_until :: proc(l: ^Lexer, check: ..rune) -> (int, bool) {
	starting_pos := l.pos - 1

	for l.ch != 0 {
		lexer_read(l)

		if l.ch == '\r' || l.ch == '\n' {
			return starting_pos, false
		}

		for c in check {
			if c == rune(l.ch) {
				return starting_pos, true
			}
		}
	}

	return starting_pos, false
}

next_token :: proc(l: ^Lexer) -> Token {
	white_space_check(l)

	t: Token

	t.line = l.line

	switch {
	case l.ch == 0:
		t.type = .EOF
		t.text = ""

	case l.ch == '[':
		starting_pos, okay := scan_until(l, ']')

		if okay {
			t.type = .Section
		} else {
			t.type = .Illegal
		}

		t.text = l.src[starting_pos + 1:l.pos - 1]
		lexer_read(l)

	case l.ch == '#' || l.ch == ';':
		t.type = .Comment

		starting_pos, _ := scan_until(l, '#', ';')
		t.text = l.src[starting_pos + 1:l.pos - 1]

	case l.ch == '=' || l.ch == ':':
		t.type = .Assign
		t.text = l.src[l.pos - 1:l.pos]
		lexer_read(l)

	case unicode.is_letter(rune(l.ch)) || l.ch == '\"' || l.ch == '\'':
		starting_pos, is_key := scan_until(l, '=', ':')
		if is_key {
			t.type = .Key
		} else {
			t.type = .Value
		}

		if l.src[starting_pos] == '\"' || l.src[starting_pos] == '\'' {
			t.text = l.src[starting_pos + 1:l.pos - 2]
		} else {
			t.text = l.src[starting_pos:l.pos - 1]
		}

	case:
		t.type = .Illegal
		t.text = l.src[l.pos - 1:l.pos]
		lexer_read(l)
	}

	return t
}
