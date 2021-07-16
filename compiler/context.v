// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module compiler

import os
import compiler.ast
import compiler.util

pub const (
	version       = '0.1.0-alpha'
	compiler_home = os.dir(os.executable()).all_before('bin')
	foxil_home    = os.join_path(os.home_dir(), '.foxil_home')
	cache_dir     = os.join_path(foxil_home, 'cache')
)

__global (
	g_context Context // the current compiler context
)

pub enum UseColor {
	auto
	always
	never
}

// Context represents the current context of the
// compiler
pub struct Context {
pub mut:
	root   ast.Scope // the global scope
	output string    // binary name
	cc     string    // C compiler to use
	// cache directory used to store the object code files and .c files
	cache_dir                string
	optimize                 bool // do we apply optimizations? default: false
	verbose                  bool // do we inform about everything? default: false
	only_check_syntax        bool
	treat_warnings_as_errors bool
	show_no_warnings         bool
	compile_only             bool
	compile_and_assemble     bool
	use_color                UseColor
	files_to_delete          []string
	objects                  []string
	source_files             []ast.SourceFile
}

// new_context returns a new Context, with some presets
pub fn new_context() Context {
	return Context{
		root: ast.new_root_scope()
	}
}

// add_source_file adds a new source file to the current
// compiler context
pub fn (mut c Context) add_source_file(filename string) {
	content := util.read_file(filename) or {
		foxil_error(err.msg)
		return
	}
	c.source_files << ast.new_source_file(filename, content)
}

// get_source_file returns a reference to a ast.SourceFile
pub fn (c &Context) get_source_file(filename string) ?&ast.SourceFile {
	for i, sf in c.source_files {
		if sf.path == filename {
			return &c.source_files[i]
		}
	}
	return none
}

// cleanup frees the memory used in the current context
pub fn (mut c Context) cleanup() {
	for f in c.files_to_delete {
		if c.compile_only && (f.ends_with('.h') || f.ends_with('.c')) {
			continue
		}
		os.rm(f) or { foxil_error(err.msg) }
	}
	unsafe {
		g_context.free()
	}
}

[unsafe]
pub fn (mut c Context) free() {
	unsafe {
		c.objects.free()
		c.files_to_delete.free()
	}
}
