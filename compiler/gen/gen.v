// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module gen

import os
import strings
import compiler
import compiler.ast

const (
	header           = '// Generated by the Foxil compiler, version $compiler.version\n'
	c_reserved_words = ['if', 'else', 'switch', 'extern', 'static', 'return', 'struct', 'enum',
		'typedef',
	]
	fx_runtime_h     = 'foxil_runtime.h'
	guard            = '__GUARD__FOXIL__RUNTIME__HEADER__'
)

fn cname(name string) string {
	if name in gen.c_reserved_words || name in ast.native_type_names {
		return '_fx__$name'
	}
	return name
}

struct Gen {
mut:
	typedefs   strings.Builder
	structs    strings.Builder
	fns        strings.Builder
	header     strings.Builder
	source     strings.Builder
	opt        string
	indent     int
	empty_line bool
	arrays     []int
}

pub fn run_gen() {
	mut g := Gen{
		typedefs: strings.new_builder(100)
		structs: strings.new_builder(100)
		fns: strings.new_builder(100)
		header: strings.new_builder(100)
		source: strings.new_builder(100)
		opt: if g_context.optimize { '-O2' } else { '' }
	}
	g_context.files_to_delete << gen.fx_runtime_h
	for sf in g_context.source_files {
		g.gen_file(&sf)
	}

	g.header.writeln(gen.header)
	g.header.writeln('#ifndef $gen.guard
#define $gen.guard

// ============= Foxil RUN-TIME :) ============
#include <inttypes.h>
#define true  (1)
#define false (0)
#define NULL  (0)
// =================== END ====================
')
	if g.typedefs.len > 0 {
		g.header.writeln('// typedefs')
		g.header.writeln(g.typedefs.str())
	}
	if g.structs.len > 0 {
		g.header.writeln('// structs')
		g.header.writeln(g.structs.str())
	}
	g.header.writeln('// functions')
	g.header.writeln(g.fns.str())
	g.header.writeln('\n#endif // $gen.guard')

	// .c => .o => .exe
	os.write_file(gen.fx_runtime_h, g.header.str()) or { compiler.foxil_error(err.msg) }
	if !g_context.compile_only {
		for sf in g_context.source_files {
			fname := os.file_name(sf.path)
			c_file := '${fname}.c'
			obj_file := '${fname}.o'
			res := os.execute('$g_context.cc $g.opt -o $obj_file -c $c_file')
			if res.exit_code != 0 {
				compiler.foxil_error('an error occurred while creating the object code for `$sf.path`:\n$res.output')
			} else {
				g_context.objects << obj_file
				g_context.files_to_delete << c_file
			}
		}
		if !g_context.compile_and_assemble {
			list := g_context.objects.join(' ')
			res := os.execute('$g_context.cc -o $g_context.output $list')
			if res.exit_code != 0 {
				compiler.foxil_error('an error occurred while creating the binary `$g_context.output`:\n$res.output')
			}
			g_context.files_to_delete << g_context.objects
		}
		g_context.delete_files()
	}
}

fn (mut g Gen) gen_file(sf &ast.SourceFile) {
	g.source.writeln(gen.header)
	g.source.writeln('#include "$gen.fx_runtime_h"\n')
	g.stmts(sf.nodes)
	os.write_file('${os.file_name(sf.path)}.c', g.source.str()) or { compiler.foxil_error(err.msg) }
}

fn (mut g Gen) stmts(stmts []ast.Stmt) {
	for stmt in stmts {
		g.stmt(stmt)
	}
}

fn (mut g Gen) stmt(stmt ast.Stmt) {
	match stmt {
		ast.FuncDecl {
			if stmt.is_extern {
				g.fns.write_string('extern ')
			}
			header_fn := '${g.typ(stmt.ret_typ)} ${stmt.sym.gname}('
			g.fns.write_string(header_fn)
			if !stmt.is_extern {
				g.write(header_fn)
			}
			if stmt.args.len == 0 {
				g.fns.write_string('void')
				if !stmt.is_extern {
					g.write('void')
				}
			} else {
				for i, arg in stmt.args {
					arg_ := '${g.typ(arg.typ)} $arg.gname'
					g.fns.write_string(arg_)
					if !stmt.is_extern {
						g.write(arg_)
					}
					if i != stmt.args.len - 1 {
						g.fns.write_string(', ')
						if !stmt.is_extern {
							g.write(', ')
						}
					}
				}
			}
			g.fns.writeln(');')
			if !stmt.is_extern {
				g.writeln(') {')
				g.indent++
				g.stmts(stmt.stmts)
				g.indent--
				g.writeln('}\n')
			}
		}
		ast.AssignStmt {
			sym := stmt.left
			g.write('${g.typ(sym.typ)} $sym.gname')
			g.write(' = ')
			g.expr(stmt.right)
			g.writeln(';')
		}
		ast.ExprStmt {
			g.expr(stmt.expr)
			g.writeln(';')
		}
		else {}
	}
}

fn (mut g Gen) typ(typ ast.Type) string {
	ts := g_context.get_type_symbol(typ)
	if ts.info is ast.ArrayInfo {
		t_idx := typ.idx()
		if t_idx !in g.arrays {
			g.typedefs.writeln('typedef ${g.typ(ts.info.elem_type)} *$ts.gname;')
			g.arrays << t_idx
		}
	}
	return ts.gname + '*'.repeat(typ.nr_muls())
}

pub fn (mut g Gen) write(s string) {
	if g.indent > 0 && g.empty_line {
		g.source.write_string('    '.repeat(g.indent))
	}
	g.source.write_string(s)
	g.empty_line = false
}

pub fn (mut g Gen) writeln(s string) {
	if g.indent > 0 && g.empty_line {
		g.source.write_string('    '.repeat(g.indent))
	}
	g.source.writeln(s)
	g.empty_line = true
}
