// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module compiler

import compiler.ast

pub fn (mut c Context) install_native_types() {
	c.register_type_symbol(name: 'void', gname: 'void', kind: .void)
	c.register_type_symbol(name: 'bool', gname: 'uint8_t', kind: .bool)
	c.register_type_symbol(name: 'char', gname: 'char', kind: .char)
	c.register_type_symbol(name: 'i8', gname: 'int8_t', kind: .i8)
	c.register_type_symbol(name: 'i16', gname: 'int16_t', kind: .i16)
	c.register_type_symbol(name: 'i32', gname: 'int32_t', kind: .i32)
	c.register_type_symbol(name: 'i64', gname: 'int64_t', kind: .i64)
	c.register_type_symbol(name: 'i8', gname: 'int8_t', kind: .u8)
	c.register_type_symbol(name: 'u16', gname: 'uint16_t', kind: .u16)
	c.register_type_symbol(name: 'u32', gname: 'uint32_t', kind: .u32)
	c.register_type_symbol(name: 'u64', gname: 'uint64_t', kind: .u64)
	c.register_type_symbol(name: 'f32', gname: 'float', kind: .f32)
	c.register_type_symbol(name: 'f64', gname: 'double', kind: .f64)
	c.register_type_symbol(name: 'rawptr', gname: 'void*', kind: .rawptr)
}

[inline]
pub fn (mut c Context) get_type_symbol(typ ast.Type) &ast.TypeSymbol {
	idx := typ.idx()
	if idx >= 0 {
		return unsafe { &c.type_symbols[idx] }
	}
	// this should never happen
	panic('Context.get_type_symbol: invalid type (typ=$typ idx=$idx). Compiler bug. This should never happen. Please report the bug.')
	return ast.invalid_type_symbol
}

[inline]
pub fn (mut c Context) get_unresolved_type(typ ast.Type) &ast.Symbol {
	idx := typ.idx()
	if idx >= 0 {
		return unsafe { &c.unresolved_types[idx] }
	}
	// this should never happen
	panic('Context.get_unresolved_type: invalid type (typ=$typ idx=$idx). Compiler bug. This should never happen. Please report the bug.')
	return 0
}

[inline]
pub fn (mut c Context) get_type_name(typ ast.Type) string {
	if typ.has_flag(.unresolved) {
		return c.get_unresolved_type(typ).gname
	}
	return c.get_type_symbol(typ).name
}

[inline]
pub fn (mut c Context) get_type_gname(typ ast.Type) string {
	if typ.has_flag(.unresolved) {
		return c.get_unresolved_type(typ).name
	}
	return c.get_type_symbol(typ).gname
}

pub fn (mut c Context) register_type_symbol(typ ast.TypeSymbol) int {
	mut existing_idx := c.type_idxs[typ.name]
	if existing_idx > 0 {
		return existing_idx
	}
	typ_idx := c.type_symbols.len
	c.type_symbols << typ
	c.type_idxs[typ.name] = typ_idx
	return typ_idx
}

pub fn (mut c Context) register_unresolved_type(typ ast.Symbol) int {
	mut existing_idx := c.unresolved_idxs[typ.gname]
	if existing_idx > 0 {
		return existing_idx
	}
	typ_idx := c.unresolved_types.len
	c.unresolved_types << typ
	c.unresolved_idxs[typ.gname] = typ_idx
	return typ_idx
}

pub fn (mut c Context) find_or_register_array(elem_type ast.Type, size int) int {
	name := c.array_name(elem_type, size)
	existing_idx := c.type_idxs[name]
	if existing_idx > 0 {
		return existing_idx
	}
	return c.register_type_symbol(ast.TypeSymbol{
		kind: .array
		name: name
		gname: c.array_cname(elem_type, size)
		info: ast.ArrayInfo{
			elem_type: elem_type
			size: size
		}
	})
}

// array_name generates the original name for the foxil source.
// e. g. [16 x [8 x i32]]
[inline]
pub fn (mut c Context) array_name(elem_type ast.Type, size int) string {
	elem_type_name := c.get_type_name(elem_type)
	ptr := if elem_type.is_ptr() { '*'.repeat(elem_type.nr_muls()) } else { '' }
	return '[$size x $elem_type_name$ptr]'
}

[inline]
pub fn (mut c Context) array_cname(elem_type ast.Type, size int) string {
	elem_type_gname := c.get_type_gname(elem_type)
	ptr := if elem_type.is_ptr() { '__ptr'.repeat(elem_type.nr_muls()) } else { '' }
	return 'Array__$elem_type_gname${ptr}__$size'
}
