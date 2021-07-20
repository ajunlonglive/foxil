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
extern int puts(char*);

int main() {
    puts("Hello World!");
    return 0;
}
```

converted to Foxil:

```llvm
; A simple "Hello World"

extern func @puts(char*) i32

func @main(i32 %argc, char** %argv) i32 {
    %str = alloca [12 x char], [12 x char] "Hello World!"
    %cstr = cast [12 x char] %str as char*
    call i32 @puts(char* %cstr)
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
