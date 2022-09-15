#!/bash

[[ ${BPAN_ROOT-} ]] || {
  (
    echo "Tests require BPAN to be installed."
    echo "See https://github.com/bpan-org/bpan"
  ) >&2
  exit 1
}

source "$BPAN_ROOT/lib/bpan.bash" --

export PATH=$PWD/lib:$PATH

bpan:source bashplus --
bpan:source test-tap
