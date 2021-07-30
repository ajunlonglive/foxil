// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module checker

import compiler.ast

pub struct Checker {
mut:
	cur_fn        &ast.FuncDecl = 0
	expecting_typ bool
	store_instr   bool
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
			mut has_return := false
			c.cur_fn = unsafe { &stmt }
			for mut dd_stmt in stmt.stmts {
				if !stmt.is_extern && mut dd_stmt is ast.ExprStmt {
					if dd_stmt.expr is ast.InstrExpr
						&& (dd_stmt.expr as ast.InstrExpr).name == 'ret' {
						has_return = true
					}
				}
				c.stmt(mut dd_stmt)
			}
			if !stmt.is_extern && !stmt.ret_typ.is_void() && !has_return {
				report.error('current function does not return a value', stmt.pos).emit()
			}
		}
		ast.AssignStmt {
			t := c.expr(&stmt.right)
			if t.is_void() {
				report.error('this instruction does not return a value', stmt.right.pos).emit()
			}
			stmt.left.typ = t
			mut nsym := stmt.left.scope.lookup(stmt.left.name) or {
				// we update the type of the object in the scope
				// this must never fail
				&ast.Symbol{}
			}
			nsym.typ = t
		}
		ast.GlobalAssignStmt {
			if stmt.kind == .const_ {
				t := c.expr(&stmt.expr)
				stmt.left.typ = t
				mut nsym := stmt.left.scope.lookup(stmt.left.name) or {
					// we update the type of the object in the scope
					// this must never fail
					&ast.Symbol{}
				}
				nsym.typ = t
			} else {
				ts := g_context.get_type_symbol(c.expr(&stmt.expr))
				if '@$ts.name' == stmt.left.name {
					report.error('a type alias cannot refer to itself', stmt.pos).emit()
				}
			}
		}
		ast.ExprStmt {
			c.expr(&stmt.expr)
		}
		ast.LabelStmt {
			// no checks
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
			if !expr.typ.is_char() {
				report.error('invalid character literal, expecting `char <VALUE>`', expr.pos).emit()
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
			if expr.typ != ast.str_type {
				report.error('invalid string literal, expecting `str <VALUE>`', expr.pos).emit()
			}
			return expr.typ
		}
		ast.ArrayLiteral {
			mut elem_t := ast.Type(0)
			for i, elem in expr.elems {
				t := c.expr(&elem)
				if i == 0 {
					elem_t = t
				} else {
					c.check_types(t, elem_t) or {
						report.error('$err.msg, in array literal', elem.pos).emit()
					}
				}
			}
			t := ast.Type(g_context.find_or_register_array(elem_t, expr.size))
			expr.typ = elem_t
			return t
		}
		ast.StructLiteral {
			t := c.typ(expr.typ)
			mut ts := g_context.get_final_type_symbol(t)
			if ts.kind != .struct_ {
				report.error('$ts.name is not a type', expr.pos).emit()
			} else {
				mut ts_fields := &(ts.info as ast.StructInfo).fields
				tsfl := ts_fields.len
				msg := '$tsfl expression(s) are expected, not $expr.exprs.len'
				if tsfl < expr.exprs.len {
					report.error('too few expressions to type ‘$ts.name’ ($msg)',
						expr.pos).emit()
				} else if tsfl > expr.exprs.len {
					report.error('too many expressions to type ‘$ts.name’ ($msg)',
						expr.pos).emit()
				} else {
					for i, e in expr.exprs {
						et := c.expr(&e)
						mut ef := unsafe { &ts_fields[i] }
						at := unsafe { c.typ(ef) }
						c.check_types(at, et) or {
							report.error('$err.msg, in field ${i + 1}', e.pos).emit()
						}
						ef = at
					}
				}
			}
			expr.typ = t
			return t
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
				}
			}
			if c.store_instr && expr.kind == .constant {
				report.error('`$expr.name` is constant, its value cannot change', expr.pos).emit()
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
			if args_count < fn_args_count {
				report.error('too few arguments to function ‘$ce_fn’ ($msg)', ce.pos).emit()
			} else if args_count > fn_args_count && !fn_node.use_c_varargs {
				report.error('too many arguments to function ‘$ce_fn’ ($msg)', ce.pos).emit()
			} else {
				for i, mut arg in ce.args {
					arg_typ := c.expr(&arg.expr)
					if i < fn_args_count {
						name := fn_node.args[i].name
						fn_arg_typ := c.typ(fn_node.args[i].typ)
						fn_node.args[i].typ = fn_arg_typ
						c.check_types(arg_typ, fn_arg_typ) or {
							n := if fn_node.is_extern { i.str() } else { '`$name`' }
							k := if fn_node.is_extern { 'extern ' } else { '' }

							report.error('$err.msg, in argument $n of ${k}function `$ce_fn.name`',
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
			instr.typ = c.typ((instr.args[0] as ast.TypeNode).typ)
			if instr.args.len > 1 {
				if instr.args[1] is ast.Symbol {
					report.error('`alloca` cannot assign values ​​from other symbols, use the `load` instruction instead',
						instr.args[1].pos).emit()
				} else {
					expr_t := c.expr(&instr.args[1])
					c.check_types(expr_t, instr.typ) or {
						report.error('$err.msg, in initial value of `alloca` instruction',
							instr.args[1].pos).emit()
					}
				}
			}
			return instr.typ
		}
		'br' {
			if instr.args.len == 3 {
				t := c.expr(&instr.args[0])
				if !t.is_bool() {
					report.error('boolean literal expected', instr.args[0].pos).emit()
				}
				tlabel := (instr.args[1] as ast.Symbol)
				if tlabel.name !in c.cur_fn.labels {
					report.error('label `$tlabel.name` not found', tlabel.pos).emit()
				}
				flabel := (instr.args[2] as ast.Symbol)
				if flabel.name !in c.cur_fn.labels {
					report.error('label `$flabel.name` not found', flabel.pos).emit()
				}
			} else {
				label := (instr.args[0] as ast.Symbol)
				if label.name !in c.cur_fn.labels {
					report.error('label `$label.name` not found', label.pos).emit()
				}
			}
		}
		'cast' {
			from_t := c.expr(&instr.args[0])
			from_ts := g_context.get_type_symbol(from_t)
			to_t := c.typ((instr.args[1] as ast.TypeNode).typ)
			if (from_t.is_number() && to_t.is_number())
				|| (from_t.is_bool() && to_t.is_number())
				|| (from_t.is_char() && to_t.is_number())
				|| (from_t.is_number() && to_t.is_char())
				|| (from_t.is_rawptr() && to_t.is_ptr())
				|| (from_t.is_ptr() && to_t.is_rawptr())
				|| (from_ts.info is ast.ArrayInfo
				&& (from_ts.info as ast.ArrayInfo).elem_type.is_char() && to_t.is_str()) {
				instr.typ = to_t
				return to_t
			} else {
				report.error('cannot cast `${ast.typ2str(from_t)}` to `${ast.typ2str(to_t)}`',
					instr.pos).emit()
			}
			return from_t
		}
		'call' {
			instr.typ = c.expr(&instr.args[0])
			return instr.typ
		}
		'cmp' {
			op1 := c.expr(&instr.args[1])
			op2 := c.expr(&instr.args[2])
			c.check_types(op2, op1) or {
				report.error('$err.msg, in the second comparison operand', instr.pos).emit()
			}
			instr.typ = ast.bool_type
			return instr.typ
		}
		'getelement' {
			is_ref := (instr.args[0] as ast.BoolLiteral).lit
			t := c.expr(&instr.args[1])
			ts := g_context.get_type_symbol(t)
			idx := &instr.args[2]
			if !c.expr(idx).is_number() {
				report.error('expected an numeric index', instr.args[2].pos).emit()
			} else {
				match true {
					t.is_str() {
						instr.typ = ast.char_type
					}
					t.is_ptr() {
						instr.typ = t.deref()
					}
					else {
						mut i := 0
						match mut ts.info {
							ast.ArrayInfo {
								if !g_context.no_safe_checks && mut idx is ast.IntegerLiteral {
									i = idx.lit.int()
									if i < 0 || i > ts.info.size {
										report.error('index out of range (idx: $i, len: $ts.info.size)',
											instr.pos).emit()
									}
								}
								instr.typ = ts.info.elem_type
							}
							ast.StructInfo {
								if mut idx is ast.IntegerLiteral {
									i = idx.lit.int()
									if !g_context.no_safe_checks
										&& (i < 1 || i > ts.info.fields.len) {
										report.error('index out of range (idx: $i, with $ts.info.fields.len field(s))',
											instr.pos).emit()
									}
									instr.typ = ts.info.fields[if i == 1 { 0 } else { i - 1 }] or {
										ast.void_type
									}
								} else {
									report.error('expected an integer literal', idx.pos).emit()
								}
							}
							else {
								report.error('expected an array or a struct', instr.args[1].pos).emit()
							}
						}
					}
				}
			}
			nt := if is_ref { instr.typ.to_ptr() } else { instr.typ }
			instr.typ = nt
			return nt
		}
		'load' {
			t := c.expr(&instr.args[0])
			if instr.args[0] !is ast.Symbol {
				report.error('`load` only works with symbols', instr.args[0].pos).emit()
			}
			instr.typ = t
			return if t.is_ptr() { t.deref() } else { t }
		}
		'ret' {
			instr.typ = c.expr(&instr.args[0])
			c.check_types(instr.typ, c.cur_fn.ret_typ) or {
				report.error('$err.msg, in return argument', instr.args[0].pos).emit()
			}
		}
		'select' {
			t := c.expr(&instr.args[0])
			if t.is_bool() {
				instr.typ = c.expr(&instr.args[1])
				t2 := c.expr(&instr.args[2])
				c.check_types(instr.typ, t2) or { report.error(err.msg, instr.args[2].pos).emit() }
				return instr.typ
			} else {
				report.error('expected a boolean literal', instr.args[0].pos).emit()
			}
		}
		'store' {
			if instr.args[1] !is ast.Symbol {
				report.error('`store` only works with symbols', instr.args[1].pos).emit()
			} else {
				val := c.expr(&instr.args[0])
				c.store_instr = true
				dest := c.expr(&instr.args[1])
				c.store_instr = false
				c.check_types(val, dest) or { report.error(err.msg, instr.args[0].pos).emit() }
			}
		}
		// arithmetic operators
		'add', 'sub', 'mul', 'div', 'mod', 'lshift', 'rshift', 'and', 'or', 'xor' {
			t1 := c.expr(&instr.args[0])
			t2 := c.expr(&instr.args[1])
			if t1.is_number() {
				c.check_types(t2, t1) or {
					report.error('$err.msg, in the second operand of the `$instr.name` instruction',
						instr.pos).emit()
				}
			} else {
				report.error('expected a numeric expression', instr.args[0].pos).emit()
			}
			instr.typ = t1
			return t1
		}
		'neg' {
			t := c.expr(&instr.args[0])
			if !t.is_number() {
				report.error('expected a numeric expression', instr.args[0].pos).emit()
			}
			instr.typ = t
			return t
		}
		else {
			report.error('checker: unsupported instruction: `$instr.name`', instr.pos).emit()
		}
	}
	return ast.void_type
}

fn (mut c Checker) typ(typ ast.Type) ast.Type {
	if !typ.has_flag(.unresolved) {
		mut ts := g_context.get_type_symbol(typ)
		if mut ts.info is ast.ArrayInfo {
			ts.info.elem_type = c.typ(ts.info.elem_type)
		} else if mut ts.info is ast.StructInfo {
			c.check_struct(mut ts)
		}
		return typ
	}
	c.expecting_typ = true
	t := c.expr(g_context.unresolved_types[typ.idx()]).derive(typ).clear_flag(.unresolved)
	c.expecting_typ = false
	mut ts := g_context.get_type_symbol(t)
	c.check_struct(mut ts)
	return t
}

fn (mut c Checker) check_struct(mut ts ast.TypeSymbol) {
	if mut ts.info is ast.StructInfo {
		for mut f in ts.info.fields {
			f = c.typ(f)
		}
	}
}

fn (mut c Checker) check_types(got ast.Type, expected ast.Type) ? {
	if !c.are_compatible_types(got, expected) {
		return error('expecting `${ast.typ2str(expected)}`, not `${ast.typ2str(got)}`')
	}
}

fn (mut c Checker) are_compatible_types(got ast.Type, expected ast.Type) bool {
	if expected.idx() == got.idx() {
		if (expected.is_ptr() && got.is_ptr()) && (expected.nr_muls() != got.nr_muls()) {
			return false
		}
		return true
	}
	if (expected.is_rawptr() && got.is_number())
		|| (expected.is_rawptr() && got.is_ptr())
		|| (expected.is_ptr() && got.is_rawptr())
		|| (expected.is_number() && got.is_ptr()) {
		return true
	}
	charptr_t := ast.char_type.to_ptr()
	if (expected == charptr_t && got.is_str()) || (got == charptr_t && expected.is_str()) {
		return true
	}
	return false
}
