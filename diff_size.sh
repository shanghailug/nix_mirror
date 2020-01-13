#!/usr/bin/env bash

store=$1
from1=$2
to1=$3

function usage {
    echo "$0 STORE_URL FROM_CHANNEL TO_CHNNEL"
}

if [ "X$to1" = X ]; then
    usage
    exit 1
fi

to=$(readlink -f $to1)
from=$(readlink -f $from1)

tmp1="${from}.list"
tmp2="${to}.list"
tmp3="${to}.new"

echo "find full list for '$from', now: `date`"

xzcat "$from/store-paths.xz" | xargs nix path-info -r --store "$store" | \
    sort | uniq > $tmp1

echo "find full list for '$to', now: `date`"

xzcat "$to/store-paths.xz" | xargs nix path-info -r --store "$store" | \
    sort | uniq > $tmp2

echo "done, now: `date`"

comm -1 -3 $tmp1 $tmp2 > $tmp3

rm $tmp1

cat $tmp3 | xargs nix path-info \
                  --json  \
                  --store "$store" | \
    jq -r '.[] | (.url + "," + (.narSize | tostring) + "," + (.downloadSize | tostring))' | \
    sort | uniq > $tmp2

nsize=$(cut -d ',' -f 2 < $tmp2 | paste -sd+ | bc)
dsize=$(cut -d ',' -f 3 < $tmp2 | paste -sd+ | bc)

ln=$(wc -l < "$tmp2")
echo "total nar number is $ln"
echo "nar size is $(($nsize / 1024 /1024))M"
echo "download size is $(($dsize / 1024 / 1024))M"

rm $tmp2 $tmp3
