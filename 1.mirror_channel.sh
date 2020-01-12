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
for f in store-paths.xz \
             nixexprs.tar.xz \
             binary-cache-url \
             git-revision \
             src-url; do
    echo "downloading '$f'"
    wget -c --progress=dot "$url1/$f" -O "$target/$f" || exit 1
done

date > "$target/.done"

ln -sfn "$target" "${dir}/channel"

rm "${target}.todo"
