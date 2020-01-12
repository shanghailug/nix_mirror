#!/usr/bin/env bash

function usage () {
    echo "Usage: $0 NIX_CHANNEL_URL LOCAL_DIR"
}

url=$1
dir=$2

if [ "X$dir" = X ]; then
    usage
    exit 1
fi

echo "mirror nix channel '$url' to local dir '$dir'"

url1=$(curl -s -I https://nixos.org/channels/nixos-19.09 | \
           fgrep Location | sed -e 's/^.*http/http/' | tr -d '[:space:]')
echo "actual url is '${url1}'"

target="$dir/$(basename $url1)"

mkdir -p "$target"

if [ -e "$target/.done" ]; then
    echo "already done, exit"
    exit
fi

echo "$url1" > "${target}.todo"

# get files
for f in binary-cache-url \
             git-revision \
             nixexprs.tar.xz \
             src-url \
             store-paths.xz; do
    echo "downloading '$f'"
    wget -c --progress=dot "$url1/$f" -O "$target/$f"
done

date > "$target/.done"

rm "${target}.todo"
