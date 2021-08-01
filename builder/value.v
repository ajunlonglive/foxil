// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module builder

type Value = Constant | Ident | SingleLiteral | StructLiteral

pub fn (v Value) str() string {
	match v {
		Ident {
			p := if v.is_global { '@' } else { '%' }
			return '$v.typ $p$v.name'
		}
		Constant {
			return '$v.typ @$v.name'
		}
		SingleLiteral {
			return '$v.typ $v.lit'
		}
		StructLiteral {
			mut lstr := '{ '
			for i, l in v.lits {
				lstr += l.str()
				if i != v.lits.len - 1 {
					lstr += ', '
				}
			}
			return '$lstr }'
		}
	}
	return ''
}

pub struct Ident {
pub:
	name      string
	is_global bool
	typ       Type
}

pub struct SingleLiteral {
pub:
	lit string
	typ Type
}

pub struct StructLiteral {
pub:
	lits []Value
	typ  Type
}
