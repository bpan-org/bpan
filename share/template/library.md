(% markdown-title %)

Your tagline for '(% pkg %)'

## Synopsis

...

## Description

...

## Installation

* With [BPAN](
  https://github.com/bpan-org/bpan#installation):
  ```
  bpan install (% pkg %)
  ```

* From source:
  ```
  git clone (% config:package.repo %) /path/to/(% pkg %)
  ```

  Then add the following line to your shell's startup file:
  ```
  source /path/to/(% pkg %)/.rc
  ```

  This support 12 interactive shells including `bash`, `zsh` and `fish`.

## Copyright and License

Copyright (% copyright-year %) by (% author-name %)

This is free software, licensed under:

The MIT (X11) License
