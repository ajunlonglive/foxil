// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
import term

files := ls('examples') ?.filter(it.ends_with('.foxil'))
files_total := files.len
mut ok := 0
mut fail := 0

println(term.header('Running examples', '-'))
for i, file in files {
	p := term.cyan('[${i + 1}/$files_total]')
	print(' $p examples/$file -> ')
	mut res := execute('./bin/foxilc examples/$file')
	if res.exit_code != 0 {
		println(term.red('FAIL (in compilation)'))
		eprintln(res.output)
		fail++
	} else {
		res = execute('./executable.out')
		if res.exit_code != 0 {
			println(term.red('FAIL (in execution)'))
			eprintln(res.output)
			fail++
		} else {
			println(term.bright_green('OK'))
			ok++
		}
	}
}
println(term.header('Summary for all examples: $ok passed, $fail failed', '-'))
if fail > 0 {
	exit(1)
}
