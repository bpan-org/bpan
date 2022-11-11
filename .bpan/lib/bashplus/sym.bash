# Generate a unique symbol by joining a prefix (default is 'sym') to a random
# string, separated by an underscore (`_`) character.
# Useful for unique variable and function names.
# Here we define 6 different ways to generate a random string, since there is
# no standard way to do this in Bash 3.2+.

# For 5.0+ use EPOCHREALTIME unless it is already spoiled.
if [[ ${EPOCHREALTIME-} != "${EPOCHREALTIME-}" ]]; then
  # prevent `unset EPOCHREALTIME` which spoils it:
  readonly EPOCHREALTIME
  # This is fastest by far:
  +sym() {
    echo "${1:-sym_}_${EPOCHREALTIME/./_}"
  }
# uuidgen is pretty standard and pretty fast
elif +can uuidgen; then
  +sym() {
    local s
    s=$(uuidgen)
    echo "${1:-sym}_${s//-/_}"
  }
# BSD date (macOS) doesn't support nanoseconds
elif date --version &>/dev/null; then
  +sym() {
    echo "${1:-sym}_$(date '+%s_%N')"
  }
# `od` is super common but check for /dev/urandom
elif +can od && [[ -e /dev/urandom ]]; then
  +sym() {
    local words
    read -ra words < <(od -A n -t x2 -N 16 /dev/urandom)
    echo "${1:-sym}_$(printf '%s' "${words[@]}")"
  }
# Bash's RANDOM is 3.2+ but can also be spoiled by unset.
elif [[ ${RANDOM}_${RANDOM} != ${RANDOM}_${RANDOM} ]]; then
  readonly RANDOM
  +sym() {
    echo "${1:-sym_}_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}"
  }
# Try perl
elif +can perl; then
  +sym() {
    echo "${1:-sym_}_$(
      perl -MTime::HiRes -e 'print join "_", Time::HiRes::gettimeofday'
    )"
  }
else
  die "bashplus can't define '+sym'"
fi
