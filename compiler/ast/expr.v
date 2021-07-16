// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

import compiler.token

pub type Expr = ArrayLiteral | BoolLiteral | CharLiteral | EmptyExpr | FloatLiteral |
	IntegerLiteral | StringLiteral | Symbol | InstrExpr

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
	lit bool
	pos token.Position
}

pub struct CharLiteral {
pub:
	lit     string
	is_byte bool
	pos     token.Position
}

pub struct FloatLiteral {
pub:
	lit string
	pos token.Position
}

pub struct IntegerLiteral {
pub:
	lit string
	pos token.Position
}

pub struct StringLiteral {
pub:
	lit     string
	is_cstr bool
	pos     token.Position
}

pub struct InstrExpr {
pub mut:
    name string
pub:
    pos token.Position
}

pub fn (e Expr) is_lit() bool {
	return match e {
		BoolLiteral, CharLiteral, IntegerLiteral, FloatLiteral, StringLiteral { true }
		else { false }
	}
}
