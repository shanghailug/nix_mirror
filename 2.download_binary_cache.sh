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

base=$(dirname $dir)

remote_url=$(cat "$dir/binary-cache-url")
target="${base}/store"

url_new="file://$target"

mkdir -p "$target"
mkdir -p "$target/nar"

echo "will download from '$remote_url' to '$target'"

xzcat "${dir}/store-paths.xz" | xargs nix copy --from "$remote_url" --to "$url_new" || {
    echo "copy not success, please run this step again"
    exit 1
}
