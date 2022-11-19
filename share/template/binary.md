<!-- Note to author:
  This templated file is just to get you started.
  You'll need to edit it to refelect your desired content.
  You can safely remove these HTML comments.
-->

[% markdown-title %]

[% pkg-title-default %]

## Synopsis

...

## Description

...

## Installation

* With [BPAN](
  https://github.com/bpan-org/bpan#installation):
  ```
  bpan install [% pkg %]
  ```

  <!-- Note to author:
    This section only applies if you have a `.rc` file,
    otherwise remove this section.
  -->

* From source:
  ```
  git clone [% config:package.repo %] /path/to/[% pkg %]
  ```

  Then add the following line to your shell's startup file:
  ```
  source /path/to/[% pkg %]/.rc
  ```

  This supports 12 interactive shells including `bash`, `zsh` and `fish`.

## Copyright and License

Copyright [% copyright-year %] by [% author-name %]

This is free software, licensed under:

The MIT (X11) License
