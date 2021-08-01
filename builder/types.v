// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module builder

pub const (
	void_type   = Type{'void', 0}
	bool_type   = Type{'bool', 0}
	char_type   = Type{'char', 0}
	str_type    = Type{'str', 0}
	i8_type     = Type{'i8', 0}
	i16_type    = Type{'i16', 0}
	i32_type    = Type{'i32', 0}
	i64_type    = Type{'i64', 0}
	u8_type     = Type{'u8', 0}
	u16_type    = Type{'u16', 0}
	u32_type    = Type{'u32', 0}
	u64_type    = Type{'u64', 0}
	f32_type    = Type{'f32', 0}
	f64_type    = Type{'f64', 0}
	rawptr_type = Type{'rawptr', 0}
)

pub struct Type {
pub:
	name string
pub mut:
	nr_mults int
}

[inline]
pub fn (t Type) to_ptr() Type {
	return Type{
		name: t.name
		nr_mults: t.nr_mults + 1
	}
}

[inline]
pub fn (t Type) str() string {
	return t.name + '*'.repeat(t.nr_mults)
}

pub fn (mut b Builder) new_alias(name string, typ Type) Type {
	a_name := '@$name'
	b.aliases.writeln('$a_name = type $typ')
	return Type{
		name: a_name
	}
}

pub fn (mut b Builder) new_struct(fields []Type) Type {
	mut lit := '{ '
	for i, f in fields {
		lit += f.str()
		if i != fields.len - 1 {
			lit += ', '
		}
	}
	return Type{
		name: '$lit }'
	}
}

[inline]
pub fn (mut b Builder) new_array(size int, typ Type) Type {
	return Type{
		name: '[$size x $typ]'
	}
}
