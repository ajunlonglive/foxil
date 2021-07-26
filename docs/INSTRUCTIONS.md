# Foxil instructions list

## `alloca`
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

## `br`
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

## `cast`
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

## `call`
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

## `cmp`
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

## `getelement`
`getelement` returns the element found at the index given as an
argument. If `ref` is used, a reference to that element will be
returned.

### Syntax
```llvm
getelement [ref] <array|struct>, <index>
```

### Example
```llvm
%array = alloca [5 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5]
%elem1 = getelement [5 x i32] %array, i32 0 ; == i32:1
%elem2.ptr = getelement ref [5 x i32] %array, i32 1 ; == i32*:2

%struct = alloca {i32, bool}, {i32, bool} {i32 5, bool true}
%s.elem1 = getelement {i32, bool} %struct, i32 1 ; == i32:5
%s.elem2.ptr = getelement ref {i32, bool} %struct, i32 2 ; == i32*:5
```

* * *

## `load`
`load` loads the saved value into a symbol and returns it. If the
symbol is a pointer, it will return the value it points to.

### Syntax
```llvm
load <literal>
```

### Example
```llvm
%t = alloca i32, i32 5 ; %t == 5
%t2 = load i32 %t ; %t2 == 5
```

* * *

## `ret`
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

* * *

## `store`
`store` stores a value in a symbol. If it is a pointer, the value it points to
will be changed to the new one.

### Syntax
```llvm
store <literal>, <symbol>
```

### Example
```llvm
%f = alloca i32, i32 5 ; f == 5
store i32 10, i32 %f ; f == 10
```

* * *

## `add`, `sub`, `mul`, `div`, `mod`, `neg`, `lshift`, `rshift`, `and`, `or`, `xor`
These are arithmetic binary operators, each of them is explained below:

* `add`: Add 2 values ​​and return the result.
* `sub`: Subtract 2 values ​​and return the result.
* `mul`: Multiply 2 values ​​and return the result.
* `div`: Divide 2 values ​​and return the result.
* `mod`: Divide 2 values ​​and return the modulus of the division.
* `neg`: Converts a value to negative.
* `lshift`: Shift left.
* `rshift`: Shift right.
* `and`: AND.
* `or`: OR.
* `xor`: exclusive OR.

### Syntax
```llvm
<op> <literal1> <literal2>
```

### Example
```llvm
%r = add i32 4, i32 4 ; %r == 8
%r2 = sub i32 10, i32 3 ; %r2 == 7
%r3 = mul i32 4, i32 5 ; %r3 == 20
%r4 = div i32 10, i32 4 ; %r4 == 2
%r5 = mod i32 10, i32 80 ; %r5 == 10
%r6 = neg i32 5 ; %r6 == -5
%r7 = lshift i32 4, i32 2 ; %r7 == 16
%r8 = rshift i32 2, i32 4 ; %r8 == 0
%r9 = and i32 42, i32 91 ; %r9 == 10
%r10 = or i32 42, i32 91 ; %r10 == 123
%r11 = xor i32 42, i32 91 ; %r11 == 113
```
