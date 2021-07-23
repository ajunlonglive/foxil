# Foxil instructions list

## alloca
`alloca` stores a value on the stack and returns the address where that
value is stored.

### Syntax
```llvm
alloca T
alloca T, <Literal>
```

### Example
```llvm
%t  = alloca u32
%t2 = alloca u32, u32 4
```

* * *

## br
`br` works in 2 ways: if it receives a single argument, it will behave like
`goto` and check that the argument passed is an existing label; but if it
receives 3 arguments, it will behave like an
`if (cond) goto label2; else goto label2;`, where if the condition
is true, it will jump to the first label, otherwise, to the second label.

### Syntax
```llvm
br <LABEL>
br <BOOLEAN>, <TRUE-LABEL>, <FALSE-LABEL>
```

### Example
```llvm
    %b = alloca bool, bool true
    br bool %b, first_label, second_label

first_label:
    ret i32 0

second_label:
    ret i32 1
```

* * *

## cast
`cast` converts a literal from one type to another, as long as they are
compatible with each other (such as numbers, or boolean with a number, or
`rawptr` with a pointer).

### Syntax
```llvm
cast <LITERAL> as <T>
```

### Example
```llvm
%r = cast u32 5 as i32
```

* * *

## call
`call` calls a function and returns the result of the call.

### Syntax
```llvm
call <FUNCTION>
```

### Example
```
func @myfunc(i32 %a) i32 {
    ret i32 %a
}

call i32 @myfunc(i32 55)
%d = call i32 @myfunc(i32 55)
```

* * *

## cmp
`cmp` compares two operands with the condition passed as the
first argument, and returns a bool

### Syntax
```llvm
cmp <COND> <op1> <op2>
```

Where `<COND>` is one of:

* `eq`: equal
* `ne`: not equal
* `gt`: greater than
* `ge`: greater or equal
* `lt`: less than
* `le`: less or equal

### Example
```llvm
%r = cmp eq i32 5, i32 5
br bool %r, equal, not_equal
```

* * *

<!--
TODO: 'getelement', 'load', 'store',
'add', 'sub', 'mul', 'div', 'mod',
'lshift', 'rshift', 'and', 'or',
'xor', neg
-->

* * *

## ret
`ret` makes the function return the argument that the instruction receives.
If the function returns `void`, then` ret void` should be used.

### Syntax
```llvm
ret <LITERAL>
```

### Example
```llvm
ret void
ret i32 5
```
