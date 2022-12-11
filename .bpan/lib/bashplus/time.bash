# Get current time in epoch seconds
if [[ $EPOCHREALTIME != "$EPOCHREALTIME" ]]; then
  readonly EPOCHSECONDS
  +time:epoch() { echo "$EPOCHSECONDS"; }
else
  +time:epoch() { date +%s; }
fi

if ( shopt -s compat41 2>/dev/null ); then
  +time:stamp() { TZ=UTC printf '%(%Y-%m-%dT%H:%M:%S)T\n' -1; }
  +time:ymd() { TZ=UTC printf '%(%Y-%m-%d)T\n' -1; }
else
  +time:stamp() { TZ=UTC date '+%Y-%m-%dT%H:%M:%S'; }
  +time:ymd() { TZ=UTC date '+%Y-%m-%d'; }
fi
