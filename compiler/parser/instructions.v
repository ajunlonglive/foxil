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
		'alloca' {
			instr.args << ast.TypeNode{
				typ: p.parse_type()
				pos: pos
			}
			// value?
			if p.accept(.comma) {
				instr.args << p.parse_literal()
			}
		}
		'cast' {
			instr.args << p.parse_literal()
			p.check(.key_as)
			pos2 := p.tok.position()
			instr.args << ast.TypeNode{
				typ: p.parse_type()
				pos: pos2
			}
		}
		'call' {
			typ := p.parse_type()
			sym := p.parse_symbol()
			mut args := []ast.CallArg{}
			p.check(.lparen)
			if p.tok.kind != .rparen {
				for {
					mut apos := p.tok.position()
					expr := p.parse_literal()
					apos = apos.extend(p.prev_tok.position())
					args << ast.CallArg{
						expr: expr
						pos: apos
					}
					if !p.accept(.comma) {
						break
					}
				}
			}
			pos = pos.extend(p.tok.position())
			p.check(.rparen)
			instr.args << ast.CallExpr{
				left: sym
				args: args
				typ: typ
				pos: pos
			}
		}
		'ret' {
			instr.args << p.parse_literal()
		}
		else {
			report.error('unknown instruction: `$name`', pos).emit()
		}
	}
	instr.pos = pos.extend(p.prev_tok.position())
	return instr
}
