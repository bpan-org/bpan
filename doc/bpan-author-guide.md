BPAN Author Guide
=================

This document explains the things you need to do to create and publish a BPAN
package project.
It covers both creating a project from scratch and converting an existing
project to use BPAN and/or publish to BPAN.

Review these other docs first:

* [[bpan-terminology]]
* [[bpan-testing]]


## Creating a package from scratch

To create a new project from scratch, run a command like:

```
bpan new --bin my-project-bash
bpan new --lib my-project-bash
bpan new --bin --lib my-project-bash
```

You need to specify `--bin` or `--lib` or both.

This will create a directory called `my-project` with the following files:
```
.bpan/config
.bpan/lib/bashplus.bash
.bpan/lib/getopt.bash
.bpan/lib/bpan.bash

ReadMe.md
Makefile
License
Changes

bin/my-project
lib/my-project.bash
doc/my-project.md
man/man1/my-project.1
test/00-shellcheck.t
test/init

.rc
.gitignore
```

The exact files depend on the options used.

The `bpan new` command will also run `git init` and add all the new files to an
initial git commit.

All of this is just a starting point for your project and not set in stone.
You are free to add/delete/modify any of the files and ammend the git commit to
your liking.

You are encouraged to edit the `.bpan/config` file right away and adjust the
content.
This file is the control center for BPAN related activity in your project.
It is the only required file to use BPAN in a project.
The `bpan new` makes educated guesses for the initial content, but you'll
almost certainly want to change things.

Whenever you change the config file (or almost anything in the project) you are encouraged to run `bpan update`.
That command will make sure everything is in sync and up to date.


## Adding BPAN to an existing project

If you jumped to this section first, you are encouraged to read the previous
section about `bpan new` first.

To add BPAN stuff to your existing project, just run `bpan init`.

Hint: run `bpan init --help` first to see the options.

The `bpan new` command described above basically creates a new empty directory
and then runs `bpan init` in it.

The `bpan init` command creates all the same files as `bpan new` except it
won't overwrite files that already exist (unless you use `--force`).
Remember, (assuming your project is already committed to a revision control
system like `git`) you can always undo any changes that `bpan` commands like
`init`, `new`, `add` and `update` make.


## Using the `bpan add` command

Under the hood, the `bpan new` and `bpan init` commands are using `bpan add` to
add various (templated) files and published BPAN packages, and then running
`bpan update` to sync everything.

Run `bpan add --help` to see all its options.
Run `bpan help add` to see its help page.


## Using the `bpan bump` command

To prepare a new release, run `bpan bump` (or `bpan bump --push`).
This command will run a series of checks to make sure everything looks good.
If everything looks good, it will:

* Increment the `package.version` field in `.bpan/config`
* Update the `VERSION` in `bin/` and `lib/` files.
* Add a new entry to your `Changes` file.
  * Using `git log` subject lines since last release.
* Commit the changes.
* Tag the new commit with the new version.
* Using `--push` will push the new commit and tag.

Now you are ready to `bpan release` (or `bpan register` if this is your first
release).


## Using the `bpan register` command

A BPAN package release is really just updating the [BPAN Index](
https://github.com/bpan-org/bpan-index/blob/main/index.ini) entry for your
package with your release-ready package's release info.

When you first release a new project to BPAN (obviously) there won't be any
index entry to update.

The `bpan register` command will fork the BPAN Index repo, add an entry for
your project, and then submit a pull request (PR) for that change.

This implies that you will need to wait for a BPAN admin to review (and
hopefully merge) your PR.
The admin may suggest changes, and might reject the PR if it is deemed
inappropriate for BPAN.
Normally this should be rare because the `bpan register` (and `bpan release`)
command runs sanity checks locally before even submitting the PR.

If/when the PR is merged, then your BPAN project will be considered "released"
and available to the world.
Future releases can be done using `bpan release` with no human interaction.


## Using the `bpan release` command

This command triggers an automated process for updating the BPAN Index.

It performs a number of local sanity checks before pulling the trigger.

If everything looks good it will trigger the process and print a URL that you
can use to watch the update progress.
