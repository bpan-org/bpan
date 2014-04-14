BPAN Meta Data Spec
===================

This document is a spec for the meta data declaration of BPAN, but also aims to
be general solution for packages that have many different target systems and
use many different meta data consumers.

## The Problem

Package managers and other tools like Travis and Bower, need extra meta-data
from a package in order to work. The normal way is to put the info into a known
file in a known format like JSON or YAML.

The problem is that every system defines their own way of specifying the info.
Often systems want the same metadata, so you repeat yourself in many files, and
they start polluting the top level of your repo. As packages become more
complex and start serving multiple platforms, this does not scale well.

## The Solution

All the data could go in one file. Each system first looks under a hash key
that they own (like `=bpan`). If a value is not found there, then the top level
hash is checked. This way common data is specified once at the top level, but
can be overridden as needed.

Domain specific keys begin with `=` so they do not conflict with the top level
of any system.

Example:

meta.yaml:

    name: Mister-Blonde
    version: 0.0.5
    author:
    - name: Ingy dot Net
      email: ingy@oui.st
    - name: Andrew Cole
      twitter: aocole
    =bpan:
      bpan: 2.4.6
      name: mr-blonde
      deps:
      - json-bash: 1.2.3
    =npm:
      requires:
      - xyz: 0.1.7

The system namespaces always begin with `=` to avoid collision.

## Meta File Name

New systems tend to use their own name. This gets clumsy. The intent of this
spec is that people start moving towards consolidating files, while still
having namespace automomy. There is no mandated filename, but certain names are
encouraged. If you already have a meta file required by another system, you
should be able to co-opt it, without breaking that system. If it does break
that system, you can fall back to separate files.

The prefered file name for meta info in BPAN is `Meta`, but any of the
following are good candidates:

* Meta
* meta
* meta.json
* meta.yaml
* .meta
* .meta/conf
* Package*

and so on. BPAN will look for a file in JSON or YAML and use one that has all
the required keys. If there are more than one, the file that has a `=bpan` will
be used.

This allows freedom for developers to use what makes sense to them and their
ecosystems, but still be unambiguous.

If no file extension is used, the file will use simple heuristics to determine
the file type (JSON, YAML).

One idea to combine files is to use symlinks. For instance, a `.travis.yml`
file could be symlinked to a `Meta` file as long as Travis-CI does not care
about unknown keys.

## Meta Spec for BPAN

    =bpan:
      api:      BPAN API info (API version)
      other-overrides
    name:       Package Name
    version:    Package release semver (matches tag of release)
    author:     Author info (single or list)
      name:     Human name
      email:
      twitter:
      avatar:
    requires:   Dependency hash
    recommends: Dependency hash
    build:      Build info
      cmd:      Build command
      requires: Build time deps
    test:       Test info
      cmd:      Test command
      requires: Test time deps
    abstract:   Short phrase description
    description:  Paragraph description
    license:    Known name or url
    homepage:   Project homepage
    tags:       List of tags
    bugs:       Bug tracker
    source:     Repo url

In general any scalar value can be made richer by using a hash, and anything
that can have multiple values can be an array. This spec will grow as needed.

BPAN requires `=bpan`, `name` and `version` keys at an absolute minimum.

## Preferred BPAN top level directory layout:

    Changes
    License
    Makefile
    Meta
    ReadMe(.md)
    bin/
    doc/
    ext/
    lib/
    test/
    .travis.yml
