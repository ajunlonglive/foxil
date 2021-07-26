// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

pub const invalid_type_symbol = &TypeSymbol{
	name: 'InvalidTypeSymbol'
}

pub struct TypeSymbol {
pub mut:
	name  string
	gname string
	kind  TypeKind
	info  TypeInfo
}

pub fn (t &TypeSymbol) str() string {
	return t.name
}

type TypeInfo = AliasInfo | ArrayInfo | StructInfo

pub enum TypeKind {
	void
	bool
	char
	str
	i8
	i16
	i32
	i64
	u8
	u16
	u32
	u64
	f32
	f64
	rawptr
	array
	struct_
	alias
}

pub struct ArrayInfo {
pub mut:
	elem_type Type
pub:
	size int
}

pub struct StructInfo {
pub mut:
	fields []Type
}

pub struct AliasInfo {
pub mut:
	parent Type
}
