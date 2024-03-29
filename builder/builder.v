// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module builder

import strings

struct Builder {
pub mut:
	aliases   strings.Builder
	constants strings.Builder
	externs   strings.Builder
	functions strings.Builder
	out       strings.Builder
}

pub fn new() Builder {
	return Builder{
		aliases: strings.new_builder(100)
		constants: strings.new_builder(100)
		externs: strings.new_builder(100)
		functions: strings.new_builder(100)
		out: strings.new_builder(100)
	}
}

pub fn (mut b Builder) str() string {
	b.out.writeln('; Generated by the Foxil `builder` module\n; Please, do not modify manually :)\n')
	if b.aliases.len > 0 {
		b.out.writeln('; aliases')
		b.out.writeln(b.aliases.str())
	}
	if b.externs.len > 0 {
		b.out.writeln('; extern functions')
		b.out.writeln(b.externs.str())
	}
	if b.constants.len > 0 {
		b.out.writeln('; constants')
		b.out.writeln(b.constants.str())
	}
	b.out.writeln('; functions')
	b.out.writeln(b.functions.str())
	return b.out.str()
}
