// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
import os
import term

if os.args.len > 1 {
	files := walk_ext(os.args[1], '.foxil')
	amount := files.len
	mut idx := 1
	mut ok := 0
	mut fail := 0
	mut skip := 0
	println(term.header('Running $amount tests', '-'))
	for file in files {
		expected := os.read_file(file.replace('.foxil', '.out')) ?
		print(term.cyan(' [$idx/$amount] '))
		print('$file ->')
		res := os.execute('bin/foxilc $file')
		if res.exit_code != 0 {
			if res.output == expected {
				println(term.green(' OK'))
				ok++
			} else {
				println(term.red(' FAIL'))
				println('Expected output:')
				println(expected)
				println('Output received:')
				println(res.output)
				fail++
			}
		} else {
			println(term.yellow(' SKIP (the test was compiled)'))
			skip++
		}
		idx++
	}
	println(term.header('Summary for all tests: $ok passed, $fail failed, $skip skipped',
		'-'))
	if fail > 0 || skip > 0 {
		exit(1)
	}
} else {
	eprintln('test-checkings: a directory containing tests is required')
	exit(1)
}
