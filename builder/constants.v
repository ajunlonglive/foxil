// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module builder

struct Constant {
pub:
	name  string
	value Value
	typ   Type
}

pub fn (mut b Builder) new_const(name string, value Value) Constant {
	b.constants.writeln('@$name = const $value')
	return Constant{
		name: name
		value: value
		typ: value.typ
	}
}
