// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module parser

import compiler
import compiler.ast
import compiler.util
import compiler.token

pub struct Parser {
mut:
	sf       &ast.SourceFile = 0
	scanner  Scanner
	prev_tok token.Token
	tok      token.Token
	peek_tok token.Token
	scope    &ast.Scope
	labels   []string
}

pub fn run_parser() {
	mut p := Parser{
		scope: &g_context.root
	}
	for mut sf in g_context.source_files {
		p.parse_file(sf)
	}
}

pub fn (mut p Parser) parse_file(sf &ast.SourceFile) {
	p.scanner = new_scanner(sf)
	p.sf = unsafe { sf }
	for _ in 0 .. 2 {
		p.next()
	}
	p.sf.nodes = p.parse_declarations()
}

fn (mut p Parser) open_scope() {
	p.scope = ast.new_scope_with_parent(p.scope)
}

fn (mut p Parser) close_scope() {
	p.scope = p.scope.parent
}

fn (mut p Parser) next() {
	p.prev_tok = p.tok
	p.tok = p.peek_tok
	p.peek_tok = p.scanner.scan()
}

[inline]
fn (mut p Parser) accept(k token.Kind) bool {
	return if _likely_(p.tok.kind == k) {
		p.next()
		true
	} else {
		false
	}
}

fn (mut p Parser) check(k token.Kind) {
	if p.accept(k) {
		return
	}
	mut kstr := k.str()
	if token.is_key(kstr) || (kstr.len > 0 && !kstr[0].is_letter()) {
		kstr = '`$kstr`'
	}
	report.error('expecting $kstr, not $p.tok', p.tok.position()).emit_and_exit()
}

[inline]
fn (p &Parser) empty_stmt() ast.Stmt {
	return ast.EmptyStmt{p.tok.position()}
}

[inline]
fn (p &Parser) empty_expr() ast.Expr {
	return ast.EmptyExpr{p.tok.position()}
}

[inline]
pub fn (p &Parser) peek_token(n int) token.Token {
	return p.scanner.peek_token(n - 2)
}

fn (mut p Parser) parse_identifier() string {
	lit := p.tok.lit
	if p.tok.kind == .name || token.is_key(p.tok.lit) {
		p.next()
	} else {
		p.check(.name)
	}
	return lit
}

fn (mut p Parser) parse_symbol() &ast.Symbol {
	mut pos := p.tok.position()
	mut is_local := false
	prefix := p.tok.kind.str()
	match p.tok.kind {
		.at {
			p.next()
		}
		.mod {
			if p.scope.is_root {
				report.error('local scope prefix (`%`) cannot be used in global scope',
					pos).emit()
			}
			p.next()
			is_local = true
		}
		else {
			report.error('identifiers should start with a prefix (`@` for globals, `%` for locals)',
				pos).emit()
		}
	}
	pos = pos.extend(p.tok.position())
	name := p.parse_identifier()
	return &ast.Symbol{
		name: '$prefix$name'
		gname: util.convert_to_valid_c_ident(name)
		pos: pos
		unresolved: true
		is_local: is_local
		scope: p.scope
	}
}

fn (mut p Parser) parse_symbol_with_kind(k ast.SymbolKind) &ast.Symbol {
	mut sym := p.parse_symbol()
	sym.kind = k
	return sym
}

fn (mut p Parser) parse_literal() ast.Expr {
	mut pos := p.tok.position()
	typ := p.parse_type()
	if typ.is_void() {
		return ast.VoidRet{pos}
	}
	match p.tok.kind {
		.key_true, .key_false {
			kind := p.tok.kind
			pos = pos.extend(p.tok.position())
			p.check(p.tok.kind)
			return ast.BoolLiteral{
				lit: kind == .key_true
				pos: pos
				typ: typ
			}
		}
		.char {
			lit := p.tok.lit
			pos = pos.extend(p.tok.position())
			p.check(.char)
			return ast.CharLiteral{
				lit: lit
				pos: pos
				typ: typ
			}
		}
		.string {
			lit := p.tok.lit
			pos = pos.extend(p.tok.position())
			p.check(.string)
			return ast.StringLiteral{
				lit: lit
				pos: pos
				typ: typ
			}
		}
		.minus, .number {
			is_neg := p.accept(.minus)
			if is_neg {
				pos = pos.extend(p.tok.position())
			}
			lit := p.tok.lit
			full_lit := if is_neg { '-' + lit } else { lit }
			pos = pos.extend(p.tok.position())
			node := if lit.index_any('.eE') >= 0 && lit[..2].to_lower() !in ['0x', '0o', '0b'] { ast.Expr(ast.FloatLiteral{
					lit: full_lit
					pos: pos
					typ: typ
				}) } else { ast.Expr(ast.IntegerLiteral{
					lit: full_lit
					pos: pos
					typ: typ
				}) }
			p.next()
			return node
		}
		.at, .mod {
			mut sym := p.parse_symbol()
			sym.typ = typ
			sym.from_lit = true
			sym.pos = pos.extend(p.prev_tok.position())
			return ast.Expr(sym)
		}
		.lbracket {
			mut elems := []ast.Expr{}
			p.next()
			if p.tok.kind != .rbracket {
				for {
					elems << p.parse_literal()
					if !p.accept(.comma) {
						break
					}
				}
			}
			pos = pos.extend(p.tok.position())
			p.check(.rbracket)
			return ast.ArrayLiteral{
				elems: elems
				size: elems.len
				typ: typ
				pos: pos
			}
		}
		.lbrace {
			p.next()
			mut exprs := []ast.Expr{}
			if p.tok.kind != .rbrace {
				for {
					exprs << p.parse_literal()
					if !p.accept(.comma) {
						break
					}
				}
			}
			pos = pos.extend(p.tok.position())
			p.check(.rbrace)
			return ast.StructLiteral{
				exprs: exprs
				typ: typ
				pos: pos
			}
		}
		else {}
	}
	return p.empty_expr()
}

fn (mut p Parser) parse_type() ast.Type {
	mut pos := p.tok.position()
	if p.accept(.lbracket) {
		size := p.tok.lit.int()
		p.check(.number)
		if !(p.tok.kind == .name && p.tok.lit == 'x') {
			report.error('bad syntax, it should be `[<size> x <Type>]`', p.tok.position()).emit()
		}
		p.check(.name)
		elem_typ := p.parse_type()
		pos = pos.extend(p.tok.position())
		if elem_typ.is_void() {
			report.error('cannot make arrays of type `void`', pos).emit()
		} else if size <= 0 {
			report.error('arrays of size <= 0 are invalid', pos).emit()
		}
		p.check(.rbracket)
		mut nr_muls := 0
		for p.accept(.mult) {
			nr_muls++
		}
		if nr_muls > 0 {
			report.error('cannot make pointers to arrays, they are already pointers themselves',
				pos).emit()
		}
		return ast.Type(g_context.find_or_register_array(elem_typ, size))
	} else if p.accept(.lbrace) {
		// anonymous struct: { i32, bool }
		mut fields := []ast.Type{}
		if p.tok.kind != .rbrace {
			for {
				fields << p.parse_type()
				if !p.accept(.comma) {
					break
				}
			}
		}
		p.check(.rbrace)
		return ast.Type(g_context.find_or_register_struct_type(ast.StructInfo{fields}))
	}
	prefix := p.tok.kind
	has_prefix := prefix in [.at, .mod]
	if has_prefix {
		p.next()
	}
	name_pos := p.tok.position()
	name := p.parse_identifier()
	is_native := name in ast.native_type_names
	if has_prefix && is_native {
		report.error("native types don't require a global scope prefix (`@`)", pos.extend(name_pos)).emit()
	} else if !has_prefix && !is_native {
		report.error('non-native types require the global scope prefix (`@`)', name_pos).emit()
	}
	mut typ := match name {
		'void' {
			ast.void_type
		}
		'bool' {
			ast.bool_type
		}
		'char' {
			ast.char_type
		}
		'str' {
			ast.str_type
		}
		'i8' {
			ast.i8_type
		}
		'i16' {
			ast.i16_type
		}
		'i32' {
			ast.i32_type
		}
		'i64' {
			ast.i64_type
		}
		'u8' {
			ast.u8_type
		}
		'u16' {
			ast.u16_type
		}
		'u32' {
			ast.u32_type
		}
		'u64' {
			ast.u64_type
		}
		'f32' {
			ast.f32_type
		}
		'f64' {
			ast.f64_type
		}
		'rawptr' {
			ast.rawptr_type
		}
		else {
			ast.Type(g_context.register_unresolved_type(ast.Symbol{
				name: name
				gname: util.convert_to_valid_c_ident(name)
				unresolved: true
				pos: pos.extend(p.prev_tok.position())
			})).set_flag(.unresolved)
		}
	}
	mut nr_muls := 0
	for p.accept(.mult) {
		nr_muls++
	}
	if typ.is_void() && nr_muls > 0 {
		report.error('cannot make pointers to the type `void`, use `rawptr` instead',
			pos).emit()
	}
	return typ.set_nr_muls(nr_muls)
}

fn (mut p Parser) parse_declarations() []ast.Stmt {
	mut stmts := []ast.Stmt{}
	for p.tok.kind != .eof {
		match p.tok.kind {
			.key_extern, .key_func {
				stmts << p.parse_func_declaration()
			}
			.at {
				stmts << p.parse_global_assign()
			}
			else {
				report.error('expecting declaration, not $p.tok', p.tok.position()).emit_and_exit()
			}
		}
	}
	return stmts
}

fn (mut p Parser) parse_args(is_extern bool) ([]&ast.Symbol, bool) {
	mut args := []&ast.Symbol{}
	mut use_c_varargs := false
	p.check(.lparen)
	if p.accept(.rparen) {
		return args, false
	}
	for {
		if p.tok.lit == '...' {
			if p.peek_tok.kind != .rparen {
				report.error('`...` should go to the end of the arguments', p.tok.position()).emit()
			} else if !is_extern {
				report.error('`...` is only allowed for definitions', p.tok.position()).emit()
			} else if use_c_varargs {
				report.error('`...` is duplicated', p.tok.position()).emit()
			} else {
				use_c_varargs = true
			}
			p.next()
		} else {
			typ := p.parse_type()
			mut sym := if is_extern { &ast.Symbol{
					gname: ''
				} } else { p.parse_symbol() }
			sym.typ = typ
			p.scope.add(sym.name, sym)
			args << sym
		}
		if !p.accept(.comma) {
			break
		}
	}
	p.check(.rparen)
	return args, use_c_varargs
}

fn (mut p Parser) parse_func_declaration() ast.Stmt {
	mut pos := p.tok.position()
	mut is_extern := p.tok.kind == .key_extern
	if is_extern {
		p.next()
	}
	p.check(.key_func)
	mut sym := p.parse_symbol_with_kind(.function)
	p.open_scope()
	args, use_c_varargs := p.parse_args(is_extern)
	typ := p.parse_type()
	pos = pos.extend(p.tok.position())
	mut stmts := []ast.Stmt{}
	if p.tok.kind == .lbrace {
		if is_extern {
			report.error('external functions cannot have bodies', pos.extend(p.tok.position())).emit()
		} else {
			p.check(.lbrace)
			stmts = p.parse_stmts()
			p.check(.rbrace)
		}
	}
	p.close_scope()
	sym.typ = typ
	mut node := ast.FuncDecl{
		sym: sym
		args: args
		stmts: stmts
		use_c_varargs: use_c_varargs
		ret_typ: typ
		is_extern: is_extern
		labels: p.labels
		pos: pos
	}
	if p.labels.len > 0 {
		p.labels.clear()
	}
	sym.node = node
	g_context.root.add(sym.name, sym)
	return node
}

fn (mut p Parser) parse_assign() ast.Stmt {
	mut pos := p.tok.position()
	left := p.parse_symbol()
	p.check(.assign)
	right := p.parse_instruction()
	pos = pos.extend(p.prev_tok.position())
	p.scope.add_obj(left)
	return ast.AssignStmt{
		left: left
		right: right
		pos: pos
	}
}

fn (mut p Parser) parse_global_assign() ast.Stmt {
	mut pos := p.tok.position()
	mut left := p.parse_symbol()
	mut kind := ast.GlobalAssignKind.default
	mut expr := p.empty_expr()

	p.check(.assign)
	instr_pos := p.tok.position()
	instr := p.tok.lit
	p.next()
	match instr {
		'const' {
			kind = .const_
			left.kind = .constant
			expr = p.parse_literal()
		}
		'type' {
			kind = .type_
			left.kind = .type_
			mut tpos := p.tok.position()
			typ := p.parse_type()
			tpos = tpos.extend(p.prev_tok.position())
			expr = ast.TypeNode{
				typ: typ
				pos: tpos
			}
			left.typ = ast.Type(g_context.register_type_symbol(ast.TypeSymbol{
				name: left.name[1..]
				gname: left.gname
				kind: .alias
				info: ast.AliasInfo{typ}
			}))
			ts := g_context.get_type_symbol(typ)
			if ts.info is ast.StructInfo {
				for f in ts.info.fields {
					if !f.is_ptr() && left.name == '@${g_context.get_type_name(f)}' {
						mut e := report.error('recursion detected in type `$left.name`',
							left.pos)
						e.help('use a pointer instead').emit()
					}
				}
			}
		}
		else {
			report.error('invalid instruction for global symbols', instr_pos).emit()
		}
	}
	pos = pos.extend(p.prev_tok.position())
	if kind == .const_ {
		g_context.root.add_obj(left)
	} else {
		g_context.root.add(left.name, left)
	}
	return ast.GlobalAssignStmt{
		left: left
		expr: expr
		kind: kind
		pos: pos
	}
}

fn (mut p Parser) parse_stmts() []ast.Stmt {
	mut stmts := []ast.Stmt{}
	for p.tok.kind !in [.rbrace, .eof] {
		match p.tok.kind {
			.name {
				if p.peek_tok.kind == .colon {
					// labels
					mut pos := p.tok.position()
					label := p.parse_identifier()
					pos = pos.extend(p.tok.position())
					p.check(.colon)
					if label in p.labels {
						report.error('duplicate label `$label`', pos).emit()
					} else {
						p.labels << label
					}
					stmts << ast.LabelStmt{label, pos}
				} else {
					expr := p.parse_instruction()
					stmts << ast.ExprStmt{expr, expr.pos}
				}
			}
			.mod {
				stmts << p.parse_assign()
			}
			else {
				report.error('expecting statement, not $p.tok', p.tok.position()).emit_and_exit()
			}
		}
	}
	return stmts
}
