// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module checker

import compiler.ast

pub struct Checker {
mut:
	expecting_typ bool
}

pub fn run_checker() {
	mut c := Checker{}
	for mut sf in g_context.source_files {
		c.check_file(mut sf)
	}
}

fn (mut c Checker) check_file(mut sf ast.SourceFile) {
	for mut stmt in sf.nodes {
		c.stmt(mut stmt)
	}
}

fn (mut c Checker) stmt(mut stmt ast.Stmt) {
	match mut stmt {
		ast.DeclStmt {
			stmt.ret_typ = c.typ(stmt.ret_typ)
		}
		ast.DefDecl {
			stmt.ret_typ = c.typ(stmt.ret_typ)
			for mut dd_stmt in stmt.stmts {
				c.stmt(mut dd_stmt)
			}
		}
		ast.ExprStmt {
			c.expr(&stmt.expr)
		}
		else {
			report.error('checker: unsupported statement: `$stmt.type_name()`', stmt.pos).emit()
		}
	}
}

fn (mut c Checker) expr(expr &ast.Expr) ast.Type {
	match mut expr {
		ast.BoolLiteral {
			return expr.typ
		}
		ast.CharLiteral {
			return expr.typ
		}
		ast.IntegerLiteral {
			return expr.typ
		}
		ast.FloatLiteral {
			return expr.typ
		}
		ast.StringLiteral {
			return expr.typ
		}
		ast.VoidRet {
			return ast.void_type
		}
		ast.Symbol {
			if expr.unresolved {
				sc := if expr.is_local { expr.scope } else { &g_context.root }
				if c.expecting_typ {
					if expr.name !in g_context.type_idxs {
						report.error('type `$expr.name` not found', expr.pos).emit()
					}
					return ast.Type(g_context.type_idxs[expr.name])
				} else {
					mut nsym := sc.lookup(expr.name) or {
						report.error('symbol `$expr.name` not found', expr.pos).emit()
						return ast.void_type
					}
					if nsym.typ.has_flag(.unresolved) {
						nsym.typ = c.typ(nsym.typ)
					}
					expr.typ = nsym.typ
				}
			}
			return expr.typ
		}
		ast.TypeNode {
			expr.typ = c.typ(expr.typ)
			return expr.typ
		}
		ast.CallExpr {
			return c.call_expr(mut expr)
		}
		ast.InstrExpr {
			return c.instr_expr(mut expr)
		}
		ast.EmptyExpr {
			report.error('checker: empty expression', expr.pos).emit()
			return ast.void_type
		}
		else {
			report.error('checker: unsupported expression: `$expr.type_name()`', expr.pos).emit()
			return ast.void_type
		}
	}
}

fn (mut c Checker) call_expr(mut ce ast.CallExpr) ast.Type {
	typ := c.typ(ce.typ)
	c.expr(&ce.left)
	return typ
}

fn (mut c Checker) instr_expr(mut instr ast.InstrExpr) ast.Type {
	match instr.name {
		'alloca' {
			instr.typ = c.typ(&(instr.args[0] as ast.TypeNode).typ)
			if instr.args.len > 1 {
				instr.typ = c.expr(&instr.args[1])
			}
			return instr.typ
		}
		'call' {
			instr.typ = c.expr(&instr.args[0])
			return instr.typ
		}
		'ret' {
			instr.typ = c.expr(&instr.args[0])
			return instr.typ
		}
		else {
			report.error('checker: unsupported instruction: `$instr.name`', instr.pos).emit()
		}
	}
	return ast.void_type
}

fn (mut c Checker) typ(typ ast.Type) ast.Type {
	if !typ.has_flag(.unresolved) {
		return typ
	}
	c.expecting_typ = true
	t := c.expr(g_context.unresolved_types[typ.idx()]).derive(typ).clear_flag(.unresolved)
	c.expecting_typ = false
	return t
}
