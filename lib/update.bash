update:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command <key> [<value>]

'$app $command' Options:
--
l,local       Symlink install to local repos

h,help        Get help for $command command
"
}

update:main() (
  update:require
  update:man
)

update:require() (
  [[ -d .bpan ]] ||
    error "Can't 'bpan update'. No '.bpan/' directory"

  source1 install

  (
    file=lib/bpan.bash
    if [[ -f .bpan/$file ]] &&
      ! [[ -h .bpan/$file ]]
    then
      (
        echo-y "Updating '.bpan/$file'"
        $option_verbose && set -x
        cp -Lp "$root/$file" ".bpan/$file"
      )
    fi
  )

  while read -r pkg; do
    pkg=${pkg#require.bpan.}
    pkg=${pkg#require.test.}
    pkg=${pkg%%=*}

    install:main "$pkg"
    install:parse-vars "$pkg"

    while read -r file; do
      rm -f ".bpan/$file"
      mkdir -p "$(dirname ".bpan/$file")"

      if $option_local; then
        (
          echo-y "Updating '.bpan/$file' (local)"
          $option_verbose && set -x
          ln -s "$root/local/$file" ".bpan/$file"
        )
      else
        n=${file//[^\/]/}
        n=${#n}
        prefix=..
        for (( i = 1; i < n; i++ )); do prefix+=/..; done

        (
          echo-y "Updating '.bpan/$file'"
          $option_verbose && set -x
          cp -Lp "$root/local/$file" ".bpan/$file"
        )
      fi
    done < <(
      cd "$src" || exit
      find bin lib share -type f 2>/dev/null || true
    )

  done < <(
    bpan:config-read
    git config -lf- <<<"$config" |
      grep -E '^require\.(bpan|test)\.'
  )
)

update:man() (
  ([[ -d doc ]] && is-cmd md2man) || return

  # shellcheck disable=2044
  for md in $(find doc -type f -name '*.md'); do
    name=${md#doc/}
    name=${name%.md}
    num=3
    if [[ -f bin/$name ]]; then
      num=1
    fi
    mkdir -p "man/man$num"
    man=man/man$num/$name.$num

    MD2MAN_NUM=$num
    MD2MAN_NAME=$name
    MD2MAN_DESC=$(bpan config bpan.abstract)
    MD2MAN_PROG="md2man v0.1.0"
    export MD2MAN_NUM MD2MAN_NAME MD2MAN_DESC MD2MAN_PROG

    warn "+md2man < $md > $man"
    md2man < "$md" > "$man"
  done
)
