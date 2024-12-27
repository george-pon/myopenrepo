#!/bin/bash
#
# ファイルサイズの大きいファイル上位５個を表示する
#
function f-biggest-file-n() {
    if [ x"$1"x = x""x ]; then
        NUM=15
    else
        NUM=$1
    fi

    find . -type f -printf "%s  %h/%f \n" | sort -r -n | head -n ${NUM}
}
f-biggest-file-n "$@"
# end of file
