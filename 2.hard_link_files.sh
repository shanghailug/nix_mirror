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

echo "hard link duplicate package from '${base}/store'"

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


    # here, assume ${old_store} not contain '|'
    comm $tmp1 $tmp2 -1 -2 | \
        xargs nix path-info -r --store "$url" 2>/dev/null | \
        sort | uniq | \
        sed -e 's|/nix/store/||' \
            -e 's/-.*/.narinfo/' \
            -e "s|^|${old_store}/|" > "${target}.list1"

    comm $tmp1 $tmp2 -2 -3 > "${target}.new"

    rm $tmp1 $tmp2

    xargs cat < "${target}.list1" | \
        fgrep "URL: " | \
        sort | uniq | \
        sed -e 's|.*nar/|nar/|' \
            -e "s|^|${old_store}/|" > "${target}.list2"

    total=$(wc -l < "${target}.list1")

    echo "total $total path common, curr time: `date -Iseconds`"

    mkdir -p "${target}/nar"

    echo "link nar.xz ..."

    time xargs cp -ln -t "${target}/nar" < "${target}.list2" || exit 1

    echo "link narinfo ..."

    time xargs cp -ln -t "${target}" < "${target}.list1" || exit 1

    rm "${target}.list1" "${target}.list2"

    echo "done, now `date -Iseconds`"
fi
