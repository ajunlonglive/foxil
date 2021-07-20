// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

pub type Type = int

pub enum TypeFlag {
	unresolved
}

// return new type with TypeSymbol idx set to `idx`
[inline]
pub fn new_type(idx int) Type {
	if idx < 0 || idx > 65535 {
		panic('new_type: idx must be between 0 & 65535')
	}
	return idx
}

// return new type with TypeSymbol idx set to `idx` & nr_muls set to `nr_muls`
[inline]
pub fn new_type_ptr(idx int, nr_muls int) Type {
	if idx < 0 || idx > 65535 {
		panic('new_type_ptr: idx must be between 0 & 65535')
	}
	if nr_muls < 0 || nr_muls > 255 {
		panic('new_type_ptr: nr_muls must be between 0 & 255')
	}
	return (nr_muls << 16) | u16(idx)
}

// return TypeSymbol idx for `t`
[inline]
pub fn (t Type) idx() int {
	return u16(t) & 0xffff
}

// return nr_muls for `t`
[inline]
pub fn (t Type) nr_muls() int {
	return (int(t) >> 16) & 0xff
}

// set nr_muls on `t` and return it
[inline]
pub fn (t Type) set_nr_muls(nr_muls int) Type {
	if nr_muls < 0 || nr_muls > 255 {
		panic('set_nr_muls: nr_muls must be between 0 & 255')
	}
	return int(t) & 0xff00ffff | (nr_muls << 16)
}

// increments nr_nuls on `t` and return it
[inline]
pub fn (t Type) to_ptr() Type {
	nr_muls := (int(t) >> 16) & 0xff
	if nr_muls == 255 {
		panic('to_ptr: nr_muls is already at max of 255')
	}
	return int(t) & 0xff00ffff | ((nr_muls + 1) << 16)
}

// decrement nr_muls on `t` and return it
[inline]
pub fn (t Type) deref() Type {
	nr_muls := (int(t) >> 16) & 0xff
	if nr_muls == 0 {
		panic('deref: type `$t` is not a pointer')
	}
	return int(t) & 0xff00ffff | ((nr_muls - 1) << 16)
}

// copy flags & nr_muls from `t_from` to `t` and return `t`
[inline]
pub fn (t Type) derive(t_from Type) Type {
	return (0xffff0000 & t_from) | u16(t)
}

// copy flags from `t_from` to `t` and return `t`
[inline]
pub fn (t Type) derive_add_muls(t_from Type) Type {
	return Type((0xff000000 & t_from) | u16(t)).set_nr_muls(t.nr_muls() + t_from.nr_muls())
}

[inline]
pub fn (t Type) is_full() bool {
	return t != 0 && t != ast.void_type
}

// return true if `t` is a pointer (nr_muls>0)
[inline]
pub fn (t Type) is_ptr() bool {
	return (int(t) >> 16) & 0xff > 0
}

[inline]
pub fn (t Type) is_void() bool {
	return t == ast.void_type
}

[inline]
pub fn (t Type) is_char() bool {
	return t == ast.char_type
}

[inline]
pub fn (t Type) is_uchar() bool {
	return t == ast.uchar_type
}

[inline]
pub fn (t Type) is_char_or_uchar() bool {
	return t.is_char() || t.is_uchar()
}

[inline]
pub fn (t Type) is_bool() bool {
	return t == ast.bool_type
}

[inline]
pub fn (t Type) is_rawptr() bool {
	return t == ast.rawptr_type
}

[inline]
pub fn (typ Type) is_float() bool {
	return typ.idx() in ast.float_type_idxs
}

[inline]
pub fn (typ Type) is_int() bool {
	return typ.idx() in ast.integer_type_idxs
}

[inline]
pub fn (typ Type) is_signed() bool {
	return typ.idx() in ast.signed_integer_type_idxs
}

[inline]
pub fn (typ Type) is_unsigned() bool {
	return typ.idx() in ast.unsigned_integer_type_idxs
}

[inline]
pub fn (typ Type) is_number() bool {
	return typ.idx() in ast.number_type_idxs
}

// set `flag` on `t` and return `t`
[inline]
pub fn (t Type) set_flag(flag TypeFlag) Type {
	return int(t) | (1 << (int(flag) + 24))
}

// clear `flag` on `t` and return `t`
[inline]
pub fn (t Type) clear_flag(flag TypeFlag) Type {
	return int(t) & ~(1 << (int(flag) + 24))
}

// clear all flags
[inline]
pub fn (t Type) clear_flags() Type {
	return int(t) & 0xffffff
}

// return true if `flag` is set on `t`
[inline]
pub fn (t Type) has_flag(flag TypeFlag) bool {
	return int(t) & (1 << (int(flag) + 24)) > 0
}

pub fn typ2str(t Type) string {
	name := g_context.get_type_name(t)
	ptr := if t.is_ptr() { '*'.repeat(t.nr_muls()) } else { '' }
	return '$name$ptr'
}

pub const (
	void_type_idx   = 0
	bool_type_idx   = 1
	char_type_idx   = 2
	uchar_type_idx  = 3
	i8_type_idx     = 4
	i16_type_idx    = 5
	i32_type_idx    = 6
	i64_type_idx    = 7
	u8_type_idx     = 8
	u16_type_idx    = 9
	u32_type_idx    = 10
	u64_type_idx    = 11
	f32_type_idx    = 12
	f64_type_idx    = 13
	rawptr_type_idx = 14
)

pub const (
	integer_type_idxs          = [i8_type_idx, i16_type_idx, i32_type_idx, i64_type_idx, u8_type_idx,
		u16_type_idx, u32_type_idx, u64_type_idx, char_type_idx, uchar_type_idx]
	signed_integer_type_idxs   = [i8_type_idx, i16_type_idx, i32_type_idx, i64_type_idx,
		char_type_idx,
	]
	unsigned_integer_type_idxs = [u8_type_idx, u16_type_idx, u32_type_idx, u64_type_idx]
	float_type_idxs            = [f32_type_idx, f64_type_idx]
	number_type_idxs           = [i8_type_idx, i16_type_idx, i32_type_idx, i64_type_idx, u8_type_idx,
		u16_type_idx, u32_type_idx, u64_type_idx, f32_type_idx, f64_type_idx]
)

pub const (
	void_type   = new_type(void_type_idx)
	bool_type   = new_type(bool_type_idx)
	char_type   = new_type(char_type_idx)
	uchar_type  = new_type(uchar_type_idx)
	i8_type     = new_type(i8_type_idx)
	i16_type    = new_type(i16_type_idx)
	i32_type    = new_type(i32_type_idx)
	i64_type    = new_type(i64_type_idx)
	u8_type     = new_type(u8_type_idx)
	u16_type    = new_type(u16_type_idx)
	u32_type    = new_type(u32_type_idx)
	u64_type    = new_type(u64_type_idx)
	f32_type    = new_type(f32_type_idx)
	f64_type    = new_type(f64_type_idx)
	rawptr_type = new_type(rawptr_type_idx)
)

pub const (
	native_type_names = ['void', 'bool', 'char', 'uchar', 'i8', 'i16', 'i32', 'i64', 'u8', 'u16',
		'u32', 'u64', 'f32', 'f64', 'rawptr']
)
