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
    echo "use local store '$old_store'"

    url="file://$old_store"

    function dup_path {
        p=$1

        nix path-info --store "$url" $p >/dev/null 2>/dev/null && {
            # valid package
            if nix path-info -r --store "$url_new" $p >/dev/null 2>/dev/null; then
                echo "SKIP: $p"
            else
                n=0
                for i in `nix path-info -r --store "$url" $p`; do
                    hsh=$(basename $i | sed -e 's/-.*//')

                    info_r="${hsh}.narinfo"
                    info="${old_store}/$info_r"
                    info_t="${target}/$info_r"

                    nar_r=$(cat "$info" | fgrep "URL: " | sed -e 's|.*nar/|nar/|')
                    nar="${old_store}/${nar_r}"
                    nar_t="${target}/${nar_r}"

                    [ -e "$info_t" ] || ln "$info" "$info_t"
                    [ -e "$nar_t" ]  || ln "$nar"  "$nar_t"

                    n=$(expr $n + 1)
                done

                printf "DONE: %5d " $n
                echo "$p"
            fi
        }
    }

    for p in `xzcat "$dir/store-paths.xz"`; do
        dup_path $p
    done
fi

echo
echo "2. download remain package from $remote_url"

xzcat store-paths.xz | xargs nix copy --from "$remote_url" --to "$url_new"

# done
date > "$target/.done"

# update store link
echo
echo "update last store symlink"
ln -sF $(basename "$target") "${base}/store"
