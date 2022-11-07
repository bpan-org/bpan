init:help() (cat<<'...'
Set up a project to use BPAN

## Synopsis

Example `bpan init` commands:

    $ bpan init
    $ bpan init --name=foo-bar
    $ bpan init --bin
    $ bpan init --lib


## Description

The 'bpan init' command adds BPAN files to a project.

It is used to either create a new BPAN project (when run in an empty directory)
or to add BPAN support to and existing project.

Usually you only run this program once per project.

Afterwards you can use the following commands to maintain BPAN assets:

* `bpan add`

  Add new files and packages.

* `bpan config`

  Make changes to your `.bpan/config` file.

* `bpan update`

  Update the BPAN assets listed under `[update]` in your `.bpan/config` file.

You can also edit the `.bpan/config file by hand and run `bpan update` to make
sure everything is in sync.


## Options

* `--bin`

  Create the following files:

  * `bin/<name>`

    A starter bin program for your project.

  * `.bpan/lib/bpan.bash`

    Most BPAN bin scripts use this file to bootstrap their environment.

  * `.rc`

    Used for BPAN packages that install a commandline bin utility.

* `--lib`

  Create a `lib/<name>.bash` starter library.

  This option may be used in combination with `--bin`.

* `--name=<name>`

  By default `bpan init` will use the current directory name (stripping off
  `-bash` from the end if it is there) as the name for these files (if it needs
  to create them):

  * `bin/<name>`
  * `lib/<name>.bash`
  * `doc/<name>.md`
  * `man/man1/<name>.md`
  * `man/man3/<name>.md`

  The `--name=...` option lets you override that name.

* `--config=<file-name>`

  Normally the BPAN config file is `.bpan/config`.
  With this options you can specify a different name.
  Then `.bpan/config` will be a symlink to that file.

* `--force`

  The `bpan init` command will not overwrite existing files, unless you use
  this `--force` option.

  Note: If your existing files are committed to git, then you can safely use
  this to overwrite files if you are curious to see what happens.

* `--from=<bpan-template-directory>`

  BPAN provides a default template directory to `init` and `add` from.
  This option lets you choose your own.


## See Also

* `bpan help add`
* `bpan help update`
...
)

init:options() (cat <<...
bin       Add a bin program: ./bin/<name>
lib       Add a lib program: ./lib/<name>.bash
name=     The name for primary bin / lib files
config=   Specify a name for the config file
from=     Custom directory of template files

force     Overwrite existing files
...

# from=     Specify a custom template collection
)

init:main() (
  # TODO assert one of:
  # * we are in an empty dir and we will make .bpan/config
  # * we are in root of a git repo and will make .bpan/config
  # * ./.bpan/config exists
  # * option_force is in effect

  source-once add

  add:set-env

  [[ -f .bpan/config ]] ||
    add:config

  ini:init \
    "$root/etc/config" \
    "$root/config" \
    "$(pwd)/.bpan/config"

  while read -r file; do
    from=$base/$file
    to=$file
    to=${to/bin-NAME/${name/-bash/}}
    to=${to/lib-NAME/${name/-bash/}}
    to=${to/NAME/${name/-bash/}}
    to=${to/gitignore/.gitignore}

    if [[ $file == bin/* ]] ||
         [[ $file == .bpan/lib/* ]]
    then
      $option_bin || continue
    elif [[ $file == lib/* ]]; then
      $option_lib || continue
    elif [[ $file == .rc ]]; then
      [[ -f bin/${name/-bash} ]] || continue
    elif [[ $file == doc/bin-* ]]; then
      $option_bin || continue
    elif [[ $file == doc/lib-* ]]; then
      $option_lib || continue
    fi

    if ! [[ -e $to ]]; then
      add:file "$from" "$to"
    fi

    if [[ $file == doc/* ]]; then
      touch ReadMe.md
      ini:all update.file | grep -q '^ReadMe\.md' || {
        ini:add update.file "ReadMe.md $to"
        if [[ -d bin ]]; then
          ini:add update.man1 "$to"
        else
          ini:add update.man3 "$to"
        fi
      }
    fi
  done < <(
    git config -f "$base/bpan-file.ini" --list |
      grep '^file.init' |
      cut -d '=' -f2- |
      grep -v '^\.bpan/config$'
  )

  pkgs=(
    bashplus:@
    bashplus:@/err
    bashplus:@/sys
    getopt-bash
  )

  if $option_bin; then
    for pkg in "${pkgs[@]}"; do
      add:package-added "$pkg" ||
        add:package "$pkg"
    done
  fi

  pkg=$(ini:get package.name)
  name=${pkg%-bash}

  if [[ ! -d .git ]]; then
    git init --quiet
    say -y "RUNNING 'git init'"
  fi

  source-once update

  say -y "RUNNING 'bpan update'"

  update:main
)
