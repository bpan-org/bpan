init:help() (cat<<...
Set up a project to use $APP

## Synopsis

Create an entirely new $APP package directory:

    $ $app $cmd --new=my-app-pkg --bin

Init an existing project:

    $ $app $cmd
    $ $app $cmd --name=foo-bar
    $ $app $cmd --bin
    $ $app $cmd --lib


## Description

The '$app $cmd' command adds $APP files to a project.

It is used to either create a new $APP project or to add $APP support to an
existing project.

Usually you only run this program once per project.

Afterwards you can use the following commands to maintain $APP assets:

* '$app add'

  Add new files and packages.

* '$app config'

  Make changes to your '.$app/config' file.

* '$app update'

  Update the $APP assets listed under '[update]' in your '.$app/config' file.

You can also edit the '.$app/config file by hand and run '$app update' to make
sure everything is in sync.


## Options

* '--new=<name>'

  Create a new directory to '$app $cmd' in.
  This will also run 'git init' in the new project directory.

* '--bin'

  Create the following files:

  * 'bin/<name>'

    A starter bin program for your project.

  * '.$app/lib/$app.bash'

    Most $APP bin scripts use this file to bootstrap their environment.

  * '.rc'

    Used for $APP packages that install a commandline bin utility.

* '--lib'

  Create a 'lib/<name>.bash' starter library.

  This option may be used in combination with '--bin'.

* '--name=<name>'

  By default '$app $cmd' will use the current directory name (stripping off
  '-bash' from the end if it is there) as the name for these files (if it needs
  to create them):

  * 'bin/<name>'
  * 'lib/<name>.bash'
  * 'doc/<name>.md'
  * 'man/man1/<name>.md'
  * 'man/man3/<name>.md'

  The '--name=...' option lets you override that name.

* '--config=<file-name>'

  Normally the $APP config file is '.$app/config'.
  With this options you can specify a different name.
  Then '.$app/config' will be a symlink to that file.

* '--from=<$app-template-directory>'

  $APP provides a default template directory to 'init' and 'add' from.
  This option lets you choose your own.

* '--force'

  The '$app $cmd' command will not overwrite existing files, unless you use
  this '--force' option.

  Note: If your existing files are committed to git, then you can safely use
  this to overwrite files if you are curious to see what happens.


## See Also

* '$app help add'
* '$app help update'
...
)

init:options() (cat <<...
new=      New directory name to init

bin       Add a bin program: ./bin/<name>
lib       Add a lib program: ./lib/<name>.bash

name=     The name for primary bin / lib files
config=   Specify a name for the config file
from=     Custom directory of template files

force     Overwrite existing files
...
)

init:main() (
  if [[ $option_new ]]; then
    init:new "$option_new"
  else
    init:apply
  fi
)

init:apply() (
  source-once add

  add:set-env

  [[ -f .bpan/config ]] ||
    add:config

  ini:init \
    "$config_file_system" \
    "$config_file_global" \
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
    github:bpan-org/bashplus:@
    github:bpan-org/bashplus:@/err
    github:bpan-org/bashplus:@/sys
    github:bpan-org/getopt-bash
  )

  if $option_bin; then
    for pkg in "${pkgs[@]}"; do
      add:package-added "$pkg" ||
        add:package "$pkg"
    done
  fi

  bpan:get-pkg-vars
  pkg=$pkg_name
  name=${pkg%-bash}

  if [[ ! -d .git ]]; then
    git init --quiet
    say -y "RUNNING 'git init'"
  fi

  say -y "RUNNING 'bpan update'"
  source-once util/db
  db:sync
  source-once update
  update:apply
)

init:new() (
  dir=$1

  if ! $option_bin && ! $option_lib; then
    error "'bpan init --new=...' requires --bin or --lib (or both)"
  fi

  if [[ -d $dir ]] && ! +fs:empty "$dir"; then
    error "Directory '$dir' already exists and is not empty"
  fi

  mkdir -p "$dir"
  path=$(cd "$dir" && pwd -P)
  cd "$dir" || exit

  init:apply

  if +git:has-untracked; then
    git add .
    say -y "Making initial 'git commit'"
    git commit --quiet --message='Initial commit'
  fi

  say -g "Created new BPAN project in '$path'"
)
