# Check if a file or directory is empty
+fs:empty() {
  local path=${1?}
  if [[ -f $path ]]; then
    ! [[ -s $path ]]
  elif [[ -d $path ]]; then
    ! [[ $(shopt -s nullglob; printf '%s' *) ]]
  else
    die "'$path' is not a file or directory"
  fi
}

# Get the absolute path of a dirname
+fs:dirname() {
  cd "$(dirname "$1")" || exit
  pwd -P
}

# Get the absolute path of a directory
+fs:dirpath() {
  cd "$1" || exit
  pwd -P
}

# Check if 2 files are the same or different.
+fs:file-same() { diff -q "$1" "$2" &>/dev/null; }
+fs:file-diff() { ! +fs:file-same "$@"; }

# mktemp files and dirs that automatically get deleted at end of scope.
+fs:mktemp() {
  temp=$(mktemp "$@")
  if [[ -d $temp ]]; then
    chmod '=rwx' "$temp"
  else
    chmod '=rw' "$temp"
  fi
  +trap "[[ -d '$temp' ]] && rm -fr '$temp' || rm -f '$temp'"
}

# Get file modification time in epoch seconds
if [[ $OSTYPE == darwin* ]]; then
  +fs:mtime() { stat -f %m "$1"; }
else
  +fs:mtime() { stat -c %Y "$1"; }
fi
