#!/bin/bash
#
# bashrc common functions
#

# set alias cdd and cdhome , if not set.
if alias cdd 1>/dev/null 2>/dev/null ; then
    echo "alias cdd always defined. skip." > /dev/null
else
    alias cdd='cd $HOME/Desktop'
fi
if alias cdhome 1>/dev/null 2>/dev/null ; then
    echo "alias cdhome always defined. skip." > /dev/null
else
    alias cdhome='cd $HOME'
fi


# MSYS2特注
# /tmp に書き込み権限が無いので、ホームディレクトリの下に作る
export TMP=$HOME/tmp2
export TEMP=$TMP
export tmp=$TMP
export temp=$TMP
if [ ! -d $TMP ]; then
    mkdir -p $TMP
fi



# check tty (for Windows MSYS2)
function f-check-tty() {
    if type tty.exe  1>/dev/null 2>/dev/null ; then
        if type winpty.exe 1>/dev/null 2>/dev/null ; then
            local ttycheck=$( tty | grep "/dev/pt" )
            if [ ! -z "$ttycheck" ]; then
                return 0
            else
                return 1
            fi
        fi
    fi
    return 0
}


# bash 5.1 以降のブラケットペーストモードを off にする (テキストをペーストした後に選択モードとなり Enter 入力が余計に必要になるのを回避する)
# https://matoken.org/blog/2020/11/12/gnu-bash-bracketed-paste-settings/ GNU Bashのbracketed pasteの設定 matoken's meme
# test -t 1 で、端末につながっている場合はtrue

# if f-check-tty ; then
    # bind は、 bash が端末に接続している時しか利用できない。
    # キーバインド編集コマンドなので。
    # 端末に接続していない場合は警告が出る。
    # bind 'set enable-bracketed-paste off'
# fi

# ~/.inputrc が無い場合は作成
if [ ! -f ~/.inputrc ] ; then
    echo "set convert-meta off" >> ~/.inputrc
    echo "set meta-flag on" >> ~/.inputrc
    echo "set output-meta on" >> ~/.inputrc
    echo "set enable-bracketed-paste off" >> ~/.inputrc
fi




# set WINPTY_CMD environment variable when it need. (for Windows MSYS2)
function f-check-winpty() {
    if type tty.exe  1>/dev/null 2>/dev/null ; then
        if type winpty.exe 1>/dev/null 2>/dev/null ; then
            local ttycheck=$( tty | grep "/dev/pt" )
            if [ ! -z "$ttycheck" ]; then
                export WINPTY_CMD=winpty
                return 0
            else
                export WINPTY_CMD=
                return 0
            fi
        fi
    fi
    return 0
}

#
# MSYS2 黒魔術
#
# MSYS2では、実行するコマンドが Windows用のexeで、
# コマンドの引数が / からはじまったらファイル名だと思って C:\Program Files\ に変換をかける
# コマンドの引数がファイルならこれで良いのだが、 /C=JP/ST=Tokyo/L=Tokyo みたいなファイルではないパラメータに変換がかかると面倒
# ここでは、条件によってエスケープをかける
#
#   1. cmdがあって、/CがProgram Filesに変換されれば、Windows系 MSYS
#   1. / から始まる場合、MSYS
#
function f-msys-escape() {
    local args="$@"
    export MSYS_FLAG=

    # check cygwin
    if type uname 2>/dev/null 1>/dev/null ; then
        local result=$( uname -o )
        if [ x"$result"x = x"Cygwin"x ]; then
            MSYS_FLAG=
            # if not MSYS, normal return
            echo "$@"
            return 0
        fi
    fi

    # check Msys
    if type uname 2>/dev/null 1>/dev/null ; then
        local result=$( uname -o )
        if [ x"$result"x = x"Msys"x ]; then
            MSYS_FLAG=true
        fi
    fi

    # check cmd is found
    if type cmd 2>/dev/null 1>/dev/null ; then
        # check msys convert ( Git for Windows )
        local result=$( cmd //c echo "/CN=Name")
        if [ x"$result"x = x"/CN=Name"x ]; then
            MSYS_FLAG=
        else
            MSYS_FLAG=true
        fi
    fi

    # if not MSYS, normal return
    if [ x"$MSYS_FLAG"x = x""x ]; then
        echo "$@"
        return 0
    fi

    # if MSYS mode...
    # MSYSの場合、/から始まり、/の数が1個の場合は、先頭に / を加えれば望む結果が得られる
    # MSYSの場合、/から始まり、/の数が2個以上の場合は、先頭に // を加え、文中の / を \ に変換すれば望む結果が得られる (UNCファイル指定と誤認させる)
    local i=""
    for i in "$@"
    do
        # if argument starts with /
        local startWith=$( echo $i | awk '/^\// { print $0  }' )
        local slashCount=$( echo $i | awk '{ for ( i = 1 ; i < length($0) ; i++ ) { ch = substr($0,i,1) ; if (ch=="/") { count++; print count }  }  }' | wc -l )
        if [ -n "$startWith"  ]; then
            if [ $slashCount -eq 1 ]; then
                echo "/""$i"
            fi
            if [ $slashCount -gt 1 ]; then
                echo "//"$( echo $i | sed -e 's%^/%%g' -e 's%/%\\%g' )
            fi
        else
            echo "$i"
        fi
    done
}





# vagrant provider指定 (hyperv or virtualbox)
# 現在Hyper-Vが有効かどうかにしたがって環境変数VAGRANT_DEFAULT_PROVIDERを設定する
function f-hyperv-check() {
    if [ x"$VAGRANT_DEFAULT_PROVIDER"x = x""x ] ; then
        if type bcdedit 1>/dev/null 2>/dev/null ; then
            local RESULT=$( bcdedit $( f-msys-escape /enum ) | grep "hypervisorlaunchtype" )
            local RESULT2=$( echo $RESULT | grep "Auto" )
            local RESULT3=$( echo $RESULT | grep "Off" )
            if [ -n  "$RESULT2" ] ; then
                # echo "Hyper-V is ON"
                export VAGRANT_DEFAULT_PROVIDER="hyperv"
            fi
            if [ -n "$RESULT3" ] ; then
                # echo "Hyper-V is OFF"
                export VAGRANT_DEFAULT_PROVIDER="virtualbox"
            fi
        fi
    fi
}

# do hyper-v check
f-hyperv-check

# run git bash in other window
# 引数があればコマンドと見なして実行する
function f-git-bash() {

    # check os type
    # if type uname 1>/dev/null 2>/dev/null ; then
    #     RESULT=$( uname -o )
    #     if [ x"$RESULT"x = x"Cygwin"x ]; then
    #         echo "OS Type is not Cygwin. abort."
    #         return 1
    #     else
    #         echo "OS Type OK" > /dev/null
    #     fi
    # fi

    if [ $# -eq 0 ]; then
        # "/c/Program Files/Git/usr/bin/mintty.exe" --exec "/usr/bin/bash" --login -i &
        # "mintty.exe" --exec "/usr/bin/bash" --login -i &
        # "mintty.exe" --exec "/usr/bin/bash" &
        "mintty.exe" "/usr/bin/bash" &
    else
        # "/c/Program Files/Git/usr/bin/mintty.exe" --exec "/usr/bin/bash" "$@"
        # "mintty.exe" --hold always --exec "$@" &
        "mintty.exe" "/usr/bin/bash" -c "$@" &
    fi
}

# run msys bash in other window
# 引数があればコマンドと見なして実行する
function f-msys-bash() {

    export MSYS="nocase"
    export MSYS2_PATH_TYPE="inherit"
    export CHERE_INVOKING="enabled_from_arguments"

    # check os type
    # if type uname 1>/dev/null 2>/dev/null ; then
    #     RESULT=$( uname -o )
    #     if [ x"$RESULT"x = x"Cygwin"x ]; then
    #         echo "OS Type is not Cygwin. abort."
    #         return 1
    #     else
    #         echo "OS Type OK" > /dev/null
    #     fi
    # fi

    # check font height
    font_height="12"
    if [ -n "$F_MSYS_BASH_FONT_HEIGHT" ] ; then
        font_height="$F_MSYS_BASH_FONT_HEIGHT"
    fi

    # mintty config file 作成
    mintty_config_file="${HOME}/.minttyrc-utf8"
    echo "BoldAsFont=no" > $mintty_config_file
    echo "# Font=Ricty Diminished" >> $mintty_config_file
    echo "# Font=Cascadia Mono" >> $mintty_config_file
    echo "Font=Consolas" >> $mintty_config_file
    echo "FontHeight=$font_height" >> $mintty_config_file
    echo "Columns=120" >> $mintty_config_file
    echo "Rows=28" >> $mintty_config_file
    echo "RightClickAction=paste" >> $mintty_config_file
    echo "Transparency=low" >> $mintty_config_file
    echo "CursorType=block" >> $mintty_config_file
    echo "BackgroundColour=0,30,0" >> $mintty_config_file
    echo "Locale=ja_JP" >> $mintty_config_file
    echo "Charset=UTF-8" >> $mintty_config_file
    echo "Language=ja" >> $mintty_config_file
    echo "ForegroundColour=255,255,255" >> $mintty_config_file
    echo "CopyAsRTF=no" >> $mintty_config_file

    if [ $# -eq 0 ]; then
        # "/c/Program Files/Git/usr/bin/mintty.exe" --exec "/usr/bin/bash" --login -i &
        # "mintty.exe" --exec "/usr/bin/bash" --login -i &
        # "mintty.exe"  "/usr/bin/bash" &
        # インタラクティブに反応する bash を起動する
        "mintty.exe" --config $mintty_config_file --exec "/usr/bin/winpty" "/usr/bin/bash" "-i" &
    else
        # echo "まだ動かない；；"
        # "/c/Program Files/Git/usr/bin/mintty.exe" --exec "/usr/bin/bash" "$@"
        "mintty.exe" --config $mintty_config_file "/usr/bin/bash" -c "$@"
    fi
}

# run msys bash in other window
# 引数があればコマンドと見なして実行する
# sjisで起動する
# mintty の設定ファイルは、 /etc/minttyrc, $APPDATA/mintty/config, ~/.config/mintty/config, ~/.minttyrc, の順に検索する。
# ~/.minttyrc をコピーして、 .minttyrc-sjis を作成しておく。
function f-msys-bash-sjis() {

    export MSYS="nocase"
    export MSYS2_PATH_TYPE="inherit"
    export CHERE_INVOKING="enabled_from_arguments"

    # check os type
    # if type uname 1>/dev/null 2>/dev/null ; then
    #     RESULT=$( uname -o )
    #     if [ x"$RESULT"x = x"Cygwin"x ]; then
    #         echo "OS Type is not Cygwin. abort."
    #         return 1
    #     else
    #         echo "OS Type OK" > /dev/null
    #     fi
    # fi

    # check font height
    font_height="12"
    if [ -n "$F_MSYS_BASH_FONT_HEIGHT" ] ; then
        font_height="$F_MSYS_BASH_FONT_HEIGHT"
    fi

    # mintty config file 作成
    mintty_config_file="${HOME}/.minttyrc-sjis"
    echo "BoldAsFont=no" > $mintty_config_file
    echo "# Font=Ricty Diminished" >> $mintty_config_file
    echo "# Font=Cascadia Mono" >> $mintty_config_file
    echo "Font=Consolas" >> $mintty_config_file
    echo "FontHeight=$font_height" >> $mintty_config_file
    echo "Columns=120" >> $mintty_config_file
    echo "Rows=28" >> $mintty_config_file
    echo "RightClickAction=paste" >> $mintty_config_file
    echo "Transparency=low" >> $mintty_config_file
    echo "CursorType=block" >> $mintty_config_file
    echo "BackgroundColour=0,30,0" >> $mintty_config_file
    echo "Locale=ja_JP" >> $mintty_config_file
    echo "Charset=SJIS" >> "${mintty_config_file}"
    echo "Language=ja" >> $mintty_config_file
    echo "ForegroundColour=255,255,255" >> $mintty_config_file
    echo "CopyAsRTF=no" >> $mintty_config_file

    old_lang=${LANG}
    LANG="ja_JP.SJIS"
    export LANG
    if [ $# -eq 0 ]; then
        # "/c/Program Files/Git/usr/bin/mintty.exe" --exec "/usr/bin/bash" --login -i &
        # "mintty.exe" --exec "/usr/bin/bash" --login -i &
        "mintty.exe"  --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash" &
    else
        # echo "まだ動かない；；"
        # "/c/Program Files/Git/usr/bin/mintty.exe" --exec "/usr/bin/bash" "$@"
        "mintty.exe"  --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash" -c "$@" &
    fi
    LANG=${old_lang}
}

# run WSL bash in window
function f-wsl-bash-here() {
    if [ $# -eq 0 ]; then
        # "/c/Program Files/Git/usr/bin/mintty.exe" --exec "/usr/bin/bash" --login -i &
        # "mintty.exe" --exec "/usr/bin/bash" --login -i &
        winpty /c/windows/system32/bash.exe
        # winpty "/c/Program Files/WindowsApps/CanonicalGroupLimited.Ubuntu18.04onWindows_1804.2019.522.0_x64__79rhkp1fndgsc/ubuntu1804.exe"
    else
        echo "まだ動かない；；"
        # "/c/Program Files/Git/usr/bin/mintty.exe" --exec "/usr/bin/bash" "$@"
    fi
}

# コマンドライン引数をカンマ区切りに変換する
function f-conv-args-comma() {
    local cmd_args=
    local i=
    for i in "$@"
    do
        if [ -n "$cmd_args" ]; then
            cmd_args="${cmd_args},"
        fi
        cmd_args="${cmd_args}${i}"
    done
    echo $cmd_args
}

# run powershell in other window
function f-powershell() {
    if [ $# -eq 0 ]; then
        start powershell.exe
    elif [ $# -eq 1 ]; then
        local cmd_file=$1
        start powershell "Start-Process $cmd_file"
    else
        local cmd_file=$1
        shift
        local cmd_args=$( f-conv-args-comma "$@" )
        start powershell "Start-Process $cmd_file -ArgumentList $cmd_args"
    fi
}

# run powershell in other window
function f-sudo-powershell() {
    if [ $# -eq 0 ] ; then
        # echo "管理者権限を得るため、bashから通常権限のPowerShellを起動して、そこから管理者権限のPowerShellを起動する"
        powershell "Start-Process -Verb runas powershell"
        # powershell "Start-Process -Verb runas -PassThru powershell.exe"
        # start powershell -NoExit "Start-Process -Verb runas -PassThru powershell.exe"
    elif [ $# -eq 1 ]; then
        local cmd_file=$1
        start powershell "Start-Process $cmd_file -Verb runas"
    else
        local cmd_file=$1
        shift
        local cmd_args=$( f-conv-args-comma "$@" )
        start powershell "Start-Process $cmd_file -Verb runas -ArgumentList $cmd_args"
    fi
}

function f-windows-terminal() {
    if [ $# -eq 0 ] ; then
        powershell start-process wt
    else
        # 引数はカンマ区切りとする
        cmd_args=$( f-conv-args-comma "$@" )
        powershell start-process wt -ArgumentList "--startingDirectory","$PWD","$cmd_args"
    fi
}

function f-sudo-windows-terminal() {
    if [ $# -eq 0 ] ; then
        powershell start-process wt -ArgumentList "--startingDirectory","$PWD" -verb runas
    else
        # 引数はカンマ区切りとする
        cmd_args=$( f-conv-args-comma "$@" )
        powershell start-process wt -ArgumentList "--startingDirectory","$PWD","$cmd_args" -verb runas
    fi
}

# run powershell in other window
function f-pwsh() {
    if [ $# -eq 0 ]; then
        start pwsh.exe
    else
        echo "まだ動かない；；"
        # start powershell.exe -NoExit "$@"
    fi
}

# run powershell in other window
function f-sudo-pwsh() {
    if [ $# -eq 0 ] ; then
        echo "管理者権限を得るため、bashから通常権限のPowerShellを起動して、そこから管理者権限のPowerShellを起動する...まだ動かない"
        start pwsh.exe -NoExit "Start-Process -Verb runas -PassThru pwsh.exe"
    else
        echo "まだ動かない；；"
        # start powershell.exe -NoExit "Start-Process -Verb runas -PassThru -ArgumentList $@"
    fi
}

# cygwinのbashを別ウィンドウで起動する
# MSYS2からは、cygwinなバイナリを起動できない模様；；
function f-cygwin-bash {

    # check os type
    # if type uname 1>/dev/null 2>/dev/null ; then
    #     RESULT=$( uname -o )
    #     if [ x"$RESULT"x = x"Cygwin"x ]; then
    #         echo "OS Type OK" > /dev/null
    #     else
    #         echo "OS Type is not Cygwin. abort."
    #         return 1
    #     fi
    # fi

    if [ $# -eq 0 ]; then
        # f-path-remove-cygwin1
        # f-path-prepend /c/tools/cygwin/bin
        # mintty.exe -i /Cygwin-Terminal.ico  --exec /usr/bin/bash --login -i &
        mintty.exe  --exec /usr/bin/bash &
    else
        # mintty.exe -i /Cygwin-Terminal.ico  --hold always --exec "$@" &
        mintty.exe   --hold always --exec "$@" &
    fi
}

# afxwを別ウィンドウで起動する
# 起動中のafxw画面を使う場合は -s オプションを追加すること
function f-afxw() {
    AFXW.EXE -L"$PWD\\" -R"$PWD\\" &
}

#
# ファイルがテキストかどうか判定する。 0 ならテキスト。
#
function f_is_text_file() {
    local file=$1
    local fileType=$( file -i -b $file )
    local bText=false
    if echo $fileType | grep text/plain > /dev/null ; then
        return 0
    elif echo $fileType | grep text/x-shellscript > /dev/null ; then
        return 0
    elif echo $fileType | grep text/html > /dev/null ; then
        return 0
    fi
    return 1
}

# PATHに追加する。
# 既にある場合は何もしない。
function f-path-add() {
    local addpath="$1"
    if [ -z "$addpath" ]; then
        echo "f-path-add  path"
        return 0
    fi
    if [ ! -d "$addpath" ]; then
        echo "not a directory : $addpath"
        return 1
    fi
    local result=$( echo "$PATH" | sed -e 's/:/\n/g' | awk -v va="$addpath" '{ if ( $0 == va ) { print $0 } }' )
    if [ -z "$result" ]; then
        export PATH="$PATH:$addpath"
        # echo "PATH add $addpath"
    fi
}

# PATHの先頭に追加する。
# 既にある場合は消してから先頭に追加する
function f-path-prepend() {
    local addpath="$1"
    if [ -z "$addpath" ]; then
        echo "f-path-add  path"
        return 0
    fi
    if [ ! -d "$addpath" ]; then
        echo "not a directory : $addpath"
        return 1
    fi
    local result=$( echo "$PATH" | sed -e 's/:/\n/g' | awk -v va="$addpath" '{ if ( $0 == va ) { print $0 } }' )
    if [ -z "$result" ]; then
        export PATH="$addpath:$PATH"
    else
        f-path-remove "$addpath"
        export PATH="$addpath:$PATH"
    fi
}

# PATHから削除する。
# ない場合は何もしない。
function f-path-remove() {
    local removepath="$1"
    local resultpath=
    if [ -z "$removepath" ]; then
        echo "f-path-remove  path"
        return 0
    fi
    local tempfile=$(  mktemp  $TMP/f-path-remove-XXXXXXXX.tmp )
    echo "$PATH" | sed -e 's/:/\n/g' | while read ans
    do
        if [ x"$ans"x = x"$removepath"x ]; then
            # echo "remove PATH ... $removepath"
            continue
        fi
        echo "$ans" >> $tempfile
    done
    resultpath=$( cat $tempfile | sed -e 's/*/-/g' | tr '\n' ':' )
    resultpath=$( echo $resultpath | sed -e 's/:$//g' )
    /bin/rm $tempfile
    if [ -n "$resultpath" ]; then
        PATH=$resultpath
        export PATH
    fi
}

# cygwin1.dllがあるPATHをPATHから削除する。
# ない場合は何もしない。
function f-path-remove-cygwin1() {
    local removecmd="$1"
    local resultpath=
    if [ -z "$removecmd" ]; then
        removecmd=cygwin1.dll
    fi
    local tempfile=$(  mktemp  $TMP/f-path-remove-XXXXXXXX.tmp )
    echo "$PATH" | sed -e 's/:/\n/g' | while read ans
    do
        # ディレクトリがある
        if [ -d "$ans" ] ; then
            # コマンドがある
            if [ -x "$ans/$removecmd" ] ; then
                # echo "remove PATH ... $ans"
                continue
            fi
        fi
        echo "$ans" >> $tempfile
    done
    resultpath=$( cat $tempfile | sed -e 's/*/-/g' | tr '\n' ':' )
    resultpath=$( echo $resultpath | sed -e 's/:$//g' )
    /bin/rm $tempfile
    if [ -n "$resultpath" ]; then
        PATH="$resultpath"
        export PATH
    fi
}

function f-path-show() {
    echo $PATH | sed -e 's/:/\n/g'
}

#
# ランダム生成
#

# 第一引数の文字列から第二引数の回数だけランダムに文字を選択して表示する
function f-random-select() {
    source="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"  # 任意の文字列をここに指定
    length=16
    result=""
    if [ $# -ge 1 ] ; then
        source=$1
    fi
    if [ $# -ge 2 ] ; then
        length=$2
    fi

    for ((i = 0; i < length; i++));
    do
        rand_index=$((RANDOM % ${#source}))
        result+="${source:$rand_index:1}"
    done

    echo "$result"
}



# ランダム文字列を生成する
# O と 0 と o は除外
# 1 と l は除外
# 8 と B は除外
# ACDEFGHIJKLMNPQRSTUVWXYZ
# abcdefghijkmnpqrstuvwxyz
# 2345679
function f-random-string-generate() {
    FROM1_STR=""
    FROM1_STR="${FROM1_STR}ACDEFGHIJKLMNPQRSTUVWXYZ"
    FROM2_STR=""
    FROM2_STR="${FROM2_STR}abcdefghijkmnpqrstuvwxyz"
    FROM3_STR=""
    FROM3_STR="${FROM3_STR}2345679"
    FROM4_STR=""
    FROM4_STR="${FROM4_STR}${FROM1_STR}"
    FROM4_STR="${FROM4_STR}${FROM2_STR}"
    FROM4_STR="${FROM4_STR}${FROM3_STR}"
    result=""
    # ランダムに16文字を選択
    result="$result$( f-random-select $FROM2_STR 2 )"
    result="$result$( f-random-select $FROM1_STR 2 )"
    result="$result$( f-random-select $FROM2_STR 4 )"
    result="$result$( f-random-select $FROM3_STR 4 )"
    result="$result$( f-random-select $FROM4_STR 16 )"
    echo $result
}



#
# azure cli 設定
#

# az cli 用にPATHを編集する
function f-az-path-init() {
    # Python38のPATHを末尾に移動する。azコマンドがgit for windowsで動かなくなるので。
    for i in /c/Python38/Scripts /c/Python38
    do
        if [ -d $i ] ; then
            echo "hoge"
            # f-path-remove $i
            # f-path-add $i
        fi
    done
    # Azure CLI をPATHの先頭に移動する
    for i in "/c/Program Files (x86)/Microsoft SDKs/Azure/CLI2/wbin"  "/c/Program Files (x86)/Microsoft SDKs/Azure/CLI2"  "/c/Program Files (x86)/Microsoft SDKs/Azure/CLI2/Scripts"
    do
        if [ -d "$i" ] ; then
            echo "hoge"
            # f-path-remove "$i"
            # f-path-prepend "$i"
        fi
    done
    export PYTHONPATH=

}

# Git Bash for Windowsの場合は、azシェルスクリプトを実行しない
# MSYSの場合はパスを設定する。wbinを先頭に設定すると、az.cmdとかaz(bash shell)が使える。
function f-az-init() {
    f-path-prepend "/c/Program Files (x86)/Microsoft SDKs/Azure/CLI2"
    f-path-prepend "/c/Program Files (x86)/Microsoft SDKs/Azure/CLI2/Scripts"
    f-path-prepend "/c/Program Files (x86)/Microsoft SDKs/Azure/CLI2/wbin"
}

# no_proxyに追加する。
# 既にある場合は何もしない。
# no_proxyが全く設定されていない場合は、何もしない。おそらくproxyが必要な環境ではない。
function f-no-proxy-add() {
    local addpath=$1
    if [ -z "$addpath" ]; then
        echo "f-no-proxy-add  no-proxy-host"
        return 0
    fi
    # no_proxyが全く設定されていない場合は、何もしない
    if [ -z "$no_proxy" ]; then
        return 0
    fi
    local result=$( echo "$no_proxy" | sed -e 's/,/\n/g' | awk -v va=$addpath '{ if ( $0 == va ) { print $0 } }' )
    if [ -z "$result" ]; then
        export no_proxy="$no_proxy,$addpath"
        echo "no_proxy add $addpath"
    fi
}

# proxy環境変数を全部クリアする
function f-proxy-clear() {
    export http_proxy=
    export https_proxy=
    export no_proxy=
    export HTTP_PROXY=
    export HTTPS_PROXY=
    export NO_PROXY=
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset NO_PROXY
    unset http_proxy
    unset https_proxy
    unset no_proxy
}

# バックアップファイル作成 or diff
function f-backup-file-or-diff() {
    local FILE=$1
    local FILE_BAK=$1.20190315_1457_obama
    if [ ! -r $FILE ]; then
        echo "FILE $FILE is not readable. abort."
        return 1
    fi
    if [ -r $FILE_BAK ]; then
        echo "FILE $FILE_BAK found. "
        diff -uw $FILE_BAK $FILE
    else
        echo "FILE $FILE backup."
        /bin/cp -p $FILE $FILE_BAK
    fi
}

# Windows CPU 負荷が30%以下で安定するのを待つ
function f-windows-wait-cpu-ready() {
    local cpu_rate=30
    local num_count=10
    local sumaveawk=$( mktemp $TMP/sumave-XXXXXXXXXX.awk )
    local outputfile=$( mktemp $TMP/output-XXXXXXXXXX.csv )
    local result=

cat > $sumaveawk << "EOF"
BEGIN { SUM=0 ; CNT=0 }
{ SUM = SUM + $1 ; CNT++ }
END { AVE=SUM/CNT ; if ( AVE > AVELEVEL ) { print "BUSY " "AVE:" AVE " AVELEVEL:" AVELEVEL } else { print "OK" } }
EOF

    while true
    do
        /bin/rm -f $outputfile
        echo "waiting for typeperf.exe $num_count seconds..."
        typeperf.exe  -sc $(( num_count + 2 )) -o $outputfile  "\processor(_total)\% processor time"  1>/dev/null  2>/dev/null
        result=$( cat $outputfile | tail -n $num_count | awk -F , '{print $2}' | sed -e 's/"//g' | awk -v AVELEVEL=$cpu_rate -f $sumaveawk )
        echo $(date) " result is " $result
        if [ x"$result"x = x"OK"x ]; then
            echo "CPU ready"
            break
        else
            cat $outputfile
            sleep 5
        fi
    done
    /bin/rm -f $sumaveawk $outputfile
}

# すぐに再起動する
function f-shutdown-r-now() {
    f-vagrant-poweroff-all
    shutdown.exe -r -t 5 -f
}

# すぐにシャットダウンする
function f-shutdown-h-now() {
    f-vagrant-poweroff-all
    shutdown.exe -s -t 5 -f
}

# 6時間後にシャットダウンする
function f-shutdown-h-6-hours() {
    f-vagrant-poweroff-all
    shutdown.exe -s -t 21600 -f
}




#
# テスト用ディレクトリに移動
#
function cdtest1() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test1/test1
            cd test1/test1
        fi
    fi
}

function cdtest2() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test2/test2
            cd test2/test2
        fi
    fi
}

function cdtest3() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test3/test3
            cd test3/test3
        fi
    fi
}

function cdtest4() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test4/test4
            cd test4/test4
        fi
    fi
}

function cdtest5() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test5/test5
            cd test5/test5
        fi
    fi
}

function cdtest6() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test6/test6
            cd test6/test6
        fi
    fi
}

function cdtest7() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test7/test7
            cd test7/test7
        fi
    fi
}

function cdtest8() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test8/test8
            cd test8/test8
        fi
    fi
}

function cdtest9() {
    if [ ! -z "$GIT_BASE_DIR" ] ; then
        if [ -d "$GIT_BASE_DIR" ] ; then
            cd $GIT_BASE_DIR
            mkdir -p test9/test9
            cd test9/test9
        fi
    fi
}

function hexdump() {
    if [ $# -eq 0 ]; then
        echo "hexdump filename"
        return 0
    fi
    od -tx1z -Ax  "$@"
}

# 自分のPCのIPアドレスを得る。第一引数に "イーサネット" をとる。
function f-get-ipv4() {
    name="$1"
    if type netsh 1>/dev/null 2>/dev/null ; then
        netsh interface ipv4 show address $name | grep -a IP | awk '{print $3}'
    fi
}

# 環境変数 DEFAULT_IPV4_ADDR の設定
if [ -z "$DEFAULT_IPV4_ADDR" ] ; then
    ipv4addr=$( f-get-ipv4 "イーサネット" )
    if [ -z "$ipv4addr" ] ; then
        ipv4addr=$( f-get-ipv4 "Wi-Fi" )
    fi
    if [ -z "$ipv4addr" ] ; then
        ipv4addr=$( f-get-ipv4 "Wi-Fi 2" )
    fi
    if [ -z "$ipv4addr" ] ; then
        export DEFAULT_IPV4_ADDR=
        # echo "Can not Get IPv4 Address"
    else
        export DEFAULT_IPV4_ADDR=$ipv4addr
        # echo "DEFAULT_IPV4_ADDR=$DEFAULT_IPV4_ADDR"
    fi
fi

# 環境変数DISPLAY設定
if [ -z "$DISPLAY" ] ; then
    if [ -z "$DEFAULT_IPV4_ADDR" ] ; then
        export DISPLAY=$( hostname ):0.0
    else
        export DISPLAY=$DEFAULT_IPV4_ADDR:0.0
    fi
fi

# add bash.exe and mintty.exe path ( Git for Windows )
if [ -d "/C/Program Files/Git/bin" ] ; then
    f-path-add "/C/Program Files/Git/bin"
    f-path-add "/C/Program Files/Git/usr/bin"
fi

# add VcXsrv path
if [ -d "/C/Program Files/VcXsrv" ] ; then
    f-path-add "/C/Program Files/VcXsrv"
fi

# add mytools path
if [ -n "$GIT_GEORGE_PON_DIR" ] ; then
    if [ -d "$GIT_GEORGE_PON_DIR/mytools" ] ; then
        f-path-add "$GIT_GEORGE_PON_DIR/mytools"
    fi
fi

# add myopenrepo path
if [ -n "$GIT_GEORGE_PON_DIR" ] ; then
    if [ -d "$GIT_GEORGE_PON_DIR/myopenrepo" ] ; then
        f-path-add "$GIT_GEORGE_PON_DIR/myopenrepo"
    fi
fi

# see tomcat log
function f-tomcat-log-less() {
    TODAY=$( date "+%Y-%m-%d" )
    LOGFILE="/c/Program Files/Apache Software Foundation/Tomcat 10.1/logs/catalina.${TODAY}.log"
    less -F "$LOGFILE"
}

# see tomcat log
function f-tomcat-log-tail() {
    TODAY=$( date "+%Y-%m-%d" )
    LOGFILE="/c/Program Files/Apache Software Foundation/Tomcat 10.1/logs/catalina.${TODAY}.log"
    tail -f "$LOGFILE"
}

# kjwikigdocker.war ファイルの dataStorePath を書き換えて tomcat ディレクトリにコピーする
function f-kjwikigdocker-edit-war() {
    if [ ! -f kjwikigdocker.war ] ; then
        echo "file not found. kjwikigdocker.war"
        return 1
    fi

    cp kjwikigdocker.war kjwikigdocker.zip
    mkdir -p tmpwork
    pushd tmpwork
    unzip ../kjwikigdocker.zip WEB-INF/classes/kjwikig.properties
    sed -i -e 's%authenticationMode=AuthenticationModeMay%authenticationMode=AuthenticationModeMust%g' ./WEB-INF/classes/kjwikig.properties
    sed -i -e 's%dataStorePath=/var/lib/kjwikigdocker%dataStorePath=C:\\\\var\\\\lib\\\\kjwikigdocker%g' ./WEB-INF/classes/kjwikig.properties
    zip -u ../kjwikigdocker.zip ./WEB-INF/classes/kjwikig.properties
    popd

    cp kjwikigdocker.zip "/c/Program Files/Apache Software Foundation/Tomcat 10.1/webapps/kjwikigdocker.war"

    /bin/rm -rf tmpwork kjwikigdocker.zip

}


#
# edge 操作
#
function f-edge-prof-n() {
    a1=1
    if [ $# -gt 0 ] ; then
        a1=$1
        shift
    fi
    a2=
    if [ $# -gt 0 ] ; then
        a2=$1
        shift
    fi
    # プロファイルディレクトリ  C:\Users\xxxx\AppData\Local\Microsoft\Edge\User Data\Profile 1
    cd "/c/Program Files (x86)/Microsoft/Edge/Application"
    ./msedge.exe --profile-directory="Profile $a1" $a2
}

function f-edge-default() {
    cd "/c/Program Files (x86)/Microsoft/Edge/Application"
    ./msedge.exe --profile-directory=Default
}

# プロファイルの一覧を表示
function f-edge-profile-list() {
    cd ~
    cd "./AppData/Local/Microsoft/Edge/User Data/"

    for i in $( seq 1 25 )
    do
        prof_dir="Profile $i"
        if [ -d "$prof_dir" ] ; then
            prof_file="$prof_dir/Preferences"
            if [ -f "$prof_file" ] ; then
                prof_name=$( cat "$prof_file" | jq ".profile.name" )
                echo "$prof_file : $prof_name"
            fi
        fi
    done
}


# vagrant用のディレクトリ位置を特定する
# SSD用の特殊位置があるため
if [ -d /C/HOMESSD/git/george-pon/vagrant ] ; then
    export VAGRANT_BASE_DIR=/C/HOMESSD/git/george-pon/vagrant
elif [ -d /D/HOME/git/george-pon/vagrant ] ; then
    export VAGRANT_BASE_DIR=/D/HOME/git/george-pon/vagrant
fi


function f-sakura-memo() {
    NEW_MEMO_APPEND=""
    while [ $# -gt 0 ]
    do
        arg1="$1"
        shift
        if [ x"$arg1"x = x"-n"x ] ; then
            NEW_MEMO_APPEND="_$1"
            shift
        fi
    done
    NEW_MEMO_FILE=$(date +%Y%m%d_%H%M%S)
    NEW_MEMO_FILE="$PERSONAL_BASE_DIR/Memo_${NEW_MEMO_FILE}${NEW_MEMO_APPEND}.txt"
    sakura.exe "$NEW_MEMO_FILE" &
}

function f-code-memo() {
    NEW_MEMO_APPEND=""
    while [ $# -gt 0 ]
    do
        arg1="$1"
        shift
        if [ x"$arg1"x = x"-n"x ] ; then
            NEW_MEMO_APPEND="_$1"
            shift
        fi
    done
    NEW_MEMO_FILE=$(date +%Y%m%d_%H%M%S)
    NEW_MEMO_FILE="$PERSONAL_BASE_DIR/Memo_${NEW_MEMO_FILE}${NEW_MEMO_APPEND}.txt"
    code "$NEW_MEMO_FILE" &
}

#
# end of file
#

