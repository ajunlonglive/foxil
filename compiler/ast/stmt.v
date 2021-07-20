// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

import compiler.token

type Stmt = AssignStmt | EmptyStmt | ExprStmt | FuncDecl

pub struct EmptyStmt {
pub:
	pos token.Position
}

pub struct FuncDecl {
pub mut:
	sym           &Symbol
	args          []&Symbol
	ret_typ       Type
	use_c_varargs bool
	is_extern     bool
	stmts         []Stmt
pub:
	pos token.Position
}

pub struct AssignStmt {
pub mut:
	left  Symbol
	right Expr
pub:
	pos token.Position
}

pub struct ExprStmt {
pub mut:
	expr Expr
pub:
	pos token.Position
}
