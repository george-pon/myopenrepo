#!/bin/bash
#
#  ~/.bashrcの設定サンプル(UTF-8)(LF)
#

# プロンプト
PS1='MSYS2 \u@\h \w $ '

# docker host を固定指定する
# export DOCKER_HOST=tcp://192.168.33.10:2375
# export DOCKER_HOST=tcp://192.168.12.10:2375
# export DOCKER_HOST=ssh://vagrant@master1
# export DOCKER_HOST=tcp://192.168.72.76:2375
# export DOCKER_HOST=tcp://192.168.80.80:2375
# export DOCKER_HOST=tcp://debian81:2375
# export DOCKER_HOST=ssh://debian81

# 環境変数DISPLAYを適当に設定する
if [ -z "$DISPLAY" ] ; then
    hostname=$( hostname )
    DISPLAY=${hostname}:0.0
    export DISPLAY
fi

# 言語
if [ -z "$LANG" ] ; then
    LANG=ja_JP.UTF-8
    export LANG
fi

# TERM
export TERM=xterm-256color

# Use case-insensitive filename globbing
# shopt -s nocaseglob

# 個人のベースディレクトリ
if [ -d "$HOME/Desktop/obama" ] ; then
    export PERSONAL_BASE_DIR="$HOME/Desktop/obama"
elif [ -d "/c/HOME" ] ; then
    export PERSONAL_BASE_DIR="/c/HOME"
fi

# GITのベースディレクトリ
checkGitBase="${PERSONAL_BASE_DIR}/git"
if [ -d "$checkGitBase" ] ; then
    GIT_BASE_DIR="$checkGitBase"
    export GIT_BASE_DIR
fi

# GITのオレ専用ベースディレクトリ
if [ -d "$GIT_BASE_DIR/george-pon" ] ; then
    GIT_MY_DIR="$GIT_BASE_DIR/george-pon"
    export GIT_MY_DIR
    GIT_GEORGE_PON_DIR="$GIT_BASE_DIR/george-pon"
    export GIT_GEORGE_PON_DIR
fi

# オレ専用ディレクトリ移動エイリアス
alias cdd='cd $HOME/Desktop'
alias cdhome='cd $HOME'
alias cdgitmy='cd "$GIT_MY_DIR"'
alias cdgit='cd "$GIT_BASE_DIR"'
alias cdgitsub='cd /c/homesub/git'

# vagrant ディレクトリは SSD 特例の例外がある
# alias cdvagrant='cd $GIT_GEORGE_PON_DIR/vagrant'
function cdvagrant() {
    if [ -d "/c/HOMESSD/git/george-pon/vagrant" ] ; then
        cd /c/HOMESSD/git/george-pon/vagrant
    else
        cd "$GIT_GEORGE_PON_DIR/vagrant"
    fi
}

if [ -d "$GIT_GEORGE_PON_DIR/mytools" ] ; then
    alias cdmytools='cd "$GIT_GEORGE_PON_DIR/mytools"'
fi
if [ -d "$GIT_GEORGE_PON_DIR/myopenrepo" ] ; then
    alias cdmyopenrepo='cd "$GIT_GEORGE_PON_DIR/myopenrepo"'
fi
alias cdmyazure='cd "$GIT_GEORGE_PON_DIR/myazure"'
alias cdkjwikig='cd "$GIT_GEORGE_PON_DIR/kjwikig"'
alias cdkjwikigdocker='cd "$GIT_GEORGE_PON_DIR/kjwikigdocker"'
alias cdfreebsdhome='cd /c/home/freebsd/home-run-v'
alias cdawshome='cd /c/home/aws/home-run-v'
alias cdubuntuhome='cd /c/home/ubuntu/home-run-v'
alias cddebianhome='cd /c/home/debian/home-run-v'
alias cdoraclehome='cd /c/home/oracle/home-run-v'

# MSYS2 特有
export TMP=$HOME/tmp2

# read mytools
if [ -d "$GIT_GEORGE_PON_DIR/mytools" ] ; then
    source "$GIT_GEORGE_PON_DIR/mytools/bash_profile.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/bashrc-common.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/bashrc-home.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/git-functions.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/shar-cat.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/docker-functions.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/kubernetes-functions.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/vagrant-functions.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/kube-run-v.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/ansible-role-hinagata.sh"
    source "$GIT_GEORGE_PON_DIR/mytools/vagrant-ssh-run-v.sh"
elif [ -d "$GIT_GEORGE_PON_DIR/myopenrepo" ] ; then
    source "$GIT_GEORGE_PON_DIR/myopenrepo/bashrc-common.sh"
    source "$GIT_GEORGE_PON_DIR/myopenrepo/git-functions.sh"
fi


# alias調整
alias node='node'
unalias node
alias rm='rm'
unalias rm
alias cp='cp'
unalias cp
alias mv='mv'
unalias mv
alias ls='ls'
unalias ls
alias ls='ls -aF --color'

# PATHの先頭にgit for windows sdk mingw64/binを指定する
# PATH="/c/home/01-desktop-tools/git-for-windows-sdk/usr/bin:/mingw64/bin/:$PATH"
# export PATH

# mingw64 path add
if [ -d "/mingw64/bin" ]; then
    f-path-prepend "/mingw64/bin"
fi


# msys用に.ssh/configをコピーする
function f-msys-copy-ssh-config() {
    OLD_PWD=$PWD
    cd "/home/${USER}/.ssh"
    cp "/c/Users/${USER}/.ssh/config" .
    cd $OLD_PWD
}

# Android Studio 環境整備
function f-setup-android-studio() {
    # JDK 1.8を指定する
    f-path-prepend "/c/Program Files/Java/jdk1.8.0_251/bin"
    JAVA_HOME="c:/Program Files/Java/jdk1.8.0_251"
    export JAVA_HOME

    # emulator.exeにパスを通す
    f-path-prepend "/c/Users/fj6782ix/AppData/Local/Android/Sdk/emulator"

    # 設定確認
    f-path-show
    java -version

    # 環境変数設定
    export ANDROID_SDK_ROOT="$HOME/AppData/Local/Android/Sdk"

    cd "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Android Studio"
    # $proc = Start-Process "C:\Program Files\Android\Android Studio\bin\studio64.exe"
    # $proc.WaitForExit()
    "C:\Program Files\Android\Android Studio\bin\studio64.exe"

    echo "starting android studio ..."
}
# f-setup-android-studio

# apache tomcat log directory
function cdtomcatlog() {
    if [ -d "/c/Program Files/Apache Software Foundation/Tomcat 10.0/logs" ] ; then
        cd "/c/Program Files/Apache Software Foundation/Tomcat 10.0/logs"
    fi
}


# alias for emacs eww
alias emacs-eww-browse="emacs -nw -f eww-browse"
alias emacs-eww-google="emacs -nw -f eww-browse https://www.google.co.jp/"
alias emacs-eww-getdiaries="emacs -nw -f eww-browse http://www.ceres.dti.ne.jp/~george/getdiaries.html"

# alias for w3m
alias w3m-google="w3m https://www.google.co.jp/"
alias w3m-getdiaries='w3m http://www.ceres.dti.ne.jp/~george/getdiaries.html'

#
# end of file
#
