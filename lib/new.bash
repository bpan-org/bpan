new:help() (cat<<'...'
Set up a project to use BPAN

## Synopsis

Example `bpan new` commands:

    $ bpan new --bin doodle
    $ bpan new --lib --name=foo-bar path/to/foo-bash
    $ bpan new --bin --lib poodle


## Description

The 'bpan new' command creates a new BPAN project repository.

You must specify the `--bin` option or the `--lib` option or both.
You must also provide a (non-existent) directory path that `bpan` will create
and init the new project in.

This command is pretty much the same as creating a new directory and running
`bpan init` in it.


## Options

Same options as `bpan init (except --force).

Run `bpan help init` for details.


## See Also

* `bpan help init`
* `bpan help add`
* `bpan help update`
...
)

new:usage() (
  echo "$app [<$app-opts>] $cmd [<$cmd-opts>] <directory-path>"
)

new:options() (cat <<...
bin       Add a bin program: ./bin/<name>
lib       Add a lib program: ./lib/<name>.bash
name=     The name for primary bin / lib files
config=   Specify a name for the config file
from=     Custom directory of template files
...

# from=     Specify a custom template collection
)

new:main() (
  [[ $# -eq 1 ]] ||
    error "'bpan new' requires a (non-existent or empty) directory to create"
  dir=$1

  if ! $option_bin && ! $option_lib; then
    error "'bpan new' requires --bin or --lib (or both)"
  fi

  if [[ -d $dir ]] && ! +empty "$dir"; then
    error "Directory '$dir' already exists and is not empty"
  fi

  opts1=()
  opts2=()

  $option_quiet && opts1+=(--quiet)
  $option_verbose && opts1+=(--verbose)
  $option_debug && opts1+=(--debug)

  $option_bin && opts2+=(--bin)
  $option_lib && opts2+=(--lib)
  $option_name && opts2+=(--name "$option_name")
  $option_config && opts2+=(--config "$option_config")
  $option_from && opts2+=(--from "$option_from")

  mkdir -p "$dir"
  path=$(cd "$dir" && pwd -P)
  cd "$dir" || exit

  bpan "${opts1[@]}" init "${opts2[@]}"

  say -g "Created new BPAN project in '$path'"
)
