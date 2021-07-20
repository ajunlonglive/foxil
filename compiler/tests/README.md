# Tests

This folder contains tests for the Foxil compiler.
The tests are divided into 2 forms:

1) Compiler source code: tests for the Scanner or Parser
2) Checks: tests for the Checker

To run the tests we can use the Makefile with:

```bash
$ make test-compiler # Run compiler tests (Scanner and Parser)
$ make test-checks # Run Checker tests
$ make test # Run all the tests (test-compiler and test-checks)
```

In the `checker` folder there are 2 types of files, the tests,
which are Foxil source code files and the expected outputs, which
are the files with the extension `.out`.

To create an expected output file, you can use:

```bash
$ foxilc compiler/tests/checks/<test>.foxil 2> compiler/tests/checks/<test>.out
```

Replacing `<test>` with the name of your test.
