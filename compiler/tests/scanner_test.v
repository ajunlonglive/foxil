// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module scanner_test

import compiler.parser
import compiler.token

fn scan(text string) []token.Kind {
	mut s := parser.new_scanner_with_text(text)
	mut tks := []token.Kind{}
	for tok := s.scan(); tok.kind != .eof; tok = s.scan() {
		tks << tok.kind
	}
	return tks
}

fn test_simple_name() {
	kinds := scan('simple name')
	assert kinds.len == 2
	assert kinds[0] == .name
	assert kinds[1] == .name
}

fn test_number_literal() {
	// decimal
	mut kinds := scan('2004 2008.95 2008e9')
	assert kinds.len == 3
	assert kinds[0] == .number
	assert kinds[1] == .number
	assert kinds[2] == .number

	// hexadecimal
	kinds = scan('0x9AFC8')
	assert kinds.len == 1
	assert kinds[0] == .number

	// octal
	kinds = scan('0o666')
	assert kinds.len == 1
	assert kinds[0] == .number

	// binary
	kinds = scan('0b10101010101111101')
	assert kinds.len == 1
	assert kinds[0] == .number
}
