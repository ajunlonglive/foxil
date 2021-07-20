// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module parser

import compiler
import compiler.ast
import compiler.token
import compiler.util
import math.mathutil as mu

const (
	single_quote = `\'`
	double_quote = `"`
	num_sep      = `_`
	b_lf         = 10
	b_cr         = 13
)

pub struct Scanner {
	text     string
	filepath string
mut:
	pos         int
	line_nr     int
	line_ends   []int
	nr_lines    int
	last_nl_pos int = -1
	is_started  bool
	is_cr_lf    bool
	eofs        int
	all_tokens  []token.Token
	tidx        int
}

pub fn new_scanner(sf &ast.SourceFile) &Scanner {
	mut s := &Scanner{
		text: sf.content
		filepath: sf.path
	}
	s.init_scan()
	return s
}

pub fn new_scanner_with_text(text string) &Scanner {
	mut s := &Scanner{
		text: text
		filepath: '<in-memory>'
	}
	s.init_scan()
	return s
}

[inline]
pub fn (mut s Scanner) scan() token.Token {
	return s.buffer_scan()
}

fn (mut s Scanner) buffer_scan() token.Token {
	for {
		cidx := s.tidx
		s.tidx++
		if cidx >= s.all_tokens.len {
			return s.end_of_file()
		}
		tok := s.all_tokens[cidx]
		return tok
	}
	return s.end_of_file()
}

fn (mut s Scanner) init_scan() {
	s.scan_remaining_text()
	s.tidx = 0
}

fn (mut s Scanner) scan_remaining_text() {
	for {
		t := s.text_scan()
		s.all_tokens << t
		if t.kind == .eof {
			break
		}
	}
}

[inline]
fn (s &Scanner) cur_pos() token.Position {
	return token.Position{
		file: s.filepath
		len: 1
		line: s.line_nr
		pos: s.pos
		col: s.current_column()
	}
}

[inline]
fn (mut s Scanner) new_token(tok_kind token.Kind, lit string, len int) token.Token {
	return token.Token{
		file: s.filepath
		kind: tok_kind
		lit: lit
		line_nr: s.line_nr + 1
		col: mu.max(1, s.current_column() - len + 1)
		pos: s.pos - len + 1
		len: len
	}
}

[inline]
fn (s &Scanner) new_eof_token() token.Token {
	return token.Token{
		file: s.filepath
		kind: .eof
		lit: ''
		line_nr: s.line_nr + 1
		col: s.current_column()
		len: 1
	}
}

fn (mut s Scanner) ident_name() string {
	start := s.pos
	s.pos++
	for s.pos < s.text.len {
		c := s.text[s.pos]
		double_colon := (c == `:` && s.look_ahead(1) == `:`)
		if double_colon {
			s.pos++
		}
		if !((c == `.` || double_colon) || util.is_name_char(c) || c.is_digit()) {
			break
		}
		s.pos++
	}
	name := s.text[start..s.pos]
	s.pos--
	return name
}

fn (mut s Scanner) ident_bin_number() string {
	mut has_wrong_digit := false
	mut first_wrong_digit_pos := 0
	mut first_wrong_digit := byte(0)
	start_pos := s.pos
	s.pos += 2
	if s.pos < s.text.len && s.text[s.pos] == parser.num_sep {
		s.error('separator `_` is only valid between digits in a numeric literal').emit()
	}
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == parser.num_sep && s.text[s.pos - 1] == parser.num_sep {
			s.error('cannot use `_` consecutively').emit()
		}
		if !c.is_bin_digit() && c != parser.num_sep {
			if !c.is_digit() && !c.is_letter() {
				break
			} else if !has_wrong_digit {
				has_wrong_digit = true
				first_wrong_digit_pos = s.pos
				first_wrong_digit = c
			}
		}
		s.pos++
	}
	if s.text[s.pos - 1] == parser.num_sep {
		s.pos--
		s.error('cannot use `_` at the end of a numeric literal').emit()
	} else if start_pos + 2 == s.pos {
		s.pos-- // adjust error position
		s.error('number part of this binary is not provided').emit()
	} else if has_wrong_digit {
		s.pos = first_wrong_digit_pos // adjust error position
		s.error('this binary number has unsuitable digit `$first_wrong_digit.ascii_str()`').emit()
	}
	number := s.text[start_pos..s.pos]
	s.pos--
	return number
}

fn (mut s Scanner) ident_hex_number() string {
	mut has_wrong_digit := false
	mut first_wrong_digit_pos := 0
	mut first_wrong_digit := byte(0)
	start_pos := s.pos
	if s.pos + 2 >= s.text.len {
		return '0x'
	}
	s.pos += 2
	if s.pos < s.text.len && s.text[s.pos] == parser.num_sep {
		s.error('separator `_` is only valid between digits in a numeric literal').emit()
	}
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == parser.num_sep && s.text[s.pos - 1] == parser.num_sep {
			s.error('cannot use `_` consecutively').emit()
		}
		if !c.is_hex_digit() && c != parser.num_sep {
			if !c.is_digit() && !c.is_letter() {
				break
			} else if !has_wrong_digit {
				has_wrong_digit = true
				first_wrong_digit_pos = s.pos
				first_wrong_digit = c
			}
		}
		s.pos++
	}
	if s.text[s.pos - 1] == parser.num_sep {
		s.pos--
		s.error('cannot use `_` at the end of a numeric literal').emit()
	} else if start_pos + 2 == s.pos {
		s.pos-- // adjust error position
		s.error('number part of this hexadecimal is not provided').emit()
	} else if has_wrong_digit {
		s.pos = first_wrong_digit_pos // adjust error position
		s.error('this hexadecimal number has unsuitable digit `$first_wrong_digit.ascii_str()`').emit()
	}
	number := s.text[start_pos..s.pos]
	s.pos--
	return number
}

fn (mut s Scanner) ident_oct_number() string {
	mut has_wrong_digit := false
	mut first_wrong_digit_pos := 0
	mut first_wrong_digit := byte(0)
	start_pos := s.pos
	s.pos += 2
	if s.pos < s.text.len && s.text[s.pos] == parser.num_sep {
		s.error('separator `_` is only valid between digits in a numeric literal').emit()
	}
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == parser.num_sep && s.text[s.pos - 1] == parser.num_sep {
			s.error('cannot use `_` consecutively').emit()
		}
		if !c.is_oct_digit() && c != parser.num_sep {
			if !c.is_digit() && !c.is_letter() {
				break
			} else if !has_wrong_digit {
				has_wrong_digit = true
				first_wrong_digit_pos = s.pos
				first_wrong_digit = c
			}
		}
		s.pos++
	}
	if s.text[s.pos - 1] == parser.num_sep {
		s.pos--
		s.error('cannot use `_` at the end of a numeric literal').emit()
	} else if start_pos + 2 == s.pos {
		s.pos-- // adjust error position
		s.error('number part of this octal is not provided').emit()
	} else if has_wrong_digit {
		s.pos = first_wrong_digit_pos // adjust error position
		s.error('this octal number has unsuitable digit `$first_wrong_digit.ascii_str()`').emit()
	}
	number := s.text[start_pos..s.pos]
	s.pos--
	return number
}

fn (mut s Scanner) ident_dec_number() string {
	mut has_wrong_digit := false
	mut first_wrong_digit_pos := 0
	mut first_wrong_digit := byte(0)
	start_pos := s.pos
	// scan integer part
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == parser.num_sep && s.text[s.pos - 1] == parser.num_sep {
			s.error('cannot use `_` consecutively').emit()
		}
		if !c.is_digit() && c != parser.num_sep {
			if !c.is_letter() || c in [`e`, `E`] {
				break
			} else if !has_wrong_digit {
				has_wrong_digit = true
				first_wrong_digit_pos = s.pos
				first_wrong_digit = c
			}
		}
		s.pos++
	}
	if s.text[s.pos - 1] == parser.num_sep {
		s.pos--
		s.error('cannot use `_` at the end of a numeric literal').emit()
	}
	mut call_method := false // true for, e.g., 16.str(), 16.6.str(), 16e6.str()
	mut is_range := false // true for, e.g., 6..16
	// scan fractional part
	if s.pos < s.text.len && s.text[s.pos] == `.` {
		s.pos++
		if s.pos < s.text.len {
			// 16.6, 16.6.str()
			if s.text[s.pos].is_digit() {
				for s.pos < s.text.len {
					c := s.text[s.pos]
					if !c.is_digit() {
						if !c.is_letter() || c in [`e`, `E`] {
							// 16.6.str()
							if c == `.` && s.pos + 1 < s.text.len && s.text[s.pos + 1].is_letter() {
								call_method = true
							}
							break
						} else if !has_wrong_digit {
							has_wrong_digit = true
							first_wrong_digit_pos = s.pos
							first_wrong_digit = c
						}
					}
					s.pos++
				}
			} else if s.text[s.pos] == `.` {
				// 4.. a range
				is_range = true
				s.pos--
			} else if s.text[s.pos] in [`e`, `E`] {
				// 6.e6
			} else if s.text[s.pos].is_letter() {
				// 16.str()
				call_method = true
				s.pos--
			} else {
				// 5.
			}
		}
	}
	// scan exponential part
	mut has_exp := false
	if s.pos < s.text.len && s.text[s.pos] in [`e`, `E`] {
		has_exp = true
		s.pos++
		if s.pos < s.text.len && s.text[s.pos] in [`-`, `+`] {
			s.pos++
		}
		for s.pos < s.text.len {
			c := s.text[s.pos]
			if !c.is_digit() {
				if !c.is_letter() {
					// 6e6.str()
					if c == `.` && s.pos + 1 < s.text.len && s.text[s.pos + 1].is_letter() {
						call_method = true
					}
					break
				} else if !has_wrong_digit {
					has_wrong_digit = true
					first_wrong_digit_pos = s.pos
					first_wrong_digit = c
				}
			}
			s.pos++
		}
	}
	if has_wrong_digit {
		// error check: wrong digit
		s.pos = first_wrong_digit_pos // adjust error position
		s.error('this number has unsuitable digit `$first_wrong_digit.ascii_str()`').emit()
	} else if s.text[s.pos - 1] in [`e`, `E`] {
		// error check: 5e
		s.pos-- // adjust error position
		s.error('exponent has no digits').emit()
	} else if s.pos < s.text.len && s.text[s.pos] == `.` && !is_range && !call_method {
		// error check: 1.23.4, 123.e+3.4
		if has_exp {
			s.error('exponential part should be integer').emit()
		} else {
			s.error('too many decimal points in number').emit()
		}
	}
	number := s.text[start_pos..s.pos]
	s.pos--
	return number
}

fn (mut s Scanner) ident_number() string {
	if s.expect('0b', s.pos) {
		return s.ident_bin_number()
	} else if s.expect('0x', s.pos) {
		return s.ident_hex_number()
	} else if s.expect('0o', s.pos) {
		return s.ident_oct_number()
	} else {
		return s.ident_dec_number()
	}
}

fn trim_slash_line_break(str string) string {
	mut start := 0
	mut ret_str := str
	for {
		idx := ret_str.index_after('\\\n', start)
		if idx != -1 {
			ret_str = ret_str[..idx] + ret_str[idx + 2..].trim_left(' \n\t\v\f\r')
			start = idx
		} else {
			break
		}
	}
	return ret_str
}

fn decode_u_escapes(s string, start int, escapes_pos []int) string {
	if escapes_pos.len == 0 {
		return s
	}
	mut ss := []string{cap: escapes_pos.len * 2 + 1}
	ss << s[..escapes_pos[0] - start]
	for i, pos in escapes_pos {
		idx := pos - start
		end_idx := idx + 6
		ss << s[idx + 2..end_idx].u32().str()
		if i + 1 < escapes_pos.len {
			ss << s[end_idx..escapes_pos[i + 1] - start]
		} else {
			ss << s[end_idx..]
		}
	}
	return ss.join('')
}

fn (mut s Scanner) ident_char() string {
	start := s.pos
	slash := `\\`
	mut len := 0
	for {
		s.pos++
		if s.pos >= s.text.len {
			break
		}
		if s.text[s.pos] != slash {
			len++
		}
		double_slash := s.expect('\\\\', s.pos - 2)
		if s.text[s.pos] == parser.single_quote && (s.text[s.pos - 1] != slash || double_slash) {
			if double_slash {
				len++
			}
			break
		}
	}
	len--
	c := s.text[start + 1..s.pos]
	if len != 1 {
		u := c.runes()
		oldpos := s.pos
		if u.len > 1 {
			s.pos -= u.len + 2
			help := 'if you meant to write a string literal, use double quotes'
			mut e := s.error('character literal may only contain one codepoint')
			e.help(help).emit()
			s.pos = oldpos
		} else if len == 0 {
			s.pos -= u.len + 2
			s.error('empty character literal').emit()
			s.pos = oldpos
		}
	}
	return c
}

fn (s &Scanner) count_symbol_before(p int, sym byte) int {
	mut count := 0
	for i := p; i >= 0; i-- {
		if s.text[i] != sym {
			break
		}
		count++
	}
	return count
}

fn (mut s Scanner) ident_string() string {
	mut n_cr_chars := 0
	mut start := s.pos
	start_char := s.text[start]
	if start_char == parser.double_quote {
		start++
	} else if start_char == parser.b_lf {
		s.inc_line_number()
	}
	mut u_escape_pos := []int{}
	slash := `\\`
	for {
		s.pos++
		if s.pos >= s.text.len {
			s.error('unfinished string literal').emit()
		}
		c := s.text[s.pos]
		prevc := s.text[s.pos - 1]
		// end of string
		if c == parser.double_quote
			&& (prevc != slash || (prevc == slash && s.text[s.pos - 2] == slash)) {
			// handle "456\\" slash at the end
			break
		}
		if c == parser.b_cr {
			n_cr_chars++
		}
		if c == parser.b_lf {
			s.inc_line_number()
		}
		// don't allow \0 and \x00
		if c == `0` && s.pos > 2 && prevc == slash {
			if (s.pos < s.text.len - 1 && s.text[s.pos + 1].is_digit())
				|| s.count_symbol_before(s.pos - 1, slash) % 2 == 0 {
			} else {
				s.error(r'cannot use `\0` (NULL character) in the string literal').emit()
			}
		}
		if c == `0` && s.pos > 5 && s.expect('\\x0', s.pos - 3) {
			if s.count_symbol_before(s.pos - 3, slash) % 2 == 0 {
			} else {
				s.error(r'cannot use `\x00` (NULL character) in the string literal').emit()
			}
		}
		// escape '\x', '\u'
		if prevc == slash && s.count_symbol_before(s.pos - 2, slash) % 2 == 0 {
			// escape '\x'
			if c == `x`
				&& (s.text[s.pos + 1] == parser.double_quote || !s.text[s.pos + 1].is_hex_digit()) {
				s.error('`\\x` used with no following hexadecimal digits').emit()
			}
			// escape '\u'
			if c == `u` {
				if s.text[s.pos + 1] == parser.double_quote
					|| s.text[s.pos + 2] == parser.double_quote
					|| s.text[s.pos + 3] == parser.double_quote
					|| s.text[s.pos + 4] == parser.double_quote || !s.text[s.pos + 1].is_hex_digit()
					|| !s.text[s.pos + 2].is_hex_digit() || !s.text[s.pos + 3].is_hex_digit()
					|| !s.text[s.pos + 4].is_hex_digit() {
					s.error('incomplete unicode character value').emit()
				}
				u_escape_pos << s.pos - 1
			}
		}
	}
	mut lit := ''
	end := s.pos
	if start <= s.pos {
		mut string_so_far := s.text[start..end]
		if u_escape_pos.len > 0 {
			string_so_far = decode_u_escapes(string_so_far, start, u_escape_pos)
		}
		if n_cr_chars > 0 {
			string_so_far = string_so_far.replace('\r', '')
		}
		lit = if string_so_far.contains('\\\n') {
			trim_slash_line_break(string_so_far)
		} else {
			string_so_far
		}
	}
	return lit
}

[inline]
fn is_nl(c byte) bool {
	return c == parser.b_cr || c == parser.b_lf
}

fn (mut s Scanner) skip_whitespace() {
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if !(c == 32 || (c > 8 && c < 14) || (c == 0x85) || (c == 0xa0)) {
			return
		}
		if s.pos + 1 < s.text.len && c == parser.b_cr && s.text[s.pos + 1] == parser.b_lf {
			s.is_cr_lf = true
		}
		if is_nl(c) && !(s.pos > 0 && s.text[s.pos - 1] == parser.b_cr && c == parser.b_lf) {
			s.inc_line_number()
		}
		s.pos++
	}
}

fn (mut s Scanner) end_of_file() token.Token {
	s.eofs++
	if s.eofs > 50 {
		s.line_nr--
		msg_f := if s.filepath != '' { 'file $s.filepath' } else { 'text' }
		compiler.foxil_error(
			'the end of $msg_f has been reached 50 times already, the blux parser is probably stuck.\n' +
			'This should not happen. Please report the bug here, and include the last 2-3 lines of your source code')
	}
	if s.pos != s.text.len && s.eofs == 1 {
		s.inc_line_number()
	}
	s.pos = s.text.len
	return s.new_eof_token()
}

fn (s &Scanner) peek_token(n int) token.Token {
	idx := s.tidx + n
	if idx >= s.all_tokens.len {
		return s.new_eof_token()
	}
	return s.all_tokens[idx]
}

fn (s &Scanner) look_ahead(n int) byte {
	if s.pos + n < s.text.len {
		return s.text[s.pos + n]
	}
	return 0
}

fn (mut s Scanner) text_scan() token.Token {
	for {
		if s.is_started {
			s.pos++
		} else {
			s.is_started = true
		}
		s.skip_whitespace()
		if s.pos >= s.text.len {
			return s.end_of_file()
		}
		c := s.text[s.pos]
		nextc := s.look_ahead(1)
		// name or keyword
		double_colon := (c == `:` && s.look_ahead(1) == `:`)
		if util.is_name_char(c) || c == `.` || double_colon {
			if double_colon {
				s.pos++
			}
			name := s.ident_name()
			next_char := s.look_ahead(1)
			kind := token.lookup(name)
			if kind != .unknown {
				return s.new_token(kind, name, name.len)
			}
			if s.pos == 0 && next_char == ` ` {
				s.pos++
			}
			return s.new_token(.name, name, name.len)
		} else if c.is_digit() || (c == `.` && nextc.is_digit()) {
			// `123`, `.123`
			mut start_pos := s.pos
			for start_pos < s.text.len && s.text[start_pos] == `0` {
				start_pos++
			}
			// how many prefix zeros should be jumped
			mut prefix_zero_num := start_pos - s.pos
			// for 0b, 0o, 0x, the heading zero shouldn't be jumped
			if start_pos == s.text.len || (c == `0` && !s.text[start_pos].is_digit()) {
				prefix_zero_num--
			}
			s.pos += prefix_zero_num // jump these zeros
			num := s.ident_number()
			return s.new_token(.number, num.replace('_', ''), num.len)
		}
		// all other tokens
		match c {
			`+` {
				return s.new_token(.plus, '', 1)
			}
			`-` {
				return s.new_token(.minus, '', 1)
			}
			`*` {
				return s.new_token(.mult, '', 1)
			}
			`/` {
				return s.new_token(.div, '', 1)
			}
			`%` {
				return s.new_token(.mod, '', 1)
			}
			`^` {
				return s.new_token(.xor, '', 1)
			}
			`|` {
				return s.new_token(.pipe, '', 1)
			}
			`&` {
				return s.new_token(.amp, '', 1)
			}
			`~` {
				return s.new_token(.bit_not, '', 1)
			}
			`?` {
				return s.new_token(.question, '', 1)
			}
			`#` {
				return s.new_token(.hash, '', 1)
			}
			`,` {
				return s.new_token(.comma, '', 1)
			}
			`;` {
				// comment: ; hello
				s.ignore_line()
				continue
			}
			`:` {
				return s.new_token(.colon, '', 1)
			}
			`$` {
				return s.new_token(.dollar, '', 1)
			}
			`@` {
				return s.new_token(.at, '', 1)
			}
			`=` {
				return s.new_token(.assign, '', 1)
			}
			`!` {
				return s.new_token(.not, '', 1)
			}
			`.` {
				if nextc == `.` && s.look_ahead(2) == `.` {
					s.pos += 2
					return s.new_token(.ellipsis, '', 3)
				} else if nextc == `.` {
					s.pos++
					return s.new_token(.dot_dot, '', 2)
				}
				return s.new_token(.dot, '', 1)
			}
			`{` {
				return s.new_token(.lbrace, '', 1)
			}
			`}` {
				return s.new_token(.rbrace, '', 1)
			}
			`(` {
				return s.new_token(.lparen, '', 1)
			}
			`)` {
				return s.new_token(.rparen, '', 1)
			}
			`[` {
				return s.new_token(.lbracket, '', 1)
			}
			`]` {
				return s.new_token(.rbracket, '', 1)
			}
			parser.single_quote {
				ident_char := s.ident_char()
				return s.new_token(.char, ident_char, ident_char.len + 2)
			}
			parser.double_quote {
				ident_string := s.ident_string()
				return s.new_token(.string, ident_string, ident_string.len + 2)
			}
			else {}
		}
		$if windows {
			if c == `\0` {
				return s.end_of_file()
			}
		}
		s.invalid_character()
		break
	}
	return s.end_of_file()
}

fn (mut s Scanner) invalid_character() {
	len := utf8_char_len(s.text[s.pos])
	end := mu.min(s.pos + len, s.text.len)
	c := s.text[s.pos..end]
	s.error('invalid character `$c`').emit()
}

[inline]
fn (s &Scanner) current_column() int {
	return s.pos - s.last_nl_pos
}

[direct_array_access; inline]
fn (s &Scanner) expect(want string, start_pos int) bool {
	end_pos := start_pos + want.len
	if start_pos < 0 || end_pos < 0 || start_pos >= s.text.len || end_pos > s.text.len {
		return false
	}
	for pos := start_pos; pos < end_pos; pos++ {
		if s.text[pos] != want[pos - start_pos] {
			return false
		}
	}
	return true
}

[inline]
fn (mut s Scanner) ignore_line() {
	s.eat_to_end_of_line()
	s.inc_line_number()
}

[direct_array_access; inline]
fn (mut s Scanner) eat_to_end_of_line() {
	for s.pos < s.text.len && s.text[s.pos] != parser.b_lf {
		s.pos++
	}
}

[inline]
fn (mut s Scanner) inc_line_number() {
	s.last_nl_pos = mu.min(s.text.len - 1, s.pos)
	if s.is_cr_lf {
		s.last_nl_pos++
	}
	s.line_nr++
	s.line_ends << s.pos
	if s.line_nr > s.nr_lines {
		s.nr_lines = s.line_nr
	}
}

fn (s &Scanner) error(msg string) &compiler.Report {
	if s.filepath == '<in-memory>' {
		compiler.foxil_error('from scanner in $s.cur_pos(): $msg')
	}
	return report.error(msg, s.cur_pos())
}
