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
	scanner      Scanner
	prev_tok     token.Token
	tok          token.Token
	peek_tok     token.Token
	in_decl_def  bool
	inside_bucle bool
	scope        &ast.Scope
	sf           &ast.SourceFile = 0
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
	pos := p.tok.position()
	mut kind := ast.SymbolKind.local
	match p.tok.kind {
		.at {
			p.next()
			ast.SymbolKind.global
		}
		.mod {
			if p.scope.is_root {
				report.error('local scope prefix (`%`) cannot be used in global scope',
					pos).emit()
			}
			p.next()
			ast.SymbolKind.local
		}
		else {}
	}
	name := p.parse_identifier()
	return &ast.Symbol{
		name: name
		pos: pos
		kind: kind
		unresolved: true
	}
}

fn (mut p Parser) parse_literal() ast.Expr {
	mut pos := p.tok.position()
	match p.tok.kind {
		.char {
			lit := p.tok.lit
			p.check(.char)
			p.next()
			return ast.CharLiteral{
				lit: lit
				pos: pos
			}
		}
		.name, .string {
			is_cstr := p.tok.kind == .name && p.tok.lit == 'c'
			if is_cstr {
				p.check(.name)
			}
			lit := p.tok.lit
			p.check(.string)
			return ast.StringLiteral{
				lit: lit
				is_cstr: is_cstr
				pos: pos
			}
		}
		.minus, .number {
			is_neg := p.accept(.minus)
			if is_neg {
				pos = pos.extend(p.tok.position())
			}
			lit := p.tok.lit
			full_lit := if is_neg { '-' + lit } else { lit }
			node := if lit.index_any('.eE') >= 0 && lit[..2].to_lower() !in ['0x', '0o', '0b'] { ast.Expr(ast.FloatLiteral{
					lit: full_lit
					pos: pos
				}) } else { ast.Expr(ast.IntegerLiteral{
					lit: full_lit
					pos: pos
				}) }
			p.next()
			return node
		}
		.at, .mod {
			return ast.Expr(p.parse_symbol())
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
			report.error('bad syntax, it should be `[<size> x T]`', pos.extend(p.tok.position())).emit()
		}
		p.check(.name)
		typ := p.parse_type()
		p.check(.rbracket)
		mut nr_muls := 0
		for p.accept(.mult) {
			nr_muls++
		}
		return ast.Type{
			nr_muls: nr_muls
			is_array: true
			array_info: &ast.ArrayInfo{
				typ: typ
				size: size
			}
		}
	}
	if p.accept(.at)
		&& p.tok.lit in ['void', 'bool', 'i8', 'i16', 'i32', 'i64', 'u8', 'u16', 'u32', 'u64', 'f32', 'f64'] {
		report.error("native types don't require a global scope prefix (`@`)", pos).emit()
	}
	name := p.tok.lit
	p.check(.name)
	sym := ast.Symbol{
		name: name
		gname: util.convert_to_valid_c_ident(name)
		pos: pos
	}
	mut nr_muls := 0
	for p.accept(.mult) {
		nr_muls++
	}
	return ast.Type{
		sym: unsafe { &sym }
		nr_muls: nr_muls
	}
}

fn (mut p Parser) parse_declarations() []ast.Stmt {
	mut stmts := []ast.Stmt{}
	for p.tok.kind != .eof {
		match p.tok.kind {
			.key_def {
				stmts << p.parse_def_declaration()
			}
			.key_decl {
				stmts << p.parse_decl_declaration()
			}
			else {
				report.error('expecting declaration, not $p.tok', p.tok.position()).emit_and_exit()
			}
		}
	}
	return stmts
}

fn (mut p Parser) parse_args(is_def bool) ([]&ast.Symbol, bool) {
	mut args := []&ast.Symbol{}
	mut use_c_varargs := false
	p.check(.lparen)
	if p.accept(.rparen) {
		return args, false
	}
	for {
		if p.tok.kind == .ellipsis {
			if p.peek_tok.kind != .rparen {
				report.error('`...` should go to the end of the arguments', p.tok.position()).emit()
			} else if !is_def {
				report.error('`...` is only allowed for definitions', p.tok.position()).emit()
			} else if use_c_varargs {
				report.error('`...` is duplicated', p.tok.position()).emit()
			} else {
				use_c_varargs = true
			}
			p.next()
		} else {
			typ := p.parse_type()
			mut sym := if is_def { &ast.Symbol{
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

fn (mut p Parser) parse_def_declaration() ast.Stmt {
	p.check(.key_def)
	sym := p.parse_symbol()
	p.open_scope()
	args, _ := p.parse_args(false)
	typ := p.parse_type()
	p.check(.lbrace)
	p.check(.rbrace)
	return ast.DefDecl{
		sym: sym
		args: args
		ret_typ: typ
	}
}

fn (mut p Parser) parse_decl_declaration() ast.Stmt {
	p.check(.key_decl)
	sym := p.parse_symbol()
	p.open_scope()
	args, use_c_varargs := p.parse_args(true)
	typ := p.parse_type()
	return ast.DeclStmt{
		sym: sym
		args: args
		use_c_varargs: use_c_varargs
		ret_typ: typ
	}
}
