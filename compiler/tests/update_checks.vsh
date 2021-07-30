// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
import os
import term

files := walk_ext('compiler/tests/checks', '.foxil')
amount := files.len
mut idx := 1
println(term.header('Checking $amount tests', '-'))
for file in files {
	outname := file.replace('.foxil', '.out')
	outfile := os.read_file(outname) ?
	print(term.cyan(' [$idx/$amount] '))
	print('$file')
	res := os.execute('bin/foxilc $file')
	if res.exit_code != 0 {
		if res.output != outfile {
			os.write_file(outname, res.output) ?
			println(term.green(' [UPDATED]'))
		} else {
			println(term.cyan(' [NOT UPDATED]'))
		}
	}
	idx++
}
println(term.header('', '-'))
