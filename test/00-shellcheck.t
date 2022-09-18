#!/usr/bin/env bash

source test/init

+is-cmd-ver shellcheck 0.8.0 ||
  plan skip-all "Test requires shellcheck 0.8.0+ to be installed"

skip=1064,1072,1073,1090,1091,2002,2030,2031,2034,2154,2207,2217

while read -r file; do
  if [[ $file == *.bash ]] ||
     [[ $(head -n1 "$file") == \#*bash ]]
  then
    ok "$(shellcheck -s bash -e "$skip" "$file")" \
      "Bash file '$file' passes shellcheck"
  fi
done < <(
  find . -type f \
         -not -path '*/\.git/*' \
         -not -path '*/local/*' |
    grep -v '\.sw[op]' |
    grep -v '\.bpan/src/' |
    grep -v 'share/template/' |
    cut -c3- |
    LC_ALL=C +sort
)

done-testing
