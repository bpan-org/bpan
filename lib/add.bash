add:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command <key> [<value>]

'$app $command' Options:
--
h,help        Get help for $command command
"
}

add:main() (
  for pkg; do
    die "bpan add $pkg"
  done
)
