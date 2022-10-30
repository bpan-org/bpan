# Get current time in epoch seconds
if [[ $EPOCHREALTIME != "$EPOCHREALTIME" ]]; then
  readonly EPOCHSECONDS
  +time:epoch() ( echo "$EPOCHSECONDS" )
else
  +time:epoch() ( date +%s )
fi
