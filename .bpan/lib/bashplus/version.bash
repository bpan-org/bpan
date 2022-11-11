# Check if first x.x.x version is greater than the second.
+version:ge() {
  local v1 v2
  IFS=. read -r -a v1 <<<"$1"
  IFS=. read -r -a v2 <<<"$2"

  (( v1[0] > v2[0] ||
    (( v1[0] == v2[0] &&
      (( v1[1] > v2[1] ||
        (( v1[1] == v2[1] && v1[2] >= v2[2] ))
      ))
    ))
  ))
}

# Check if first x.x.x version is greater than the second.
+version:gt() {
  local v1 v2
  IFS=. read -r -a v1 <<<"$1"
  IFS=. read -r -a v2 <<<"$2"

  (( v1[0] > v2[0] )) ||
  (( v1[1] > v2[1] )) ||
  (( v1[2] > v2[2] ))
}
