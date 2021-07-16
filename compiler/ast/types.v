// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

import compiler.token

pub const void_t = Type{
	sym: &Symbol{
		name: 'void'
		gname: 'void'
	}
}

pub struct Type {
pub mut:
	sym        &Symbol = 0
	nr_muls    int
	is_array   bool
	array_info &ArrayInfo = 0
	unresolved bool
	pos        token.Position
}

pub struct ArrayInfo {
pub mut:
	typ  Type
	size int
}
