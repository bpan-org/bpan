#!/bash

# Use one of the following commands to activate `[% package-name %]` in your shell:
#
# ash  | [% NAME %]_ROOT=/path/to/[% package-name %] . /path/to/[% package-name %]/.rc
# bash | source /path/to/[% package-name %]/.rc
# dash | [% NAME %]_ROOT=/path/to/[% package-name %] . /path/to/[% package-name %]/.rc
# fish | source /path/to/[% package-name %]/.rc
# ksh  | [% NAME %]_ROOT=/path/to/[% package-name %] . /path/to/[% package-name %]/.rc
# mksh | [% NAME %]_ROOT=/path/to/[% package-name %] . /path/to/[% package-name %]/.rc
# mrsh | [% NAME %]_ROOT=/path/to/[% package-name %]; . /path/to/[% package-name %]/.rc
# posh | [% NAME %]_ROOT=/path/to/[% package-name %] . /path/to/[% package-name %]/.rc
# sh   | [% NAME %]_ROOT=/path/to/[% package-name %] . /path/to/[% package-name %]/.rc
# tcsh | source /path/to/[% package-name %]/.rc
# yash | . /path/to/[% package-name %]/.rc 2>/dev/null
# zsh  | source /path/to/[% package-name %]/.rc

# Note: tcsh must come first or this won't work (for tcsh).

# tcsh
test -n "$tcsh" && eval '\
setenv [% NAME %]_SHELL tcsh \
set s = ($_) \
@ i = $#s - 1 \
set d = `dirname $s[$i]` \
setenv [% NAME %]_ROOT `cd $d && pwd -P` \
setenv PATH $[% NAME %]_ROOT/bin\:$[% NAME %]_ROOT/local/bin\:/usr/local/bin\:/usr/bin\:/bin \
setenv MANPATH $[% NAME %]_ROOT/man\:$[% NAME %]_ROOT/local/man\:`manpath` \
exit 0 \
'

# bash
test -n "$BASH_VERSION" && eval '
[% NAME %]_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PATH=$[% NAME %]_ROOT/bin:$[% NAME %]_ROOT/local/bin:$PATH
MANPATH=$[% NAME %]_ROOT/man:$[% NAME %]_ROOT/local/man:$(manpath 2>/dev/null)
export [% NAME %]_ROOT PATH MANPATH
return
'

# zsh
test -n "$ZSH_VERSION" && eval '
[% NAME %]_ROOT=$(cd "$(dirname "$0")" && pwd -P)
PATH=$[% NAME %]_ROOT/bin:$[% NAME %]_ROOT/local/bin:$PATH
MANPATH=$[% NAME %]_ROOT/man:$[% NAME %]_ROOT/local/man:$(manpath 2>/dev/null)
export [% NAME %]_ROOT PATH MANPATH
return
'

# fish
test -n "$FISH_VERSION" && eval '
set [% NAME %]_ROOT (cd (dirname (status filename)) && pwd -P)
set PATH $[% NAME %]_ROOT/bin:$[% NAME %]_ROOT/local/bin:$PATH
set MANPATH $[% NAME %]_ROOT/man:$[% NAME %]_ROOT/local/man:(manpath 2>/dev/null)
export [% NAME %]_ROOT PATH MANPATH
exit
'

# yash
test -n "$YASH_VERSION" && eval '
[% NAME %]_ROOT=$(cd "$(dirname "$0")" && pwd -P)
PATH=$[% NAME %]_ROOT/bin:$[% NAME %]_ROOT/local/bin:$PATH
MANPATH=$[% NAME %]_ROOT/man:$[% NAME %]_ROOT/local/man:$(manpath 2>/dev/null)
export [% NAME %]_SHELL [% NAME %]_ROOT PATH MANPATH
return
'

# Other shells including:
# ash, dash, ksh, mksh, mrsh, posh, sh
test -d "$[% NAME %]_ROOT" && eval '
PATH=$[% NAME %]_ROOT/bin:$[% NAME %]_ROOT/local/bin:$PATH
MANPATH=$[% NAME %]_ROOT/man:$[% NAME %]_ROOT/local/man:$(manpath 2>/dev/null)
export [% NAME %]_ROOT PATH MANPATH
return
'

echo "ERROR: for shell '$0', set [% NAME %]_ROOT=/path/to/[% name %] before sourcing .rc"

# vim: ft=sh:
