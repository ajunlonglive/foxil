<div align="center">

# The Foxil intermediate language 

Fast and light

</div>

Foxil is an intermediate language designed to facilitate compiler code generation. Foxil
uses an easy to read LLVM-IR inspired syntax and generates C code.

For now C code is generated, maybe in the future JavaScript code will be generated, and
possibly also x86 assembly code.

**NOTE:** Foxil is not designed to replace LLVM.

## Features

* Simple and easy to read syntax
* Non-null values
* Fast and light

## Examples

```c
extern int puts(char*);

int main(int argc, char** argv) {
    puts("Hello World!");
    return 0;
}
```

converted to Foxil:

```llvm
extern func @puts(char*) i32

func @main(i32 %argc, char** %argv) i32 {
    %cstr = cast [12 x char] "Hello World!" as char*
    call i32 @puts(char* %cstr)
    ret i32 0
}
```

To see more examples, you can go to the [`examples`](examples/) folder.

## Requirements

* V compiler ^0.2.2
* Any C compiler (GCC, clang, etc.)

## Compilation

To compile Foxil you need the [V language compiler](https://github.com/vlang/v).
Having installed the V compiler, we proceed to execute in the terminal:

```bash
$ git clone https://github.com/StunxFS/foxil
$ cd foxil
$ make
```

A binary will be generated in the `bin` folder. To see if it works we execute the
binary passing it the option `--version`:

```bash
$ ./bin/foxilc --version
foxilc version 0.1.0
```

## Contributions

Any contribution is welcome :)

* * *

<div align="center">

(C) 2021 **Foxil Developers** - All rights reserved

</div>
