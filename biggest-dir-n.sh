#!/bin/bash
#
# ディレクトリサイズの大きいもの上位５個を表示する
#
function f-biggest-dir-n() {
    if [ x"$1"x = x""x ]; then
        NUM=15
    else
        NUM=$1
    fi

    find . -type d | \
    while read i
    do
        du -sk "$i"
    done | sort -r -n | head -n ${NUM}
}
f-biggest-dir-n "$@"
# end of file
