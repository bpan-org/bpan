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
$ bpan cmds
$ bpan help <command>
$ bpan search utils
$ bpan install somebody/path-utils
```

Use the `bpan` Bash library in your Bash code:
```
#!/usr/bin/env bash

source "$MY_PROJECT_ROOT/.bpan/lib/bpan.bash" --

bpan:source bashplus=0.1.0
bpan:source bpan-org/getopt
bpan:source github:ingydotnet/json
```

Create new packages with BPAN:
```
$ bpan new --lib foo-bar-bash
$ bpan add --pkg=json-bash
$ bpan add --file=test/foo.t
$ bpan update
```

Publish your Bash packages:
```
$ bpan bump --push  # Prep the next publish commit
$ bpan register .   # Add new package entry to Index
$ bpan publish .    # Update package's Index entry
```


## Description

BPAN is the "Missing Bash Package Manager".

It does 3 big things for you and your Bash code:

* Find/install CLI programs/libaries written in Bash
* Install, manage, bundle Bash deps for a project
* Register and publish Bash packages that you make


## Installation

Installing BPAN is simple and everything happens in a single directory on your
host machine.
The standard location is `$HOME/.bpan/` but you can change it to anything you
like.

BPAN, works and is tested under the following shells: `bash`, `zsh`, `fish`,
`ksh`, `mksh`, `tcsh`, `yash`, `ash`, `dash`, `mrsh`, `posh` and `sh`.


### Installing with the BPAN Installation Script

You can run this command from any of the above shells to install BPAN:

```
curl -Lo- https://bpan.org/install | bash
```

The script will try to identify your interactive shell type, and will choose an
install location of `$HOME/.bpan/`.

You can override these like this:

```
curl -Lo- https://bpan.org/install |
    BPAN_SHELL=yash BPAN_ROOT=/some/path bash
```


### Install BPAN from its Source Repository

NOTE: You can replace `$HOME/.bpan` below with any directory path you wish.

1. Clone the BPAN repo:
   ```
   git clone https://github.com/bpan-org/bpan "$HOME/.bpan"
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

NOTE: `$HOME/.bpan/` can be changed above to any other location that you wish to
install BPAN.


### Prerequisites

BPAN needs just a few very common things to work:

* Bash 3.2+
  * The BPAN system is written in Bash (of course)
* Git 2.7+
  * Required by `bpan` CLI and many packages, but...
  * Not required by programs using packages (that don't require it)
* GitHub account
  * Only needed to register and publish packages
  * BPAN publishing only works on GitHub at the current time


## Copyright and License

Copyright 2022 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License
