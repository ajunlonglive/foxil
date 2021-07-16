// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

import compiler.token

pub type Expr = ArrayLiteral | BoolLiteral | CallExpr | CharLiteral | EmptyExpr | FloatLiteral |
	InstrExpr | IntegerLiteral | StringLiteral | Symbol | VoidRet

pub struct EmptyExpr {
pub:
	pos token.Position
}

pub struct ArrayLiteral {
pub mut:
	size  Expr
	elems []Expr
	typ   Type
pub:
	pos token.Position
}

pub struct BoolLiteral {
pub:
	lit  bool
	etyp Type
	pos  token.Position
}

pub struct CharLiteral {
pub:
	lit     string
	is_byte bool
	etyp    Type
	pos     token.Position
}

pub struct FloatLiteral {
pub:
	lit  string
	etyp Type
	pos  token.Position
}

pub struct IntegerLiteral {
pub:
	lit  string
	etyp Type
	pos  token.Position
}

pub struct StringLiteral {
pub:
	lit     string
	is_cstr bool
	etyp    Type
	pos     token.Position
}

pub struct InstrExpr {
pub mut:
	name string
	args []Expr
	typ  Type
	pos  token.Position
}

pub struct CallExpr {
pub mut:
	left Expr
	args []CallArg
	etyp Type // `i32` in `call i32 @sum`
	typ  Type
pub:
	pos token.Position
}

pub struct CallArg {
pub mut:
	sym &Symbol
	typ Type
pub:
	pos token.Position
}

pub struct VoidRet {
pub:
	pos token.Position
}
