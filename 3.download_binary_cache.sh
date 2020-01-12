#!/usr/bin/env bash

function usage () {
    echo "Usage: $0 LOCAL_DIR"
}

if [ "X$1" = X ]; then
    usage
    exit 1
fi

dir=$(readlink -f "$1")

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

if [ ! -e "${target}.new" ]; then
    echo "previous step not complete, exit"
    exit 1
fi

echo "will download from '$remote_url' to '$target'"

cat "${target}.new" | xargs nix copy --from "$remote_url" --to "$url_new" || {
    echo "copy not success, please run this step again"
    exit 1
}

rm "${target}.new"

# done
date > "$target/.done"

# update store link
echo
echo "update last store symlink"
ln -nsf $(basename "$target") "${base}/store"
