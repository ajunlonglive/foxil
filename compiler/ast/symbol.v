// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

import compiler.token

pub enum SymbolKind {
	native // native types/functions/etc...
	variable
	constant
	function
}

pub struct Symbol {
pub mut:
	name       string
	gname      string
	node       Stmt
	unresolved bool
	kind       SymbolKind
	is_local   bool
	from_lit   bool
	typ        Type
	scope      &Scope = 0
pub:
	pos token.Position
}

pub fn (sym Symbol) str() string {
	return sym.name
}
