// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module main

import os
import compiler
import compiler.parser
import compiler.checker

const (
	exe  = os.args[0]
	args = os.args[1..].clone()
)

fn main() {
	// we initialize the current context
	g_context = compiler.new_context()
	// we collect the arguments given by the user
	parse_args()
	// we run the parser
	parser.run_parser()
	if report.errc > 0 {
		abort_app()
	}
	// if the user only wants to check the syntax, we do nothing else,
	// otherwise, we continue
	if !g_context.only_check_syntax {
		// we run the checker, to check types, symbols, etc.
		checker.run_checker()
		if report.errc > 0 {
			abort_app()
		}
		// we run the C generator
		/*
		gen.run_gen()
		if report.errc > 0 {
			abort_app()
		}
		*/
	}
	// and finally we release the current context
	g_context.cleanup()
}

fn abort_app() {
	g_context.cleanup()
	exit(1)
}
