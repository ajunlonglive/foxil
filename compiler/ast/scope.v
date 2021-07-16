// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

[heap]
pub struct Scope {
pub mut:
	parent       &Scope = 0
	is_root      bool
	symbol_table map[string]&Symbol
	anon_symbols []&Symbol
}

// new_scope creates a new scope
[inline]
pub fn new_scope() &Scope {
	return &Scope{}
}

// new_root_scope creates a new scope with native types
pub fn new_root_scope() &Scope {
	mut s := &Scope{
		is_root: true
	}
	return s
}

// new_scope_with_parent creates a new scope with a parent
[inline]
pub fn new_scope_with_parent(parent &Scope) &Scope {
	return &Scope{
		parent: unsafe { parent }
	}
}

// add adds the specified symbol with the specified name to the symbol table
// of this scope
pub fn (mut s Scope) add(name string, sym &Symbol) {
	if name.len > 0 && name != '_' {
		if p := s.symbol_table[name] {
			mut e := report.error('redefinition of `$name`', sym.pos)
			e.note_with_pos('previous definition of `$name` here', p.pos).emit()
		} else {
			s.symbol_table[name] = unsafe { sym }
		}
	} else {
		s.anon_symbols << unsafe { sym }
	}
}

// add_module adds a object to current scope
pub fn (mut s Scope) add_obj(sy &Symbol) {
	if p := s.lookup_to_the_nearest_scope(sy.name) {
		mut e := report.error('redefinition of `$sy.name`', sy.pos)
		mut e2 := e.note_with_pos('previous definition of `$sy.name` here', p.pos)
		e2.note('if you try to change the value of the variable, use the `store` instruction').emit()
	} else {
		s.add(sy.name, sy)
	}
}

[inline]
pub fn (mut s Scope) remove(name string) {
	s.symbol_table.delete(name)
}

// lookup returns the symbol stored in the symbol table with the specified name
pub fn (s &Scope) lookup(name string) ?&Symbol {
	if sym := s.symbol_table[name] {
		return sym
	}
	return none
}

pub fn (s &Scope) lookup_to_the_nearest_scope(name string) ?&Symbol {
	for sc := s; true; sc = sc.parent {
		if sym := sc.lookup(name) {
			return sym
		}
		if isnil(sc.parent) {
			break
		}
	}
	return none
}

// is_subscope_of returns whether the specified scope is an ancestor of this scope
pub fn (s &Scope) is_subscope_of(scope &Scope) bool {
	if isnil(s) || isnil(scope) {
		return false
	}
	if scope == s {
		return true
	}
	if scope.is_root {
		return true
	}
	if !isnil(s.parent) {
		return s.parent.is_subscope_of(scope)
	}
	return false
}
