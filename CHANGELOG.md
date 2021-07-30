# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]

* **CHANGED:** Deprecate the use of an array of chars for string literals; use `str` instead.
* **CHANGED:** Implement `getelement` instruction for `str` and pointers.
* **CHANGED:** Implement `ref` instruction.

## [v0.2.0] - 2021-07-26

* **CHANGED:** Merge the `goto` instruction with the `br` instruction.
* **ADDED:** `getelement` instruction, to access elements of arrays or struct fields.
* **ADDED:** Documentation (`docs/` folder).
* **ADDED:** Support for constants.
* **ADDED:** Support for anonymous structs.
* **ADDED:** Support for alias.
* **ADDED:** `select` instruction, to select a value based on a boolean condition.

## [0.1.0] - 2021-07-21

* First release (We generate functional binaries :D!).

[Unreleased]: https://github.com/StunxFS/foxil/compare/v0.2.0...HEAD
[v0.2.0]: https://github.com/StunxFS/foxil/releases/tag/v0.2.0
[0.1.0]: https://github.com/StunxFS/foxil/releases/tag/0.1.0
