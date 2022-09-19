SHELL := bash

ifndef BPAN_ROOT
$(info ERROR: 'BPAN_ROOT' variable not set.)
$(info Makefile requires BPAN to be installed.)
$(info Try running '. .rc' first.)
$(info See: https://github.com/bpan-org/bpan#installation)
$(error ERROR)
endif

o ?=
test ?= test/


default:

BPAN_CMDS := $(shell bpan -q cmds | grep -v test)

$(BPAN_CMDS)::
	bpan $@ $o

.PHONY: test
test:
	prove -v $(test)
