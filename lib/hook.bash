hook:options() (cat <<...
dryrun    Don't run, just show what would run
keepgoing Ignore hook failures
...
)

hook:main() (
  git:in-repo ||
    error "Not in a git repo directory"

  failed=0

  for hook in "$@"; do
    hook:run "$hook" $option_dryrun $option_keepgoing || {
      failed=$((failed+1))

      $option_keepgoing || exit 1
    }
  done

  [[ $failed = 0 ]] || exit 1
)

hook:run() (
  hook=$1
  dryrun=$2
  keepgoing=$3
  failed=0

  while read -r script; do
    script=${script#*=}

    if $dryrun; then
      say -y "Running $hook hook: $script (not really, dryrun is enabled)"
    else
      say -y "Running $hook hook: $script"

      [[ -x "$script" ]] || {
        warn "Skipping non-executable $hook hook: $script"
        continue
      }

      # TODO - sanitize $script?
      "./$script" || {
        code=$?
        failed=$((failed+1))

        msg="$hook hook $script failed ($code)"
        if $keepgoing; then
          warn "$msg"
        else
          error "$msg"
        fi
      }
    fi

  done < <(
    script=".bpan/hooks/$hook"
    [[ -x "$script" ]] && echo "$script"

    ini:list --file=.bpan/config |
      grep "^hook\.$hook"
  )

  return $failed
)
