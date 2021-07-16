// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module ast

import os

// SourceFile represents a Blux source code file
pub struct SourceFile {
pub:
	path      string // the path of the file
	full_path string // the absolute path of the file
	content   string // the content of the file
pub mut:
	// the content of the file divided into lines,
	// to avoid splitting it multiple times
	content_lines []string
	nodes         []Stmt
}

// new_source_file returns a SourceFile with the content of the file
pub fn new_source_file(path string, content string) SourceFile {
	return SourceFile{
		path: path
		full_path: os.real_path(path)
		content: content
		content_lines: content.split('\n')
	}
}

[unsafe]
pub fn (mut sf SourceFile) free() {
	unsafe {
		sf.content_lines.free()
		sf.nodes.free()
	}
}
