BPAN - Bash Packages Ain't No Joke
==================================

http://bpan.org

BPAN's a very modern packaging system, that serves the Bash language.

Bash is a programming language that has been around since 1989, but is
generally only seen as a scripting language for smallish tasks. In fact, it is
a very cabaple language that is better suited to many tasks than languages like
Perl, Ruby, Python or Node.js.

The thing that Bash is missing is a set of reusable packages (libraries,
modules). BPAN intends to fill that gap.

BPAN also is trying to use techniques from the modern (2014) era, that will
make it more lightweight and scalable than its predecessors CPAN, RubyGems,
PyPI and NPM. If this works out well, BPAN can be used as a model for languages
that need a new packaging system.

## Use the BPAN Client

If you want to install the BPAN packages and use them, see the documentation
[here](https://github.com/bpan-org/bpan/tree/client#readme).

## Repository Layout

This repository has 4 main branches:

* master — General Information and Documentation Only
* gh-pages — The bpan.org website (including the BPAN indexes
* server — The webhook server code (sinatra server)
* client — The BPAN commandline client / installer (written in Bash, of course)

## Architecture

BPAN is built over GitHub infrastructure. It is not tied to it forever, but
GitHub has almost all the pieces ready to go. A small sinatra server receives
webhook API calls from GitHub and updates the indexes.
