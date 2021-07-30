# Learning the language

Foxil is a very simple language, learning it shouldn't take
long.

## Introduction

Foxil is an intermediate language developed to facilitate the
generation of code for compilers of languages ​​that do not
require advanced features, but only what is necessary to create
functional and fast binaries.

Next we will see the syntax of the language (as the compiler is
in continuous development, it is possible that the syntax could
change in the future).

## Comments

Comments are useful lines of text that are ignored by the
compiler, in which the developer can leave notes or documentation
about something specific.

Comments in Foxil start with `;` and are single-line (same as
assembly languages):

```llvm
; I am a comment :)
```

## Names

Names in Foxil must always begin with a prefix, carry
alphanumeric letters, and can optionally contain `.` and `::`:

```llvm
; @ -> prefix used for global scope (such as functions, types, constants and variables, etc.)
; % -> prefix used for local scope (as arguments and local variables)

@my::func::name ; valid name
@my.func.name.23 ; valid name
@my_func_name_23 ; valid name
%my.arg.1 ; valid name
%my::arg::2 ; valid name
%.tmp.1 ; valid name
%::tmp.2 ; valid name
```

## Constants

Constants are global symbols, the value of which cannot be changed.
They are declared in the global scope and cannot be declared within
functions.

Example:

```llvm
@age = const i32 2021

extern func @printf(str, ...) i32

func @main() void {
    %msg = cast [17 x char] "Current age: %d\n" as str
    call i32 @printf(str %msg, i32 @age)
    ret void
}
```

## Anonymous structs

Anonymous structs are aggregated without names, which can have fields.

Example:

```llvm
func @make_account(str %name, i32 %age) { str, i32 } {
    ret { str, i32 } { str %name, i32 %age }
}
```

Too verbose, right? but for that there is a solution: aliases.

## Aliases

Aliases are names that we can give to an anonymous struct or to an existing
alias.

Using an alias for the above example things get better:

```llvm
@Account = type { str, i32 }

func @make_account(str %name, i32 %age) @Account {
    ret @Account { str %name, i32 %age }
}
```

Simpler to read.

## Functions

As in any other language, the syntax for declaring a function
is simple:

```llvm
func <NAME>(<ARGS>) <RET-TYP> {
	<STMTS>
}
```

Each function has a unique name, a number of arguments, a
return type, and a series of statements between braces.

The arguments are defined as follows:

```
<Type> <NAME> -> i32 %my.arg
```

Example of a function:

```llvm
func @my::func(i32 %my.arg) u32 {
	%t.1 = cast i32 %my.arg as u32
	ret u32 %t.1
}
```

This function takes as an argument a number of type i32 and
converts it to u32 and returns it.

The statements are divided into 2 groups: assignment and
instructions. Foxil instructions are explained in
[INSTRUCTIONS.md](docs/INSTRUCTIONS.md).

## Assignment

Assignments follow this syntax:

```llvm
; <VAR-NAME> = alloca <T>[, T-Literal]
%my.var = alloca u32
%my.var2 = alloca u32, u32 5
```

## Literals

Literals are constant values ​​that can be assigned to variables by
using instructions.

Its syntax is: `<T> <literal>`

Examples:

```llvm
i8 2
i32 2

bool true
bool false

@MyType { i8 4, i32 1 }

char 'A'

str "AE"

; to use variables, we use literal syntax
%var = alloca i32, i32 100
%var2 = load i32 %var

; array literal
[5 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5]

; struct literal
{i32, bool} {i32 100, bool false}
```

## Labels

Labels allow you to jump to a certain part of your code by using the `br` instruction.

```llvm
first_label:
    %rt = alloca i32, i32 4
    br end

second_label:
    br first_label

end:
    ret i32 0
```
