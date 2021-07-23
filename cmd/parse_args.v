// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module main

import os
import term
import os.cmdline
import compiler

const usage_msg = 'The Foxil intermediate language compiler v$compiler.version

Usage:
    $exe [OPTIONS] <ARGUMENTS>

Options:
    --help, -h                          show this help message
    --version, -v                       show the compiler version

    --c-compiler, -cc <C-COMPILER>      use <C-COMPILER> to compile            
    --optimize, -opt                    apply optimizations
    
    --output, -o <FILENAME>             the output file will be called <FILENAME>
    --link, -l <OBJFILE>                add an <OBJFILE> file to be linked
    
    --compile-only, -C                  compile only (.c); do not assemble (.o) or link (.exe)
    --compile-and-assemble, -c          compile (.c) and assemble (.o), but do not link (.exe)
    
    --verbose                           in verbose mode, the compiler displays messages
    --color, --no-color                 use/not use colors for the Foxil error/warning messages
    --only-check-syntax                 only check syntax and exit the compiler
    --treat-warnings-as-errors          treat all warnings as errors, even in debug builds
    --show-no-warnings                  show no warnings'

fn parse_args() {
	if args.len == 0 {
		println(usage_msg)
		exit(1)
	}
	g_context.cc = get_c_compiler()
	mut foxil_srcs := false
	for i := 0; i < args.len; i++ {
		arg := args[i]
		current_args := args[i..].clone()
		match arg {
			'--help', '-h' {
				println(usage_msg)
				exit(0)
			}
			'--version', '-v' {
				println('foxilc version $compiler.version')
				exit(0)
			}
			// options
			'--c-compiler', '-cc' {
				if current_args.len > 1 {
					cc := cmdline.option(current_args, arg, '')
					res := os.execute('$cc --version')
					if res.exit_code != 0 {
						compiler.foxil_error('`$cc` is not a valid C compiler')
					}
					g_context.cc = cc
					i++
				} else {
					compiler.foxil_error('`$arg` requires a C compiler as argument')
				}
			}
			'--optimize', '-opt' {
				g_context.optimize = true
			}
			'--output', '-o' {
				if current_args.len > 1 {
					o := cmdline.option(current_args, arg, '')
					if os.is_dir(o) {
						compiler.foxil_error('`$o` is a directory')
					}
					g_context.output = o
					i++
				} else {
					compiler.foxil_error('`$arg` requires a filename as argument')
				}
			}
			'--link', '-l' {
				if current_args.len > 1 {
					objf := cmdline.option(current_args, arg, '')
					if !os.exists(objf) {
						compiler.foxil_error("object code file doesn't exist: `$objf`")
					} else if objf in g_context.user_objects {
						compiler.foxil_error('duplicate object: `$objf`')
					}
					g_context.user_objects << objf
					i++
				} else {
					compiler.foxil_error('`$arg` requires a object file as argument')
				}
			}
			'--compile-only', '-C' {
				g_context.compile_only = true
			}
			'--compile-and-assemble', '-c' {
				g_context.compile_and_assemble = true
			}
			'--verbose' {
				g_context.verbose = true
			}
			'--color' {
				g_context.use_color = .always
			}
			'--no-color' {
				g_context.use_color = .never
			}
			'--only-check-syntax' {
				g_context.only_check_syntax = true
			}
			'--treat-warnings-as-errors' {
				g_context.treat_warnings_as_errors = true
			}
			'--show-no-warnings' {
				g_context.show_no_warnings = true
			}
			// arguments
			else {
				if arg.ends_with('.foxil') {
					if !os.exists(arg) {
						compiler.foxil_error("`$arg` doesn't exist")
					}
					g_context.add_source_file(arg)
					foxil_srcs = true
				} else {
					if arg.starts_with('-') {
						compiler.foxil_error('unknown option `$arg`')
					} else {
						compiler.foxil_error('unknown argument `$arg`, expecting a foxil source file')
					}
				}
			}
		}
	}
	if g_context.use_color == .auto {
		if term.can_show_color_on_stderr() && term.can_show_color_on_stdout() {
			g_context.use_color = .always
		} else {
			g_context.use_color = .never
		}
	}
	if g_context.output == '' {
		g_context.output = 'executable.out'
	}
	if !foxil_srcs {
		compiler.foxil_error('expecting a foxil source file')
	}
}

// get_c_compiler returns a C compiler to work with
fn get_c_compiler() string {
	mut res := os.execute('clang --version')
	if res.exit_code != 0 {
		res = os.execute('clang-9 --version')
		if res.exit_code != 0 {
			res = os.execute('clang-10 --version')
			if res.exit_code == 0 {
				return 'clang-10'
			}
		} else {
			return 'clang-9'
		}
	} else {
		return 'clang'
	}
	// by default all linux distros come with GCC
	return 'gcc'
}
