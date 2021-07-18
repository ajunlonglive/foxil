// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module gen

import compiler.ast

fn (mut g Gen) expr(expr ast.Expr) {
	match expr {
		ast.BoolLiteral {
			g.write(expr.lit.str())
		}
		ast.CharLiteral {
			g.write("'$expr.lit'")
		}
		ast.IntegerLiteral {
			g.write(expr.lit.str())
		}
		ast.FloatLiteral {
			g.write(expr.lit.str())
		}
		ast.StringLiteral {
			g.write('/* TODO */')
		}
		ast.Symbol {
			g.write(expr.gname)
		}
		ast.InstrExpr {
			g.instr_expr(expr)
		}
		else {
			g.write('/* TODO: $expr.type_name() */')
		}
	}
}

fn (mut g Gen) instr_expr(instr ast.InstrExpr) {
	match instr.name {
		'alloca' {
			// TODO: Auto-initialize
			if instr.args.len == 2 {
				g.write(' = ')
				g.expr(instr.args[1])
			}
		}
		'call' {
			cexpr := instr.args[0] as ast.CallExpr
			g.expr(cexpr.left)
			g.write('(')
			for i, arg in cexpr.args {
				g.expr(arg.expr)
				if i != cexpr.args.len - 1 {
					g.write(', ')
				}
			}
			g.write(')')
		}
		'ret' {
			g.write('return')
			if !instr.typ.is_void() {
				g.write(' ')
				g.expr(instr.args[0])
			}
		}
		else {
			g.write('/* TODO: implement instruction: $instr.name */')
		}
	}
}
