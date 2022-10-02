add:default() (echo --help)

add:help() (cat<<'...'
Add Files, Packages and Commands to a BPAN Project

## Synopsis

bpan add --list

## Description

The 'bpan add' command add

## Options

* `--config` or `--config=<config-file-name>`

  Add a `.bpan/config` BPAN project config file.

  This file is the only required file for a project.

  If you create the file with a different name, then '.bpan/config' will be a
  symlink pointing to it.

* `--files`

  List the files that you can add with `bpan add --file=...`.

* `--file=<bpan-template-file-name>`

  Add a file from the `bpan add --files`.

* `--pkg=<package-name>[:<minimum-version>]`

  Add a project BPAN package requirement to be bundled in '.bpan/lib/'.

* `--cmd=...`

  Add a required system command for the project.

      $ bpan add --pkg=git --pkg=perl=5.18+

* `--bin` or `--bin=<bin-program-name>`

  Add a bin/name program.

* `--lib` or `--lib=<lib-library-name.bash>`

  Add a lib/name.bash program.

* `--from=<bpan-template-directory>`

  BPAN provides a default template directory to `init` and `add` from.
  This option lets you choose your own.

...
)

add:options() (cat <<'...'
config?     Add .bpan/config (or provide a name)

file=       Add a file from 'bpan add --files'
pkg=        Add a bpan package requirement
cmd=        Add a PATH command requirement

files       List the template files bpan can add
from=       Custom directory of template files

bin?        Add a bin/ script
lib?        Add a lib/ library
doc?        Add a doc/ markdown file
test        Add default test files

force       Overwrite if exists
...
)

add:main() (
  force=$option_force
  msg=

  add:set-env

  if $option_files; then
    add:list-files
    return
  fi

  additions=false

  # A config file is required for everything else
  if [[ $option_config &&
        $option_config != false
     ]]
  then
    add:config
    additions=true
    config_file=.bpan/config
  fi

  if $option_test; then
    while read -r file; do
      add:file "$base/$file" "$file"
      additions=true
    done < <(
      grep '^test/' <<< "$update_files"
    )
  fi

  if [[ $option_count_pkg -gt 0 ]]; then
    for pkg in "${option_pkg[@]}"; do
      if ! grep -q "^update.package = $pkg$" \
            <(config:all update.package)
      then
        (
          config:set "require.package.$pkg" '0.0.0+'
          config:add 'update.package' "$pkg"
        )
        additions=true
      fi
    done
  fi

  if [[ $option_count_file -gt 0 ]]; then
    for file in "${option_file[@]}"; do
      to=$file
      from=$base/$file

      if [[ $file == .gitignore ]]; then
        from=$base/gitignore
      fi

      if [[ $file =~ ^bin/([-a-z0-9]+)$ ]]; then
        from=$base/bin/NAME
      elif [[ $file =~ lib/([-a-z0-9]+).bash$ ]]; then
        from=$base/lib/NAME.bash
      elif [[ $file =~ doc/([-a-z0-9]+).bash$ ]]; then
        from=$base/lib/NAME.bash
      elif [[ -f $from ]]; then
        true
      else
        error "Don't know how to add '--file=$file'"
      fi

      add:file "$from" "$to"
      additions=true
    done
  fi

  if $additions; then
    say -y "RUNNING 'bpan update'"
    if $option_quiet; then
      bpan --quiet update
    else
      bpan update
    fi
  fi
)

add:set-env() {
  base=${option_from:-$BPAN_ROOT/share/file}
  [[ -d $base ]] || die "'$base' does not exist"
  [[ -f $base/bpan-file.ini ]] ||
    error "'$base' is an invalid BPAN template file directory"

  update_files=$(
    git config -f "$base/bpan-file.ini" --list |
      grep '^file.update=' |
      cut -d= -f2
  )

  config_file=${option_config:-.bpan/config}

  unset name
  if [[ -e $config_file ]]; then
    name=$(config:get package.name) || true
  fi
  [[ ${name-} ]] || name=$(basename "$PWD")
}

add:list-files() (
  while read -r file; do
    file="${file/NAME/$name}"
    file="${file/gitignore/.gitignore}"
    echo "$file"
  done < <(
    cd "$base" || exit
    find . -not -type d |
      cut -c3- |
      grep -v '^bpan-file.ini'
  )
)

add:config() (
  default=.bpan/config
  conf_file=$option_config

  if [[ $conf_file == true ]]; then
    if [[ -e Meta ]]; then
      conf_file=Meta
    else
      conf_file=$default
    fi
  fi
  [[ $conf_file ]] || conf_file=$default

  if ! $option_force && [[ -e $conf_file || -e $default ]]; then
    $option_all && return
    error "'$conf_file' already exists"
  fi

  msg="ADDED FILE '$conf_file'" \
    add:file "$base/$default" "$default"

  if [[ $conf_file != "$default" ]]; then
    mv "$default" "$conf_file"
    ln -s "../$conf_file" "$default"
    say -y "ADDED LINK '$default' -> '$conf_file'"
  fi
)

add:file() (
  from=$1 to=$2

  if [[ -e $to ]] &&
     ! $option_force
  then
    error "File '$file' already exists"
  fi

  (
    option_quiet=true
    add:file-copy "$from" "$to"
  )

  if grep -q "^$to$" <<<"$update_files"; then
    config:add update.file "$file"
  fi

  say -y "${msg:-"ADDED FILE '$to'"}"
)

add:package-added() (
  package=$1

  config:all update.package |
    grep -q "^$package$"
)

add:package() (
  package=$1

  if add:package-added "$package"; then
    error "Package '$package' already added"
  fi

  config:add update.package "$package"
  config:set require.package."$package" '0.0.0+'

  say -y "${msg:-"ADDED PACKAGE '$package'"}"
)

add:command() (
  say -r "Can't add commands yet."
)

add:file-copy() (
  from=$1
  to=$2

  [[ -e $to ]] &&
    action=UPDATED ||
    action=CREATED

  dir=$(dirname "$to")

  [[ -e $to ]] && existed=true || existed=false

  [[ $dir == . ]] || mkdir -p "$dir"

  temp=$(+mktemp)

  if grep -q -E '\(%.*%\)' "$from"; then
    add:file-render "$from" > "$temp"
  else
    cp -pL "$from" "$temp"
  fi

  if [[ -e $to ]]; then
    if +is-file-same "$to" "$temp"; then
      action=CURRENT
    else
      mv "$temp" "$to"
    fi

  else
    mv "$temp" "$to"
  fi

  say-y "$action '$to'"
)

add:file-render() (
  source-once env

  text=$(< "$1")

  while [[ $text =~ \(%(\ *[-a-zA-Z0-9]+\ *)%\) ]]; do
    match=${BASH_REMATCH[1]}
    cmd=${match##\ }
    cmd=${cmd%%\ }

    text=${text/\(%$match%\)/$("env:$cmd")}
  done

  echo "$text"
)
