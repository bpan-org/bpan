SHELL := bash

BPAN_CMDS := $(shell bpan cmds -q | grep -v '^test$$')

default:
	$(info $(BPAN_CMDS))

.PHONY: test
test:
	bpan $@ -v

$(BPAN_CMDS)::
	bpan $@
