// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module compiler

import os
import term
import compiler.util
import compiler.token
import math.mathutil as mu

__global (
	report Reporter
)

struct Reporter {
pub mut:
	errc int
}

enum ReportKind {
	error
	warning
	help
	note
}

struct Report {
	msg string
	pos token.Position
mut:
	kind   ReportKind
	extras []Report
}

pub fn (r Reporter) error(msg string, pos token.Position) &Report {
	return &Report{
		msg: msg
		pos: pos
		kind: .error
	}
}

pub fn (r Reporter) warn(msg string, pos token.Position) &Report {
	return &Report{
		msg: msg
		pos: pos
		kind: .warning
	}
}

pub fn (mut r Report) note(msg string) Report {
	r.extras << Report{
		msg: msg
		kind: .note
	}
	return r
}

pub fn (mut r Report) note_with_pos(msg string, pos token.Position) Report {
	r.extras << Report{
		msg: msg
		kind: .note
		pos: pos
	}
	return r
}

pub fn (mut r Report) help(msg string) Report {
	r.extras << Report{
		msg: msg
		kind: .help
	}
	return r
}

pub fn (r Report) emit() {
	mut r_kind := r.kind
	if r.kind == .warning {
		if g_context.show_no_warnings {
			return
		} else if g_context.treat_warnings_as_errors {
			r_kind = .error
		}
	}
	e := token.Position{}
	kind := r.bold(r.colorize('$r_kind.str():'))
	sep := '       = '
	sep2 := '       | '
	msg := if r.kind in [.note, .help] && r.pos == e {
		util.wrap_string(r.msg, 70, '\n$sep2')
	} else {
		r.msg
	}
	if r.pos != e {
		p := r.bold('$r.pos.str():')
		s := if r.kind == .note { sep2 } else { '' }
		eprintln('$s$p $kind $msg')
		eprintln('$s${r.pos.line + 1:6} | $r.colorize_line()')
		eprintln('$s       | $r.marker()')
		if r.kind == .error {
			report.errc++
		}
	} else {
		eprintln('$sep$kind $msg')
	}
	for rr in r.extras {
		rr.emit()
	}
}

[inline]
pub fn (r Report) emit_and_exit() {
	r.emit()
	unsafe {
		g_context.free()
	}
	exit(1)
}

fn (r &Report) bold(s string) string {
	if g_context.use_color == .always {
		return term.bold(s)
	}
	return s
}

fn (r &Report) colorize(s string) string {
	if g_context.use_color == .always {
		return match r.kind {
			.error {
				term.red(s)
			}
			.warning {
				term.yellow(s)
			}
			.note {
				term.cyan(s)
			}
			.help {
				s
			}
		}
	}
	return s
}

fn (r &Report) colorize_line() string {
	f := g_context.get_source_file(r.pos.file) or {
		foxil_error('unknown code file: $r.pos.file')
		exit(1)
	}
	line := f.content_lines[r.pos.line].replace('\t', '    ')
	start_col := mu.max(0, mu.min(r.pos.col, line.len))
	end_col := mu.max(0, mu.min(r.pos.col + mu.max(0, r.pos.len), line.len))
	mut res := line
	if g_context.use_color == .always {
		res = line[..start_col] + r.bold(r.colorize(line[start_col..end_col])) + line[end_col..]
	}
	return res
}

fn (r &Report) marker() string {
	mut res := ''
	for i := 0; i < (r.pos.col + r.pos.len); i++ {
		if i < r.pos.col {
			res += ' '
		} else {
			res += r.colorize('^')
		}
	}
	return res
}

[inline]
pub fn foxil_warn(msg string) {
	eprintln('foxilc: ' + term.yellow('warning: ') + msg)
}

[inline]
pub fn foxil_error(msg string) {
	eprintln('foxilc: ' + term.bold(term.red('error: ')) + msg)
	eprintln('use `${os.args[0]} --help` to see usage')
	exit(1)
}

[inline]
pub fn foxil_gen_error(msg_ string, cerror string) {
	msg := 'foxilc: ' + term.bold(term.red('error: ')) + msg_
	l := '---------------------------------------------'
	eprintln(msg)
	eprintln('')
	eprintln(cerror)
	eprintln(l)
	eprintln('this should never happen, please report it.')
	eprintln(l)
	exit(1)
}
