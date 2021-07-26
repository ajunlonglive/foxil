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
			g.write('"$expr.lit"')
		}
		ast.Symbol {
			g.write(cname(expr.gname))
		}
		ast.ArrayLiteral {
			g.write('((${g.typ(expr.typ)}[]){')
			for i, elem in expr.elems {
				g.expr(elem)
				if i != expr.elems.len - 1 {
					g.write(', ')
				}
			}
			g.write('})')
		}
		ast.StructLiteral {
			ts := g_context.get_final_type_symbol(expr.typ)
			g.write('((${cname(ts.gname)}){')
			for i, e in expr.exprs {
				g.write('.f${i + 1} = ')
				g.expr(e)
				if i != expr.exprs.len - 1 {
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
		'br' {
			if instr.args.len == 3 {
				g.write('if (')
				g.expr(instr.args[0])
				g.write(') goto ')
				g.write((instr.args[1] as ast.Symbol).name)
				g.write('; else goto ')
				g.write((instr.args[2] as ast.Symbol).name)
			} else {
				label := (instr.args[0] as ast.Symbol).name
				g.write('goto $label')
			}
		}
		'cast' {
			ts := g_context.get_type_symbol(instr.typ)
			e := instr.args[0]
			// arrays are already pointers :)
			if (ts.kind == .array || e is ast.StringLiteral) && instr.typ.is_ptr() {
				g.expr(e)
			} else {
				g.write('((${g.typ(instr.typ)})')
				g.expr(e)
				g.write(')')
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
		'cmp' {
			arg1 := instr.args[1]
			arg2 := instr.args[2]
			g.expr(arg1)
			cond := (instr.args[0] as ast.Symbol).name
			/*
			eq: equal
            ne: not equal
            gt: greater than
            ge: greater or equal
            lt: less than
            le: less or equal
			*/
			match cond {
				'eq' {
					g.write(' == ')
				}
				'ne' {
					g.write(' != ')
				}
				'gt' {
					g.write(' > ')
				}
				'ge' {
					g.write(' >= ')
				}
				'lt' {
					g.write(' < ')
				}
				'le' {
					g.write(' <= ')
				}
				else {}
			}
			g.expr(arg2)
		}
		'getelement' {
			if instr.typ.is_ptr() {
				g.write('&')
			}
			arg1 := instr.args[1]
			g.expr(arg1)
			k := g_context.get_type_symbol(if arg1 is ast.Symbol {
				arg1.typ
			} else if arg1 is ast.StructLiteral {
				arg1.typ
			} else {
				ast.void_type
			}).kind
			match k {
				array {
					g.write('[')
					g.expr(instr.args[2])
					g.write(']')
				}
				.struct_ {
					g.write('.f')
					g.expr(instr.args[2])
				}
				else {}
			}
		}
		'load' {
			if instr.typ.is_ptr() {
				g.write('*')
			}
			g.expr(instr.args[0])
		}
		'ret' {
			g.write('return')
			if !instr.typ.is_void() {
				g.write(' ')
				g.expr(instr.args[0])
			}
		}
		'select' {
			g.write('(')
			g.expr(instr.args[0])
			g.write(') ? ')
			g.expr(instr.args[1])
			g.write(' : ')
			g.expr(instr.args[2])
		}
		'store' {
			mut req_parens := false
			if (instr.args[1] as ast.Symbol).typ.is_ptr() {
				req_parens = true
				g.write('(*')
			}
			g.expr(instr.args[1])
			if req_parens {
				g.write(')')
			}
			g.write(' = ')
			g.expr(instr.args[0])
		}
		// arithmetic operators
		'add', 'sub', 'mul', 'div', 'mod', 'lshift', 'rshift', 'and', 'or', 'xor' {
			g.expr(instr.args[0])
			match instr.name {
				'add' { g.write(' + ') }
				'sub' { g.write(' - ') }
				'mul' { g.write(' * ') }
				'div' { g.write(' / ') }
				'mod' { g.write(' % ') }
				'lshift' { g.write(' << ') }
				'rshift' { g.write(' >> ') }
				'and' { g.write(' & ') }
				'or' { g.write(' | ') }
				'xor' { g.write(' ^ ') }
				else {}
			}
			g.expr(instr.args[1])
		}
		'neg' {
			g.write('-')
			g.expr(instr.args[0])
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
		ast.char_type {
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
			g.write('NULL')
		}
		else {
			if typ.is_ptr() {
				tderef := typ.deref()
				g.write('((${g.typ(tderef)}[]){')
				g.write_default_value(tderef)
				g.write('})')
			} else {
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
				} else if ts.info is ast.StructInfo {
					g.write('(($ts.gname){')
					for i, f in ts.info.fields {
						g.write('.f${i + 1} = ')
						g.write_default_value(f)
						if i != ts.info.fields.len - 1 {
							g.write(', ')
						}
					}
					g.write('})')
				}
			}
		}
	}
}
