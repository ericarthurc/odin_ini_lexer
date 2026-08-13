package ini

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
	src:             string,
	pos:             int,
	line:            int,
	ch:              u8,
	expecting_value: bool,
}


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

init_lexer :: proc(src: string) -> Lexer {
	l: Lexer
	l.src = src
	lexer_read(&l)

	return l
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

is_character_start :: proc(l: ^Lexer) -> bool {
	r, size := utf8.decode_rune_in_string(l.src[l.pos - 1:])

	return unicode.is_letter(r)
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
		l.expecting_value = true
		lexer_read(l)

	case is_character_start(l) || l.ch == '\"' || l.ch == '\'':
		starting_pos: int

		if l.expecting_value {
			starting_pos, _ = scan_until(l)
			t.type = .Value
			l.expecting_value = false
		} else {
			found_assign: bool
			starting_pos, found_assign = scan_until(l, '=', ':')
			if found_assign {
				t.type = .Key
			} else {
				t.type = .Illegal
			}
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
