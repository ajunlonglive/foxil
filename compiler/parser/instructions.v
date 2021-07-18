// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module parser

import compiler
import compiler.ast

fn (mut p Parser) parse_instruction() ast.Expr {
	mut pos := p.tok.position()
	name := p.tok.lit
	p.check(.name)
	mut instr := ast.InstrExpr{
		name: name
	}
	match name {
		'call' {
			mut cpos := p.tok.position()
			typ := p.parse_type()
			sym := p.parse_symbol()
			mut args := []ast.CallArg{}
			p.check(.lparen)
			if p.tok.kind != .rparen {
				for {
					mut apos := p.tok.position()
					atyp := p.parse_type()
					asym := p.parse_symbol()
					apos = apos.extend(p.tok.position())
					args << ast.CallArg{
						typ: atyp
						sym: asym
						pos: pos
					}
					if !p.accept(.comma) {
						break
					}
				}
			}
			cpos = cpos.extend(p.tok.position())
			p.check(.rparen)
			instr.args << ast.CallExpr{
				left: sym
				args: args
				typ: typ
				pos: cpos
			}
		}
		'ret' {
			instr.args << p.parse_literal()
		}
		else {
			report.error('unknown instruction: `$name`', pos).emit()
		}
	}
	instr.pos = pos.extend(p.tok.position())
	return instr
}
