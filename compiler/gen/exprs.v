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
		ast.ArrayLiteral {
			g.write('((${g.typ(expr.typ)}){')
			for i, elem in expr.elems {
				g.expr(elem)
				if i != expr.elems.len - 1 {
					g.write(', ')
				}
			}
			g.write('})')
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
			if instr.args.len == 2 {
				g.expr(instr.args[1])
			} else {
				// we write a default value
				g.write_default_value(instr.typ)
			}
		}
		'cast' {
			g.write('((${g.typ(instr.typ)})')
			g.expr(instr.args[0])
			g.write(')')
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

fn (mut g Gen) write_default_value(typ ast.Type) {
	match typ {
		ast.void_type {
			// this should never happen
			g.write('/*void*/')
		}
		ast.bool_type {
			g.write('false')
		}
		ast.char_type, ast.uchar_type {
			g.write(r"'\0'")
		}
		ast.i8_type, ast.i16_type, ast.i32_type, ast.i64_type, ast.u8_type, ast.u16_type,
		ast.u32_type, ast.u64_type {
			g.write('0')
		}
		ast.f32_type, ast.f64_type {
			g.write('0.0')
		}
		ast.rawptr_type {
			// TODO: this should not be NULL (in the future, we should
			// create pointers to values ​​by default)
			g.write('NULL')
		}
		else {
			ts := g_context.get_type_symbol(typ)
			if ts.info is ast.ArrayInfo {
				g.write('((${g.typ(ts.info.elem_type)}[$ts.info.size]){')
				for i in 0 .. ts.info.size {
					g.write_default_value(ts.info.elem_type)
					if i != ts.info.size - 1 {
						g.write(', ')
					}
				}
				g.write('})')
			}
			// TODO: here go the structs
		}
	}
}
