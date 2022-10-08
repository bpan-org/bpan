<!-- from doc/bpan.md -->


## Using the `bpan` CLI

The `bpan` command has 3 major roles:

* Finding and installing BPAN packages system-wide
  * These are generally `bin` scripts in your `PATH`
  * They are installed by default under `$BPAN_ROOT/local/`
  * The `search` and `install` BPAN commands are common
* Managing BPAN dependency libraries for a project
  * The `.bpan/config` file declares your BPAN dependencies
  * Things get added to your project under `.bpan/`
  * The `init`, `add` and `update` commands are common
* Creating and publishing BPAN packages
  * Use the `new` or `init` commands for new projects
  * Use the `bump`, `register` and `publish` commands to release

Commands are grouped into 3 categories:

* System-wide
* Per-project
* Informational

Start with `bpan --help` to get the basic usage info.

Documentation can be read with `man bpan`.


### System-wide BPAN Directory and File Layout

When you install packages system-wide with BPAN, things are stored under the
`$HOME/.bpan/local/` directory.

There are several `$HOME/.bpan/local/` subdirectories where things get
installed into:

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
api-version = 1

[package]
name = thinger-bash
version = 0.1.0
title = Do the thing
license = MIT
copyright = 2022

repo = https://github.com/$author.github/$package.name
branch = main
site = $package.repo
bug = $package.repo/issues/
irc = irc.libera.chat/bpan

[author]
name = Ingy döt Net
email = ingy@ingy.net
github = ingydotnet
twitter = ingydotnet
irc = ingy@irc.libera.chat
matrix = @ingy:yaml.io
site = https://github.com/$author.github

[owner]
github = ingydotnet

[require "package"]
bashplus = 0.1.0+
getopt-bash = 0.1.0+

[require "command"]
bash = 4.4+
git = 2.25+
perl = 5.28.3+

[update]
package = bashplus
package = getopt-bash
file = License
file = Makefile
file = ReadMe.md doc/thinger.md
file = test/init
file = test/00-shellcheck.t
man1 = doc/thinger.md
```


## BPAN Sources

Currently, all BPAN installable packages are specific commits in public Git
repositories.

The BPAN index lives here: https://github.com/bpan-org/bpan-index


