SHELL := bash

BPAN_CMDS := $(shell bpan cmds -q | grep -v '^test$$')

test ?= test

default:
	$(info $(BPAN_CMDS))

.PHONY: test
test:
	bpan $@ -v $(test)

$(BPAN_CMDS)::
	bpan $@
