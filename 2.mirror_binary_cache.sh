#!/usr/bin/env bash

function usage () {
    echo "Usage: $0 LOCAL_DIR"
}

dir=$1

if [ "X$dir" = X ]; then
    usage
    exit 1
fi

if [ ! -e "$dir/.done" ]; then
    echo "nix channel mirror '$dir' is not complete"
    exit 1
fi

remote_url=$(cat "$dir/binary-cache-url")
target="${dir}.store"
url_new="file://$target"

base=$(dirname $dir)

mkdir -p "$target"
mkdir -p "$target/nar"

if [ -e "$target/.done" ]; then
    echo "already done, exit"
    exit
fi

echo "will download from '$remote_url' to '$target'"

echo
echo "1. hard link duplicate package from '${base}/store'"

if [ ! -e "${base}/store" ]; then
    echo "last local store not available, skip this step"
else
    old_store=$(readlink -f "${base}/store")
    old_dir=${old_store%.store}

    echo "use local store '$old_store'"

    url="file://$old_store"

    tmp1=`mktemp`
    tmp2=`mktemp`

    xzcat "$dir/store-paths.xz" > $tmp1
    xzcat "$old_dir/store-paths.xz" > $tmp2

    comm $tmp1 $tmp2 -1 -2 | \
        xargs nix path-info -r --store "$url" 2>/dev/null | \
        sort | uniq > "${target}.comm"

    comm $tmp1 $tmp2 -2 -3 > "${target}.new"

    rm $tmp1 $tmp2

    function dup_path {
        i=$1

        hsh=$(basename $i | sed -e 's/-.*//')

        info_r="${hsh}.narinfo"
        info="${old_store}/$info_r"
        info_t="${target}/$info_r"

        nar_r=$(cat "$info" | fgrep "URL: " | sed -e 's|.*nar/|nar/|')
        nar="${old_store}/${nar_r}"
        nar_t="${target}/${nar_r}"

        # link nar first
        {
            [ -e "$nar_t" ]  || ln "$nar"  "$nar_t"
        } && {
            [ -e "$info_t" ] || ln "$info" "$info_t"
        }
    }

    n=0
    m=0
    total=$(wc -l < "${target}.comm")

    echo "total $total path common, curr time: `date -Iseconds`"

    for p in `cat "${target}.comm"`; do
        dup_path $p

        n=$(($n + 1))
        m=$(($m + 1))
        if [ "X$m" = X1000 ]; then
            echo "... $n / $total, path=$p"
            m=0
        fi
    done

    echo "done, now `date -Iseconds`"

    rm "${target}.comm"
fi

echo
echo "2. download remain package from $remote_url"

cat "${target}.new" | xargs nix copy --from "$remote_url" --to "$url_new"

echo "done, now `date -Iseconds`"

# done
date > "$target/.done"

# update store link
echo
echo "update last store symlink"
ln -sF $(basename "$target") "${base}/store"
