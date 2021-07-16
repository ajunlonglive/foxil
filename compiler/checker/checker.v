// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module checker

import compiler.ast

pub struct Checker {}

pub fn run_checker() {
	mut c := Checker{}
	for mut sf in g_context.source_files {
		c.check_file(mut sf)
	}
}

fn (mut c Checker) check_file(mut sf ast.SourceFile) {
}
