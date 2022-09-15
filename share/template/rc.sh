#!/bash

# source this file in any of the following shells to activate (% pkg %)

# Note: tcsh must come first or this won't work (for tcsh).

# tcsh
test -n "$tcsh" && eval '\
setenv (% PKG %)_SHELL tcsh \
set s = ($_) \
@ i = $#s - 1 \
set d = `dirname $s[$i]` \
setenv (% PKG %)_ROOT `cd $d && pwd -P` \
setenv PATH "$(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH" \
setenv MANPATH "$(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:`manpath -q`" \
(% pkg %) setup --rc
exit 0 \
'

# bash
test -n "$BASH_VERSION" && eval '
(% PKG %)_SHELL=bash
(% PKG %)_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PATH=$(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH
MANPATH=$(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:$(manpath -q)
export (% PKG %)_SHELL (% PKG %)_ROOT PATH MANPATH
source "$(% PKG %)_ROOT/share/complete.sh"
(% pkg %) setup --rc
return
'

# zsh
test -n "$ZSH_VERSION" && eval '
(% PKG %)_SHELL=zsh
(% PKG %)_ROOT=$(cd "$(dirname "$0")" && pwd -P)
PATH=$(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH
MANPATH=$(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:$(manpath -q)
export (% PKG %)_SHELL (% PKG %)_ROOT PATH MANPATH
source "$(% PKG %)_ROOT/share/complete.sh"
(% pkg %) setup --rc
return
'

# fish
test -n "$FISH_VERSION" && eval '
set (% PKG %)_SHELL fish
set (% PKG %)_ROOT (cd (dirname (status filename)) && pwd -P)
set PATH $(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH
set MANPATH $(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:(manpath -q)
export (% PKG %)_SHELL (% PKG %)_ROOT PATH MANPATH
grep -B999 "#/FISH" share/complete.sh | string split0 | source
(% pkg %) setup --rc
exit
'

# Other shells including:
# ash, dash, ksh, mksh, posh, sh
test -d "$(% PKG %)_ROOT" && eval '
(% PKG %)_SHELL=$0
PATH=$(% PKG %)_ROOT/bin:$(% PKG %)_ROOT/local/bin:$PATH
MANPATH=$(% PKG %)_ROOT/man:$(% PKG %)_ROOT/local/man:$(manpath -q)
export (% PKG %)_SHELL (% PKG %)_ROOT PATH MANPATH
(% pkg %) setup --rc
return
'

echo "ERROR: for shell '$0', set (% PKG %)_ROOT=/path/to/(% pkg %) before sourcing .rc"

# vim: ft=sh:
