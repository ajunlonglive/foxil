<div align="center">

# The Foxil intermediate language 

Easy and safe

</div>

Foxil is an intermediate language developed to facilitate the creation of programming
languages. Foxil uses a syntax inspired by LLVM-IR, and uses the C programming language
as a backend.

The idea is to facilitate code generation, allowing you to use a single syntax to
generate code for several languages. For now Foxil generates C code, but more languages
will be added very soon, such as C++, or JavaScript/TypeScript. If you want to add
your own backend, don't hesitate to do it!

## Example

```c
int puts(char*);

int main() {
    puts("Hello World!");
    return 0;
}
```

converted to Foxil:

```llvm
; A simple "Hello World"

@.str = const [13 x char] "Hello World\0A\00"

extern func @puts(char*) i32

func @main(i32 %argc, char** %argv) i32 {
    %charptr = get_element_ptr [13 x char], [13 x char] @.str, i64 0
    call i32 @puts(char* %charptr)
    ret i32 0
}
```

## Requirements

* V compiler ^0.2.2

## Contributions

Any contribution is welcome :)

* * *

<div align="center">

(C) 2021 **Foxil Developers** - All rights reserved

</div>
