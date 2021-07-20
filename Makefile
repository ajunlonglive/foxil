# (C) 2021 Foxil Developers. All rights reserved. Use of this source
# code is governed by an MIT license that can be found in the LICENSE
# file.

src_dir=$(CURDIR)/compiler
bin_dir=$(CURDIR)/bin

V=v -enable-globals
VRUN=$(V) run
VFMT=$(V) fmt
VTEST=$(V) test

define help_banner
Usage:
\tmake [target]

Targets:

endef
export help_banner

.PHONY: all format test test-compiler test-checks help
.SILENT: build format test test-compiler test-checks help

.DEFAULT_GOAL := all

all: build

build: ## Build foxil binary
	echo "Building foxil binary..."
	$(V) -o $(bin_dir)/foxilc cmd/

format: ## Format foxil source code
	echo "Formatting V files..."
	$(VFMT) -w $(src_dir) cmd/ compiler/

test: test-compiler test-checks ## Run all tests

test-compiler: ## Test compiler source code
	echo "Running V test files..."
	$(VTEST) compiler/tests/

test-checks: ## Test the Checker
	echo "Running Checker test files..."
	$(VRUN) compiler/tests/test_checks.vsh compiler/tests/checks

help: ## Show this message
	printf "$$help_banner"
	egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-20s\033[0m %s\n", $$1, $$2}'
