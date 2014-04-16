bpan(1)
=======

This is the command line tool for installing packages from BPAN.

## Synopsis

    bpan find json
    bpan install json
    bpan update
    bpan upgrade
    bpan env BPAN_ROOT
    bpan version

## Installation

You can install BPAN in any directory you want. We recommend `~/.bpan/` but it
is completely up to you. Whereever `bpan` is found in your `PATH` it will
adjust everything else for you. In other words, change `~/bpan` to your choice
in these commands:

    # Clone the client branch of the 'bpan' repo:
    git clone http://github.com/bpan-org/bpan ~/.bpan --branch=client
    # Add these lines to your shell init file:
    export PATH=~/.bpan/bin:$PATH
    export MANPATH=~/.bpan/man:$MANPATH

## Environment

These variables all set automatically or you can set them yourself:

* `BPAN_ROOT`
* `BPAN_BIN`
* `BPAN_LIB`
* `BPAN_MAN`
* `BPAN_MAN1`
* `BPAN_MAN3`
* `BPAN_INDEX`
* `BPAN_BUILD`

These all have reasonable defaults, but feel free to do what you want.

To get the value of an automatically set command, use the `bpan env` command:

    bpan env BPAN_ROOT
    bpan env BPAN_INDEX

