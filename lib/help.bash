help:main() (
  [[ $# -eq 1 ]] ||
    error "usage: $app help <cmd-name>"

  cmd=$1

  lib=$root/lib/$cmd.bash
  if [[ -f $lib ]]; then
    source-once "$cmd"
  else
    error "'$cmd' is not a valid $app command"
  fi

  if +sys:is-fun "$cmd:help"; then
    if +sys:is-cmd md2man && +sys:is-cmd man; then
      export MD2MAN_NAME='bpan help'
      export MD2MAN_DESC="bpan $cmd"
      man=/tmp/"$cmd.1"
      rm -fr "$man"
      md2man < <(help:get-markdown "$cmd") > "$man"
      man "$man"
      rm -f "$man"
    else
      (
        help:get-markdown "$cmd"
        echo
        warn "Run: 'bpan install md2man' to see 'bpan help' as manpages"
      ) | less -FRX
    fi
  else
    if +sys:is-fun "$cmd:getopt"; then
      say -r "No help page is yet available for '$app $cmd'"
      echo
      echo "Showing 'bpan $cmd --help' instead:"
      echo
      bpan "$cmd" -h
    else
      error "No help is yet available for '$app $cmd'"
    fi
  fi
)

help:get-markdown() (
  cmd=$1
  title="bpan $cmd"
  line=$(eval "printf '%.0s=' {1..${#title}}")
  echo "$title"
  echo "$line"
  echo
  "$cmd:help"
  if +sys:is-fun "$cmd:getopt"; then
    echo
    echo "See also: 'bpan $cmd --help'"
  fi
)
