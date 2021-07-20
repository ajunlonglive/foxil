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
		ast.FuncDecl {
			for mut arg in stmt.args {
				arg.typ = c.typ(arg.typ)
			}
			stmt.ret_typ = c.typ(stmt.ret_typ)
			for mut dd_stmt in stmt.stmts {
				c.stmt(mut dd_stmt)
			}
		}
		ast.AssignStmt {
			t := c.expr(&stmt.right)
			if stmt.right is ast.InstrExpr && (stmt.right as ast.InstrExpr).name == 'ret' {
				report.error('instruction `ret` cannot be used as an expression', stmt.pos).emit()
			}
			stmt.left.typ = t
			mut nsym := stmt.left.scope.lookup(stmt.left.name) or {
				// we update the type of the object in the scope
				// this must never fail
				&ast.Symbol{}
			}
			nsym.typ = t
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
			if !expr.typ.is_bool() {
				report.error('invalid bool literal, expecting `bool <VALUE>`', expr.pos).emit()
			}
			return expr.typ
		}
		ast.CharLiteral {
			if expr.typ !in [ast.char_type, ast.uchar_type] {
				report.error('invalid character literal, expecting `<char|uchar> <VALUE>`',
					expr.pos).emit()
			}
			return expr.typ
		}
		ast.IntegerLiteral {
			if !expr.typ.is_number() {
				report.error('invalid integer literal, expecting `<(i|u)(8|16|32|64)> <VALUE>`',
					expr.pos).emit()
			}
			return expr.typ
		}
		ast.FloatLiteral {
			if !expr.typ.is_float() {
				report.error('invalid float literal, expecting `<f(32|64)> <VALUE>`',
					expr.pos).emit()
			}
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
					} else {
						expr.unresolved = false
						return ast.Type(g_context.type_idxs[expr.name])
					}
				} else {
					mut nsym := sc.lookup(expr.name) or {
						report.error('symbol `$expr.name` not found', expr.pos).emit()
						return ast.void_type
					}
					if nsym.typ.has_flag(.unresolved) {
						nsym.typ = c.typ(nsym.typ)
					}
					if expr.from_lit && c.typ(expr.typ) != nsym.typ {
						report.error('symbol `$expr.name` is of type `${ast.typ2str(nsym.typ)}`, not of type `${ast.typ2str(expr.typ)}`',
							expr.pos).emit()
					}
					// update expr with nsym :)
					expr.is_local = nsym.is_local
					expr.node = nsym.node
					expr.kind = nsym.kind
					expr.typ = nsym.typ
					expr.unresolved = false
					return nsym.typ
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
	ftyp := c.expr(&ce.left)
	if typ != ftyp {
		report.error('function `$ce.left` returns `${ast.typ2str(ftyp)}`, not `${ast.typ2str(typ)}`',
			ce.pos).emit()
	} else if ce.left is ast.Symbol {
		ce_fn := ce.left as ast.Symbol
		if ce_fn.kind != .function {
			report.error('symbol `$ce_fn` is not a function, is a $ce_fn.kind', ce.pos).emit()
		} else {
			mut fn_node := ce_fn.node as ast.FuncDecl
			args_count := ce.args.len
			fn_args_count := fn_node.args.len
			msg := '$fn_args_count argument(s) are expected, not $args_count'
			// TODO: allow variadic arguments
			if args_count < fn_args_count {
				report.error('too few arguments to function ‘$ce_fn’, ($msg)', ce.pos).emit()
			} else if args_count > fn_args_count {
				report.error('too many arguments to function ‘$ce_fn’ ($msg)', ce.pos).emit()
			} else {
				for i, mut arg in ce.args {
					arg_typ := c.expr(&arg.expr)
					if i < fn_args_count {
						name := fn_node.args[i].name
						fn_arg_typ := c.typ(fn_node.args[i].typ)
						fn_node.args[i].typ = fn_arg_typ
						c.check_types(arg_typ, fn_arg_typ) or {
							report.error('$err.msg, in argument `$name` of function `$ce_fn.name`',
								arg.pos).emit()
						}
					}
				}
			}
		}
	}
	return typ
}

fn (mut c Checker) instr_expr(mut instr ast.InstrExpr) ast.Type {
	match instr.name {
		'alloca' {
			instr.typ = c.typ(&(instr.args[0] as ast.TypeNode).typ)
			if instr.args.len > 1 {
				expr_t := c.expr(&instr.args[1])
				c.check_types(expr_t, instr.typ) or {
					report.error('$err.msg, in initial value of `alloca` instruction',
						instr.args[1].pos).emit()
				}
				instr.typ = expr_t
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

fn (mut c Checker) check_types(got ast.Type, expected ast.Type) ? {
	if !c.are_compatible_types(got, expected) {
		return error('expecting ${ast.typ2str(expected)}, not ${ast.typ2str(got)}')
	}
}

fn (mut c Checker) are_compatible_types(got ast.Type, expected ast.Type) bool {
	if expected.idx() == got.idx() {
		if (expected.is_ptr() && got.is_ptr()) && (expected.nr_muls() != got.nr_muls()) {
			return false
		}
		return true
	}
	if (expected.is_rawptr() || got.is_ptr()) && (expected.is_ptr() || got.is_rawptr()) {
		return true
	}
	return false
}
