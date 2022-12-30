# Normal color vars:
D='\e[30m'      # black (dark)
R='\e[31m'      # red
G='\e[32m'      # green
Y='\e[33m'      # yellow
B='\e[34m'      # blue
M='\e[35m'      # magenta
C='\e[36m'      # cyan
W='\e[37m'      # white

# Bold color vars:
DD='\e[30;1m'   # black (dark)
RR='\e[31;1m'   # red
GG='\e[32;1m'   # green
YY='\e[33;1m'   # yellow
BB='\e[34;1m'   # blue
MM='\e[35;1m'   # magenta
CC='\e[36;1m'   # cyan
WW='\e[37;1m'   # white

# Reset color var:
Z='\e[0m'       # reset

say() (
  set "${BPAN_X:-+x}"
  +say "$@"
)

+say() (
  set "${BPAN_X:-+x}"
  ${option_quiet:-false} && return

  if [[ ${1-} == -? ]]; then
    color=${1#-}; shift
    "+say:$color" "$@"
  else
    +say:color "" "$@"
  fi
)

+say:color() (
  set "${BPAN_X:-+x}"
  ${option_quiet:-false} && return

  color=$1; shift
  if [[ -t 1 ]]; then
    echo -e "$Z$color$*$Z"
  else
    echo -e "$*"
  fi
)

+say:d() { +say:color "$D" "$@"; }
+say:r() { +say:color "$R" "$@"; }
+say:g() { +say:color "$G" "$@"; }
+say:y() { +say:color "$Y" "$@"; }
+say:b() { +say:color "$B" "$@"; }
+say:m() { +say:color "$M" "$@"; }
+say:c() { +say:color "$C" "$@"; }
+say:w() { +say:color "$W" "$@"; }

+say:D() { +say:color "$DD" "$@"; }
+say:R() { +say:color "$RR" "$@"; }
+say:G() { +say:color "$GG" "$@"; }
+say:Y() { +say:color "$YY" "$@"; }
+say:B() { +say:color "$BB" "$@"; }
+say:M() { +say:color "$MM" "$@"; }
+say:C() { +say:color "$CC" "$@"; }
+say:W() { +say:color "$WW" "$@"; }
