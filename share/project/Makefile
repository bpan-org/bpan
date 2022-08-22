SHELL := bash

o ?=

default:

BPAN_CMDS := $(shell bpan -q cmds)

.PHONY: test
$(BPAN_CMDS)::
	bpan $@ $o
