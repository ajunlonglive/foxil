// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

import compiler.token

type Stmt = AssignStmt | DeclStmt | DefDecl | EmptyStmt | ExprStmt

pub struct EmptyStmt {
pub:
	pos token.Position
}

pub struct DefDecl {
pub mut:
	sym     &Symbol
	args    []&Symbol
	ret_typ Type
	stmts   []Stmt
pub:
	pos token.Position
}

pub struct DeclStmt {
pub mut:
	sym           &Symbol
	use_c_varargs bool
	args          []&Symbol
	ret_typ       Type
pub:
	pos token.Position
}

pub struct AssignStmt {
pub mut:
	left  Expr
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
