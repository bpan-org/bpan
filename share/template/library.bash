[% name %]:version() ( echo '0.0.0' )

[% name %]:main() (
  echo "Hello ${1:-world}!"
)
