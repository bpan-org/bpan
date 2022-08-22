BPAN
====

Bash Packages Are Nifty

## Synopsis

Using the `bpan` CLI tool:
```
$ bpan search utils
$ bpan install somebody/path-utils
$ bpan new /path/to/my-project
$ bpan add getopt-bash ingydotnet/json-bash
```

Use the `bpan` Bash library in your Bash code:
```
#!/usr/bin/env bash

source "$MY_PROJECT_ROOT/.bpan/lib/bpan.bash" --prelude
bpan:use getopt=0.1.0
bpan:use ingydotnet/json
```

Publish your Bash packages:
```
$ bpan register .
$ bpan publish .
```

## Description

BPAN is the "Missing Bash Package Manager".

It does 3 big things for you and your Bash code:

* Find and install CLI programs written in Bash
* Install, manage, bundle Bash deps for a project
* Register and publish Bash packages that you make

## Installation

1. Clone the BPAN repo:
   ```
   git clone https://github.com/bpan-org/bpan ~/.bpan
   ```
2. Source the BPAN `.rc` file to use `bpan` immediately:
   ```
   source ~/.bpan/.rc
   ```
3. Add the command in step 2 to your shell's startup file (`~/.bashrc`, etc).

NOTE: `~/.bpan/` can be changed above to any other location that you wish to
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

## Using the `bpan` CLI

The `bpan` command has 2 major roles:

* Finding and installing BPAN packages system-wide
  * These are generally `bin` scripts in your `PATH`
  * They are installed by default under `$BPAN_ROOT/local/`
  * The `search` and `install` BPAN commands are common
* Managing BPAN dependency libraries for a project
  * The `.bpan/config` file declares your BPAN dependencies
  * Things get added to your project under `.bpan/`
  * The `init`, `add` and `update` commands are common

Commands are grouped into 3 categories:

* System-wide
* Per-project
* Informational

Start with `bpan --help` to get the basic usage info.

Documentation can be read with `man bpan`.

## Using BPAN in a Project

BPAN is intended to be used mostly in software projects that have Bash
dependencies.

To create a new project from scratch (that uses BPAN):
```
bpan new <dir-name>
```

To add BPAN support (`.bpan/`) to an existing project:
```
bpan init
```

To add a BPAN dependency to a project:
```
bpan add prelude-bash getopt-bash
```

To update the BPAN dependency files and generate man pages:
```
bpan update
```

### System-wide BPAN Directory and File Layout

When you install packages system-wide with BPAN, things are stored under the
`~/.bpan/local/` directory.

There are several `~/.bpan/local/` subdirectories where things get installed
into:

* `bin/` - Executable Bash programs (in `$PATH`)
* `lib/` - Supporting Bash libraries
* `share/` - Any supporting files needed by programs
* `man/man1/` - Program docs
* `man/man3/` - Library docs
* `src/` - Source code repository clones/downloads

### Per-project BPAN Directory and File Layout

BPAN installs per-project things under a `.bpan/` directory in the root of your
project.

There are 3 main files to be aware of:

1. `./.rc`

   This file is responsible for defining and exporting `MY_PROJECT_ROOT` where
   `MY_PROJECT` is the name of your project.
   This environment variable is the key to bootstrapping BPAN and other things
   that your project will need.
   While not strictly necessary, it is highly recommended.

2. `./.bpan/config`

    This is your project's BPAN configuration file.
    It's where you make all of your configuration choices and list all the BPAN
    dependency packages.

3. `./.bpan/lib/bpan.bash`

   This is the file that you `source` in your programs to initialize the BPAN
   environment, with something like:
   ```
   source "$MY_PROJECT_ROOT/.bpan/lib/bpan.bash" --
   # or:
   export PATH=$MY_PROJECT_ROOT/.bpan/lib:$PATH
   source bpan --
   ```
   This will initialize all the settings that you have chosen for your project,
   and autoload all the BPAN packages that you have configured.

Additionally there are 3 possible `.bpan/` sub-directories:

* `.bpan/lib/`
* `.bpan/bin/`
* `.bpan/share/`

This is where your per-project dependency package assets are installed to.

### Project `.bpan/config` Configuration

A typical BPAN `config` file looks like:
```
[bpan]
name = thinger-bash
version = 0.1.0
abstract = Do the thing
license = MIT
copyright = 2022

[author]
name = Ingy döt Net
email = ingy@ingy.net
github = ingydotnet
libera = ingy
twitter = ingydotnet
site = https://github.com/${author.github}

[auto]
do = source prelude.bash
do = source getopt.bash

[require]
prelude-bash = 0.1.0+
getopt-bash = 0.1.0+

[require "command"]
bash = 4.4+
git = 2.25+
perl = 5.28.3+
```

## Copyright and License

Copyright 2022 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License
