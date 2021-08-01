// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module builder

import strings

pub struct Function {
pub:
	name     string
	args     []Ident
	variadic bool
	ret_type Type
mut:
	no_indent bool
	body      strings.Builder
}

pub fn (mut b Builder) new_extern_func(name string, args []Type, variadic bool, ret_type Type) {
	b.externs.write_string('extern func @${name}(')
	for i, arg in args {
		b.externs.write_string(arg.str())
		if i != args.len - 1 {
			b.externs.write_string(', ')
		}
	}
	if variadic {
		if args.len > 0 {
			b.externs.write_string(', ')
		}
		b.externs.write_string('...')
	}
	b.externs.writeln(') $ret_type')
}

[inline]
pub fn (mut b Builder) new_func(name string, args []Ident, variadic bool, ret_type Type) Function {
	return Function{
		name: name
		args: args
		variadic: variadic
		ret_type: ret_type
	}
}

pub fn (mut b Builder) add_func(mut func Function) {
	b.functions.write_string('func @${func.name}(')
	for i, arg in func.args {
		b.functions.write_string('$arg.typ %$arg.name')
		if i != func.args.len - 1 {
			b.functions.write_string(', ')
		}
	}
	if func.variadic {
		if func.args.len > 0 {
			b.functions.write_string(', ')
		}
		b.functions.write_string('...')
	}
	b.functions.writeln(') $func.ret_type {')
	b.functions.write_string(func.body.str())
	b.functions.writeln('}\n')
}

[inline]
pub fn (mut f Function) label(name string) {
	f.body.writeln('$name:')
}

[inline]
pub fn (mut f Function) alloca(name string, t Type) {
	f.body.writeln('    %$name = alloca $t')
}

[inline]
pub fn (mut f Function) alloca_with_value(name string, value Value) {
	f.body.writeln('    %$name = alloca $value.typ, $value')
}

[inline]
pub fn (mut f Function) load(name string, value Value) {
	f.body.writeln('    %$name = load $value')
}

[inline]
pub fn (mut f Function) cmp(name string, cond string, v1 Value, v2 Value) {
	f.body.writeln('    %$name = cmp $cond $v1, $v2')
}

[inline]
pub fn (mut f Function) br(label string) {
	f.body.writeln('    br $label')
}

[inline]
pub fn (mut f Function) br2(cond Value, true_label string, false_label string) {
	f.body.writeln('    br $cond, $true_label, $false_label')
}

pub fn (mut f Function) call(func string, ret_type Type, args []Value) {
	if !f.no_indent {
		f.body.write_string('    ')
	}
	f.body.write_string('call $ret_type @${func}(')
	for i, arg in args {
		f.body.write_string(arg.str())
		if i != args.len - 1 {
			f.body.write_string(', ')
		}
	}
	f.body.writeln(')')
}

pub fn (mut f Function) call2(name string, func string, ret_type Type, args []Value) {
	f.body.write_string('    %$name = ')
	f.no_indent = true
	f.call(func, ret_type, args)
	f.no_indent = false
}

[inline]
pub fn (mut f Function) ret_void() {
	f.body.writeln('    ret void')
}

pub fn (mut f Function) instr(name string, values []Value) {
	f.body.write_string('    $name ')
	for i, v in values {
		f.body.write_string('$v')
		if i != values.len - 1 {
			f.body.write_string(', ')
		}
	}
	f.body.writeln('')
}
