rc:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command [<cmd-opts>] <pkg-id...>

'$app $command' Options:
--
bash          Print rc commands for Bash shell
fish          Print rc commands for Fish shell
ksh           Print rc commands for Ksh shell
zsh           Print rc commands for Zsh shell

h,help        Get help for $command command
"
}

rc:main() (
  if $option_bash; then
    rc:bash
  elif $option_fish; then
    rc:fish
  elif $option_ksh; then
    rc:ksh
  elif $option_zsh; then
    rc:zsh
  else
    error "'$app rc' requires --bash, --fish or --zsh"
  fi
)

rc:bash() (
  cat <<'...'
PATH=$BPAN_ROOT/bin:$BPAN_ROOT/local/bin:$PATH
MANPATH=$BPAN_ROOT/man:$BPAN_ROOT/local/man:$MANPATH
MANPATH=${MANPATH%:}
export PATH MANPATH
source "$BPAN_ROOT/share/complete.sh"
...
)

rc:fish() (
  cat <<'...'
set PATH "$BPAN_ROOT/bin:$BPAN_ROOT/local/bin:$PATH"
set MANPATH "$BPAN_ROOT/man:$BPAN_ROOT/local/man:$MANPATH"
# TODO remove possible trailing ':'
export PATH MANPATH
# TODO tab completion for Fish:
# source "$BPAN_ROOT/share/complete.fish"
...
)

rc:ksh() (
  cat <<'...'
PATH=$BPAN_ROOT/bin:$BPAN_ROOT/local/bin:$PATH
MANPATH=$BPAN_ROOT/man:$BPAN_ROOT/local/man:$MANPATH
export PATH MANPATH
...
)

rc:zsh() (
  cat <<'...'
PATH=$BPAN_ROOT/bin:$BPAN_ROOT/local/bin:$PATH
MANPATH=$BPAN_ROOT/man:$BPAN_ROOT/local/man:$MANPATH
MANPATH=${MANPATH%:}
export PATH MANPATH
source "$BPAN_ROOT/share/complete.sh"
...
)
