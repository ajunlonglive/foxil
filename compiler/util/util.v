// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module util

import os

pub fn read_file(file_path string) ?string {
	raw_text := os.read_file(file_path) or { return error('failed to open $file_path') }
	return skip_bom(raw_text)
}

pub fn skip_bom(file_content string) string {
	mut raw_text := file_content
	// BOM check
	if raw_text.len >= 3 {
		unsafe {
			c_text := raw_text.str
			if c_text[0] == 0xEF && c_text[1] == 0xBB && c_text[2] == 0xBF {
				// skip three BOM bytes
				offset_from_begin := 3
				raw_text = tos(c_text[offset_from_begin], vstrlen(c_text) - offset_from_begin)
			}
		}
	}
	return raw_text
}

[inline]
pub fn convert_to_valid_c_ident(str string) string {
	mut res := ''
	for c in str {
		if is_name_char(c) {
			res += c.ascii_str()
		} else {
			if c == `.` {
				res += '__'
			} else {
				res += '_'
			}
		}
	}
	return res
}

// is_name_char returns true if `c` is a letter or underscore, false otherwise
pub fn is_name_char(c byte) bool {
	return (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_`
}

// is_func_char returns true if `c` is a letter, underscore, or numeric digit
pub fn is_func_char(c byte) bool {
	return (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_` || c.is_digit()
}
