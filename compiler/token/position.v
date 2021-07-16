// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module token

import math.mathutil as mu

pub struct Position {
pub:
	file string
	line int
	col  int
	pos  int
	len  int
	tidx int
}

[inline]
pub fn (pos Position) str() string {
	return '$pos.file:${pos.line + 1}:${mu.max(1, pos.col)}'
}

// extend extends the current position, making use of another position
// and returns a new Position with these changes
[inline]
pub fn (pos Position) extend(end Position) Position {
	return Position{
		...pos
		len: end.pos - pos.pos + end.len
	}
}

// position returns the position of this token
[inline]
pub fn (tok Token) position() Position {
	return Position{
		file: tok.file
		len: tok.len
		line: tok.line_nr - 1
		pos: tok.pos
		col: tok.col - 1
		tidx: tok.tidx
	}
}
