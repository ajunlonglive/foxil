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
		'br' {
			if p.peek_token(3).kind == .comma {
				// br <COND>, <TRUE-LABEL>, <FALSE-LABEL>
				instr.args << p.parse_literal()
				p.check(.comma)
				ltpos := p.tok.position()
				ltlabel := p.parse_identifier()
				instr.args << ast.Symbol{
					name: ltlabel
					pos: ltpos
				}
				p.check(.comma)
				lfpos := p.tok.position()
				lflabel := p.parse_identifier()
				instr.args << ast.Symbol{
					name: lflabel
					pos: lfpos
				}
			} else {
				// br <LABEL>
				lpos := p.tok.position()
				label := p.parse_identifier()
				instr.args << ast.Symbol{
					name: label
					pos: lpos
				}
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
		'cmp' {
			cond_pos := p.tok.position()
			cond := p.parse_identifier()
			if cond !in ['eq', 'ne', 'gt', 'ge', 'lt', 'le'] {
				report.error('invalid condition: `$cond`', cond_pos).emit()
			}
			instr.args << ast.Symbol{
				name: cond
			}
			instr.args << p.parse_literal()
			p.check(.comma)
			instr.args << p.parse_literal()
		}
		'getelement' {
			// getelement [ref] <ARRAY|STRUCT>, <INDEX>
			mut is_ref := false
			if p.tok.lit == 'ref' {
				is_ref = true
				p.next()
			}
			instr.args << ast.BoolLiteral{
				lit: is_ref
			}
			instr.args << p.parse_literal()
			p.check(.comma)
			instr.args << p.parse_literal()
		}
		'load', 'ret' {
			instr.args << p.parse_literal()
		}
		'select' {
			// select <bool>, <val1>, <val2>
			instr.args << p.parse_literal()
			p.check(.comma)
			instr.args << p.parse_literal()
			p.check(.comma)
			instr.args << p.parse_literal()
		}
		'store' {
			instr.args << p.parse_literal()
			p.check(.comma)
			instr.args << p.parse_literal()
		}
		// arithmetic operators
		'add', 'sub', 'mul', 'div', 'mod', 'lshift', 'rshift', 'and', 'or', 'xor' {
			instr.args << p.parse_literal()
			p.check(.comma)
			instr.args << p.parse_literal()
		}
		'neg' {
			instr.args << p.parse_literal()
		}
		else {
			report.error('unknown instruction: `$name`', pos).emit()
		}
	}
	instr.pos = pos.extend(p.prev_tok.position())
	return instr
}
