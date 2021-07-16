<div align="center">

# The Foxil intermediate language

Easy and safe

</div>

Foxil is an intermediate language developed to facilitate the creation of programming
languages. Foxil uses a syntax inspired by LLVM-IR, and uses the C programming language
as a backend.

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

@.str = const [13 x i8] c"Hello World\0A\00"

decl @puts(i8*) i32

def @main() i32 {
    ; char* i8ptr = &_str[0];
    %i8ptr = get_element_ptr [13 x i8], [13 x i8]* @.str, i64 0
    call i32 @puts(i8* %i8ptr)
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
