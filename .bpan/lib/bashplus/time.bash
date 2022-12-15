# Get current time in epoch seconds
if [[ $EPOCHREALTIME != "$EPOCHREALTIME" ]]; then
  readonly EPOCHSECONDS
  +time:epoch() { echo "$EPOCHSECONDS"; }
else
  +time:epoch() { date +%s; }
fi

if ( shopt -s compat41 2>/dev/null ); then
  +time:stamp() { printf '%(%Y-%m-%dT%H:%M:%SZ)T\n' -1; }
  +time:ymd() { printf '%(%Y-%m-%d)T\n' -1; }
else
  +time:stamp() { date '+%Y-%m-%dT%H:%M:%SZ'; }
  +time:ymd() { date '+%Y-%m-%d'; }
fi
