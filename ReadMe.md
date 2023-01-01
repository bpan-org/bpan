BPAN
====

Bash Packages Are Nearby


## BPAN Documentation

* [[bpan-overview]]
* [[bpan-user-guide]]
* [[bpan-author-guide]]


## Synopsis

Using the `bpan` CLI tool:
```
$ bpan --help
$ bpan show --commands
$ bpan help <command>
$ bpan find foo
$ bpan install somebody/foo-bar-bash
```

Use the `bpan` Bash library in your Bash code:
```
#!/usr/bin/env bash

source "$MY_PROJECT_ROOT/.bpan/lib/bpan.bash" --

bpan:source bashplus +err +sys
bpan:source getopt
bpan:source json
```

Create new packages with BPAN:
```
$ bpan init --new=foo-bar-bash --lib
$ bpan add --pkg=json-bash
$ bpan add --file=test/foo.t
$ bpan update
$ bpan test
```

Publish your Bash packages:
```
$ bpan publish --register   # Add new package entry to Index
$ bpan publish              # Update package's Index entry
```


## Description

BPAN is the "Missing Bash Package Manager".

It does 3 big things for you and your Bash code:

* Find/install CLI apps/programs/libaries written in Bash
* Install, manage, bundle Bash deps for a project or package
* Publish Bash packages that you make


## Installation

Installing BPAN is simple and everything happens in a single directory on your
host machine.
The standard location is `$HOME/.bpan/` but you can change it to anything you
like.

BPAN is written in "modern" Bash.
It is built over several of the reusable libraries it makes available.

That said, you don't need to use Bash as your interactive shell to use BPAN.
Bash just needs to be installed (and often is by default) because Bash is the
"programming language" in this scenario.

BPAN works and is tested under the following interactive shells: `bash`, `zsh`,
`fish`, `ksh`, `mksh`, `tcsh`, `yash`, `ash`, `dash`, `mrsh`, `posh` and `sh`.


### Installing with the BPAN Installation Script

You can run this command from any of the above shells to install BPAN:

```
bash <(curl -sL get.bpan.org)
```

The script will try to identify your interactive shell type, and will choose an
installation location of `$HOME/.bpan/`.

You can override these with the `BPAN_SHELL` and `BPAN_ROOT` environment
variables like this:

```
BPAN_SHELL=abcsh BPAN_ROOT=/some/path bash <(curl -sL get.bpan.org)
```


### Install BPAN from its Source Repository

NOTE: It is common to use `$HOME/.bpan` for `/path/to/bpan` in the following:

1. Clone the BPAN repo:
   ```
   git clone https://github.com/bpan-org/bpan /path/to/bpan
   ```

2. Source the BPAN `.rc` file to use `bpan` immediately.
   Use one of these commands, depending on your shell:
   ```
   ash  |  BPAN_ROOT=/path/to/bpan . /path/to/bpan/.rc
   bash |                     source /path/to/bpan/.rc
   dash |  BPAN_ROOT=/path/to/bpan . /path/to/bpan/.rc
   fish |                     source /path/to/bpan/.rc
   ksh  |  BPAN_ROOT=/path/to/bpan . /path/to/bpan/.rc
   mksh |  BPAN_ROOT=/path/to/bpan . /path/to/bpan/.rc
   mrsh | BPAN_ROOT=/path/to/bpan; . /path/to/bpan/.rc
   posh |  BPAN_ROOT=/path/to/bpan . /path/to/bpan/.rc
   sh   |  BPAN_ROOT=/path/to/bpan . /path/to/bpan/.rc
   tcsh |                     source /path/to/bpan/.rc
   yash |                          . /path/to/bpan/.rc 2>/dev/null
   zsh  |                     source /path/to/bpan/.rc
   ```

3. Add the command in step 2 to your shell's startup file (`$HOME/.bashrc`, etc).


### Prerequisites

BPAN needs just a few very common things to work:

* Bash 3.2+
  * The BPAN system is written in Bash (of course)
* Git 2.9+
  * Required by `bpan` CLI and many BPAN packages, but...
  * Not required by programs using BPAN packages (that don't require it)
* GitHub account
  * Only needed to publish to BPAN indexes hosted on GitHub
  * The default BPAN index is on GitHub


## Copyright and License

Copyright 2022-2023 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License
