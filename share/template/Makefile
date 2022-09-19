SHELL := bash

ifndef BPAN_ROOT
$(info BPAN_ROOT variable not set)
$(info Makefile requires BPAN to be installed)
$(info See: https://github.com/bpan-org/bpan)
$(error ERROR)
endif

BPAN_CMDS := $(shell bpan -q cmds | grep -v test)

o ?=
test ?= test/


default::

$(BPAN_CMDS)::
	bpan $@ $o

.PHONY: test
test::
	prove -v $(test)

ifneq (,$(wildcard .bpan/local.mk))
include .bpan/local.mk
endif
