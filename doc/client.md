bpan(1)
=======

This is the command line tool for installing packages from BPAN.

## Synopsis

General command-line usage:

    bapn --help
    bpan find json
    bpan install json
    bpan update
    bpan upgrade
    bpan env BPAN_ROOT
    bpan env
    bpan version

BPAN Package Author Commands:

    bpan register
    bpan release
    bpan makefile > Makefile

## Installation

You can install BPAN in any directory you want.

A reasonable place is `~/.bpan/`, but it is completely up to you. Simply change
all the occurences of `~/.bpan` below to your choice:

    # Clone the 'bpan' repo:
    git clone http://github.com/bpan-org/bpan ~/.bpan
    # Add these commands to your shell initialization:
    export PATH=~/.bpan/bin:~/.bpan/lib:$PATH
    export MANPATH=~/.bpan/man:$MANPATH

You can even have many different BPAN installs.  Wherever `bpan` is found in
your `PATH`, the entire BPAN environment will be set up for that location.

## Using BPAN in different shells

Just because Bash is a shell and BPAN is for Bash and `bpan` is written in Bash
does'nt mean you can't use it under the shell of your choice. If you are a Zsh
or Dash or Fish user, everything should work fine as long as `bash` is
somewhere in your command PATH.

## Environment

These variables will all be set automatically or you can set some or all of
them yourself:

* `BPAN_ROOT`
* `BPAN_BIN`
* `BPAN_LIB`
* `BPAN_MAN`
* `BPAN_MAN1`
* `BPAN_MAN3`
* `BPAN_INDEX`
* `BPAN_BUILD`
* `BPAN_CONFIG`

These all have reasonable defaults, but feel free to customize them.
`BPAN_ROOT` is based on the path to the `bpan` command, and the others are
based on `BPAN_ROOT`.

To get the value of an automatically set command, use the `bpan env` command:

    bpan env BPAN_ROOT
    bpan env BPAN_INDEX

or use with no args to see all the `BPAN_` variables.
