// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

pub fn (e Expr) str() string {
	match e {
		BoolLiteral {
			return e.lit.str()
		}
		FloatLiteral, IntegerLiteral {
			return e.lit.str()
		}
		CharLiteral {
			prefix := if e.is_byte { 'b' } else { '' }
			return "$prefix'$e.lit.str()'"
		}
		StringLiteral {
			return '"$e.lit.str()"'
		}
		ArrayLiteral {
			mut arr := '['
			if e.elems.len > 0 {
				arr += ' '
			}
			for i, elem in e.elems {
				arr += elem.str()
				if i != e.elems.len - 1 {
					arr += ', '
				}
			}
			return '$arr]'
		}
		Symbol {
			return e.str()
		}
		InstrExpr {
			return '$e.name'
		}
		CallExpr {
			return '$e.typ ${e.left}()'
		}
		VoidRet {
			return 'void'
		}
		EmptyExpr {
			return '<empty-expr>'
		}
	}
}

pub fn (e Expr) is_lit() bool {
	return match e {
		BoolLiteral, CharLiteral, IntegerLiteral, FloatLiteral, StringLiteral { true }
		else { false }
	}
}
