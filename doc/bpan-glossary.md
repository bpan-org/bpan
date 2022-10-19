BPAN Concepts and Terminology
=============================

This document explains BPAN concepts and terminology.

BPAN is a Bash programming ecosystem.
Its primary goal is to put Bash on an equal footing with other modern
programming languages.

It provides:

* A searchable registry of Bash programs and libraries.
* A CLI tool for searching, installing, authoring and publishing Bash programs
  and libraries.
* Various Bash libraries to make Bash programming simple and robust.
  Some examples include:
  * `bashplus` - A set of various "sugar" functions for the most common Bash
    operations.
  * `getopt-bash` - Simple and powerful CLI argument and option parsing.
  * `test-tap-bash` - A TAP testing framework with bells and whistles.
  * `json-bash` - A JSON parser in pure Bash.


## Bash Programs

BPAN packages generally are one of 2 flavors: **Programs** and **Libararies**.

Programs are CLI commands (often taking options and arguments).
Good ones have tab completion in all modern interactive shells: Bash, Zsh,
Fish, etc.
They support common options like `program --help` and `program `--version`.
They also have manpages containing full documentation.
BPAN makes it easy for all BPAN programs to have all of these best practices
with minimum effort.

Where libraries are generally placed/installed in `.../lib/` directories,
programs live in `.../bin/` directories.
The `bin` directories are in turn added to the `PATH` environment variable.
The result being that the programs in the `bin` directories can be run by users
at the command line.

Note that it is common for BPAN program packages to install `lib` libraries in
addition to their `bin` program(s).
These libraries are usually not intended to be reused by other projects, but
just a way to organize a large program's code.

NOTE: When a BPAN program package is installed with `bpan` like:
```
bpan install kool-thing
```
the `kool-thing` program is immediately ready to run from the command-line.

This doesn't mean that you can only install Bash programs that use BPAN with
the `bpan` CLI.

You might want to write programs that use BPAN but are never published to BPAN.
The `bpan add --file=.rc` (the same way `bpan` itself is installed) is one way
to simplify your program's process for users to install it, but at the
end-of-the-day you how you publish and tell people to install your software is
up to you.



## Bash Libraries

Of utmost importance to a successful programming language is the availability
of published, installable, reusable libraries (modules / packages / gems / etc)
that a program (or another library) can import to do various tasks.

In Bash you can `source some-library` just like:
```
import "some/library"       # Go
require('some/library');    # JavaScript
use Some::Library;          # Perl
import some.library         # Python
use some::library;          # Rust
```

It is even possible for a library to support "export" semantics like:
```
source some-library this that
```

These languages all have their own library/package registries and CLI managers.
BPAN provides those for Bash.


## BPAN and Git

BPAN makes every attempt to not require software other than Bash 3.2 or higher.
But it is also pragmatic and doesn't ignore commonly installed system commands
where they are specifically needed.

To be clear, BPAN programs and libraries *can* be written to run with only Bash
as a prerequisite.
That said, some external utilities are needed to search, install and publish
BPAN packages.

BPAN makes heavy use of Git.
The BPAN CLI (`bpan`) requires Git for all operations.
The 3 main things the `git` provides are:

1. Cloning repositories.
   All BPAN packages are hosted repositories.
2. Reading and writing INI files.
   BPAN uses the same INI format as git to read and write config files.
   It also currently stores the BPAN Index in this format.
   And it uses `git config` to do the actual work.
3. Option parsing.
   The BPAN package `getopt-bash` is a full featured wrapped around the Git
   command `git rev-parse --parseopt`.

At present, BPAN also makes great use of GitHub and GitHub Actions to automate
the BPAN processes.
All current BPAN packages are hosted on GitHub, but that will soon be extended
to other Git hosting platforms, and possibly other repo types besides Git.

In summary, nothing about BPAN is inextricably tied to Git or GitHub, and all
decisions keep that in mind.
But they are also both extremely powerful and widely used, so we take
appropriate advantage of that.


## Other BPAN External Dependencies




## BPAN Glossary

* BPAN Package

  A published and installable Bash project that comes with code, documentation,
  tests, etc.

* BPAN Project

  The terms "project" and "package" are mostly used interchangably.
  All BPAN packages are BPAN projects, but a project is any code base that uses
  BPAN.

* BPAN Index


