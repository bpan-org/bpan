D='\e[30m'
R='\e[31m'
G='\e[32m'
Y='\e[33m'
B='\e[34m'
M='\e[35m'
C='\e[36m'
W='\e[37m'
D1='\e[30;1m'
R1='\e[31;1m'
G1='\e[32;1m'
Y1='\e[33;1m'
B1='\e[34;1m'
M1='\e[35;1m'
C1='\e[36;1m'
W1='\e[37;1m'
Z='\e[0m'

say-color() (
  ${option_quiet:-false} && return
  color=$1; shift
  if [[ -t 1 ]]; then
    echo -e "$Z$color$*$Z"
  else
    echo -e "$*"
  fi
)

say() (
  set +x
  if [[ ${1-} == [-+]? ]]; then
    color=$1; shift
    "say$color" "$@"
  else
    say-color "" "$@"
  fi
)

say-d() ( say-color "$D" "$@" )
say-r() ( say-color "$R" "$@" )
say-g() ( say-color "$G" "$@" )
say-y() ( say-color "$Y" "$@" )
say-b() ( say-color "$B" "$@" )
say-m() ( say-color "$M" "$@" )
say-c() ( say-color "$C" "$@" )
say-w() ( say-color "$W" "$@" )

say+d() ( say-color "$D1" "$@" )
say+r() ( say-color "$R1" "$@" )
say+g() ( say-color "$G1" "$@" )
say+y() ( say-color "$Y1" "$@" )
say+b() ( say-color "$B1" "$@" )
say+m() ( say-color "$M1" "$@" )
say+c() ( say-color "$C1" "$@" )
say+w() ( say-color "$W1" "$@" )
