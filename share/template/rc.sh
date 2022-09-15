#!/bash

# source this file in any of the following shells to activate (% pkg %)

# Note: tcsh must come first or this won't work (for tcsh).

# tcsh
test -n "$tcsh" && eval '\
set s = ($_) \
@ i = $#s - 1 \
set d = `dirname $s[$i]` \
setenv (% PKG %)_ROOT `cd $d && pwd -P` \
setenv PATH "$(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH" \
setenv MANPATH "$(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:`manpath -q`" \
exit 0 \
'

# bash
test -n "$BASH_VERSION" && eval '
(% PKG %)_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PATH=$(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH
MANPATH=$(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:$(manpath -q)
export (% PKG %)_ROOT PATH MANPATH
return
'

# zsh
test -n "$ZSH_VERSION" && eval '
(% PKG %)_ROOT=$(cd "$(dirname "$0")" && pwd -P)
PATH=$(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH
MANPATH=$(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:$(manpath -q)
export (% PKG %)_ROOT PATH MANPATH
return
'

# fish
test -n "$FISH_VERSION" && eval '
set (% PKG %)_ROOT (cd (dirname (status filename)) && pwd -P)
set PATH $(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH
set MANPATH $(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:(manpath -q)
export (% PKG %)_ROOT PATH MANPATH
exit
'

# Other shells including:
# ash, dash, ksh, mksh, posh, sh
test -d "$(% PKG %)_ROOT" && eval '
PATH=$(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH
MANPATH=$(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:$(manpath -q)
export (% PKG %)_ROOT PATH MANPATH
return
'

echo "ERROR: for shell '$0', set (% PKG %)_ROOT=/path/to/(% pkg %) before sourcing .rc"

# vim: ft=sh:
