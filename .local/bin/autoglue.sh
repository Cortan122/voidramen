#!/bin/sh

theNumber="$#"
while [ `factor $theNumber | tr -dc ' ' | wc -c` = 1 ]; do
  theNumber=`jq -n "$theNumber+1"`
done
desiredRatio="$(jq -n "(16/9)/($(identify -format '%w/%h\n' "$1"))")"
pairs="$(
python - $theNumber <<EOF
import sys
n = int(sys.argv[1])

for i in range(1, int(pow(n, 1 / 2))+1):
  if n % i == 0:
    print([i,n//i])
EOF
)"
cols="$(echo "$pairs" | jq -s '
  map(
    reverse | [
      ((.[0]/.[1] | log)-($dr | log) | fabs),
      .[0]
    ]
  ) | sort_by(.[0]) | .[0][1]
' --argjson dr $desiredRatio)"

glue.sh $cols "$@"
