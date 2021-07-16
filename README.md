<div align="center">

# The Foxil intermediate language

Easy and safe

</div>

Foxil is an intermediate language developed to facilitate the creation of programming
languages. Foxil uses a syntax inspired by LLVM-IR, and uses the C programming language
as a backend.

# Example

```llvm
decl @puts(cchar* s);

def @main() void {
    call @puts(c"Hello World!");
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
