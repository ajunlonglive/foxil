// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module util

// wrap_string wraps the given string within limite width in characters.
pub fn wrap_string(str string, line_width int, nl string) string {
	words := str.fields()
	if words.len == 0 {
		return ''
	}
	mut wrapped := words[0]
	mut space_left := line_width - wrapped.len
	for word in words[1..] {
		if word.len + 1 > space_left {
			wrapped += '$nl$word'
			space_left = line_width - word.len
		} else {
			wrapped += ' ' + word
			space_left -= 1 + word.len
		}
	}
	return wrapped
}
