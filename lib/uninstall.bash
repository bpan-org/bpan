uninstall:help() (
  cat <<'...'
Uninstall BPAN Packages

# Synopsis

Some 'bpan uninstall ...' commands:

```
$app uninstall getopt-bash
$app uninstall bpan-org/getopt-bash
$app uninstall bpan-org/getopt-bash=0.1.0
$app uninstall github:bpan-org/getopt-bash=0.1.0
```
...
)

uninstall:main() (
  [[ $# -gt 0 ]] ||
    error "'$app $cmd' requires one or more packages"

  source-once util/db

  for package_id do
    uninstall:package "$package_id"
  done
)

uninstall:package() (
  package_id=$1

  db:find-package "$package_id"

  source=$host/$owner/$name/$version

  if ! [[ -d $install_dir/src/$source ]]; then
    say -r "'$fqid=$version' is not installed"
    return
  fi

  say -y "Uninstalling '$name':"

  cd "$install_dir" || exit

  while read -r line; do
    link=${line%% -> *}
    link=${link##* }
    file=${line##* -> }
    [[ $link ]] || continue
    file=${file##*../src/}
    say -w "- Unlink $link -> $file"
    unlink "$link"
  done <<< "$(
    find bin lib man share -type l -print0 2>/dev/null |
      xargs -r -0 ls -l |
      grep -F "$source"
  )"
  say -w "- Removing package src/$source/"
  rm -fr "src/$source/"

  while true; do
    # shellcheck disable=2046
    set -- $(find bin lib man share src -empty 2>/dev/null)
    [[ $# -gt 0 ]] || break
    rmdir "$@"
  done
)
