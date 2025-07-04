#!/bin/bash
#
# git操作共通関数
#

function f_git() {
    echo "git $@"
    git "$@"
    local RC=$?
    if [ $RC -ne 0 ]; then
        echo "ERROR: git $@ failed."
    fi
    return $RC
}

function git-branch-config() {
    # git config の情報を表示する
    echo ""
    echo "### システム全体設定"
    f_git config --list --system
    echo ""
    echo "### ユーザー毎の設定"
    f_git config --list --global
    echo ""
    echo "### リポジトリ毎の設定"
    f_git config --list --local
}

function git-user-name() {
    # GIT_IDを取得する
    local GIT_ID=""
    if git config --local --list > /dev/null 2>&1 ; then
        GIT_ID=`git config --local --list | grep user.name| sed 's/user.name=//g'`
    fi
    if [ -z "$GIT_ID" ]; then
        GIT_ID=`git config --global --list | grep user.name| sed 's/user.name=//g'`
    fi
    if [ -z "$GIT_ID" ]; then
        echo user_name_is_null
        return 1
    fi
    # スペースはアンダースコアに変換
    GIT_ID=$( echo $GIT_ID | sed -e 's/ /_/g' )
    echo $GIT_ID
}

function git-status-check() {
    if git status | grep "nothing to commit, working tree clean" 1>/dev/null 2>/dev/null ; then
        echo "CLEAN"
    else
        echo "DURTY"
    fi
}

function git-lol() {
    # ログ表示
    f_git log --graph --decorate --pretty=oneline --abbrev-commit
}

function git-lola() {
    # ログ表示
    f_git log --graph --decorate --pretty=oneline --abbrev-commit --all
}

function git-ls-files() {
    # ファイルのアクセス許可属性の表示
    f_git ls-files -s
}

function git-branch-a() {
    # "ブランチ一覧"
    f_git branch -a
}

function git-branch-vv() {
    # ブランチが追跡しているorigin一覧
    echo "ブランチが追跡しているorigin一覧"
    echo "追跡するリモートブランチを設定する場合は git branch --set-upstream-to=origin/[ブランチ名]"
    f_git branch -vv
}

# よくあるgitの初期化を実施する
function git-initialize() {
    # コミットする時に保存されるユーザー名とメールアドレス
    git config --global user.name "Jun Obama"
    git config --global user.email "george@yk.rim.or.jp"

    # 日本語パス名の文字化け対策
    git config --global core.quotepath false

    # 改行コードの自動変換の無効化。デフォルトはtrue。
    git config --global core.autocrlf false

    # ページャーは使用しない
    # git config --global core.pager ''

    # 自己署名な証明書を許可する
    git config --global http.sslVerify false

    # gitの認証情報を保存する
    git config --global credential.helper store

    # push を upstreamが設定されているものに限定する
    # git config --global push.default upstream

    # git ver 2.0 以降では simple がデフォルト。upstreamが設定されていて、かつ、ローカルとリモートで名前が同じブランチのみpushする。
    git config --global push.default simple

    # git pull した時の戦略。マージする。(rebaseはしない)
    git config --global pull.rebase false

    # ファイル名の大文字小文字の変動を追尾する
    git config --global core.ignorecase false

    # 各リポジトリの中で実施するコマンド
    #if [ -d .git ] ; then
        # git pull した時の戦略。マージする。(rebaseはしない)(各gitリポジトリ内で実施)
        # git config pull.rebase false

        # ファイル名の大文字小文字の変動を追尾する
        # git config core.ignorecase false
    #fi

}

# git 対象ディレクトリを探索する
#function git-dirs() {
#    # 全階層のgit clone のリストを作成する。
#    local GIT_CLONE_DIR_LIST=`find .  -name ".git" |  egrep -v '\bpkg\b' | egrep -v '\bdep\b' | sed -e 's%.git$%%g' | sed -e 's%/$%%g' `
#    echo $GIT_CLONE_DIR_LIST
#    if [ -z "$GIT_CLONE_DIR_LIST" ]; then
#        return 1
#    fi
#}

# 再帰してgitの状態を表示
function git-branch-status-all() {
    local GIT_ID=$( git-user-name )
    # local GIT_CLONE_DIR_LIST=$( git-dirs )
    # bashの配列に結果を格納
    mapfile -t  GIT_CLONE_DIR_LIST < <( find .  -name ".git" |  egrep -v '\bpkg\b' | egrep -v '\bdep\b' | sed -e 's%.git$%%g' | sed -e 's%/$%%g' )
    for GIT_CLONE_DIR in "${GIT_CLONE_DIR_LIST[@]}"
    do
        SAVED_PWD="$PWD"
        cd "${GIT_CLONE_DIR}"
        echo "------------------------------"
        echo "----- ${GIT_CLONE_DIR}  "
        echo "------------------------------"
        # git fetch --prune
        f_git status
        echo ""
        cd "$SAVED_PWD"
    done
}


# pull request が全部消化された時に、developに戻す際に使う
# ユーザー名が含まれており、ローカルにだけあるブランチは消す （！注意！）
# dep,pkgというディレクトリの下の.gitは無視する。depコマンドで拾った依存ライブラリはgit pullしない。
function git-branch-clean-all() {
    local GIT_ID=$( git-user-name )

    echo "#"
    echo "# clean ${GIT_ID}'s branches"
    echo "#"

    # local GIT_CLONE_DIR_LIST=$( git-dirs )
    # bashの配列に結果を格納
    mapfile -t  GIT_CLONE_DIR_LIST < <( find .  -name ".git" |  egrep -v '\bpkg\b' | egrep -v '\bdep\b' | sed -e 's%.git$%%g' | sed -e 's%/$%%g' )
    # リスト毎に"$GIT_ID/#*"ブランチを削除する。
    for GIT_CLONE_DIR in "${GIT_CLONE_DIR_LIST[@]}"
    do
        local GIT_DEFAULT_BRANCH_NAME=develop
        SAVED_PWD="$PWD"
        cd "${GIT_CLONE_DIR}"
        echo "------------------------------"
        echo "----- ${GIT_CLONE_DIR} "
        echo "------------------------------"
        # fetch する。リモートリポジトリでは削除されているブランチは、削除する。
        f_git fetch --prune
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
        # カレントブランチを取得する
        CUR_BRANCH=`git branch | grep '^*' | sed -e 's/^\*/ /g' -e 's/^  //g'`
        # ブランチ一覧を取得する
        BR_LIST=`git branch | sed 's/^\*/ /g'`
        # リモートブランチ一覧取得
        BR_LIST_2=$( git branch -a | sed 's/^\*/ /g' | grep remotes/origin )
        # リモートブランチにdevelopがある場合は、developを採用。次に master, main を検索していく。
        if [ -n "$( echo $BR_LIST_2 | grep develop )" ]; then
            GIT_DEFAULT_BRANCH_NAME=develop
        elif [ -n "$( echo $BR_LIST_2 | grep master )" ]; then
            GIT_DEFAULT_BRANCH_NAME=master
        elif [ -n "$( echo $BR_LIST_2 | grep main )" ]; then
            GIT_DEFAULT_BRANCH_NAME=main
        else
            echo "can not determine default remote branch name. abort."
            return 1
        fi
        echo "GIT_DEFAULT_BRANCH_NAME is $GIT_DEFAULT_BRANCH_NAME"
        # カレントブランチがdirtyではなく、developまたはmasterまたはmainの場合は、git pullを行う
        STATUS=$( git status | grep "nothing to commit" )
        if [ ! -z "$STATUS" ]; then
            if [ x"$CUR_BRANCH"x = x"master"x -o x"$CUR_BRANCH"x = x"develop"x -o x"$CUR_BRANCH"x = x"main"x ]; then
                f_git pull
                RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
            else
                echo "workspace is not master nor develop nor main branch.  skip git pull."
            fi
        else
            echo "workspace is durty.  skip git pull."
        fi

        # ローカルブランチの掃除
        for BR in ${BR_LIST};
        do
            # 自分のユーザー名を含むブランチのみお掃除対象
            if [ `echo "${BR}" | grep "$GIT_ID"` ] ; then
                STATUS=$( git status | grep "nothing to commit" )
                if [ -z "$STATUS" ]; then
                    # カレントブランチがdirtyな場合は掃除しない
                    echo "directory: $GIT_CLONE_DIR , branch: $CUR_BRANCH is not clean. skip git branch -d $BR."
                elif [ ! -z "$( echo $BR_LIST_2 | grep $BR )" ]; then
                    # remoteブランチに残っている場合は残す
                    echo "directory: $GIT_CLONE_DIR , branch: $BR has remote branch. skip git branch -d $BR."
                elif [ x"$BR"x == x"$CUR_BRANCH"x ]; then
                    # currentブランチがリモートにない場合はデフォルトブランチ名(developまたはmaster)に戻してブランチは削除する
                    f_git checkout $GIT_DEFAULT_BRANCH_NAME
                    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
                    f_git pull
                    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
                    f_git branch -d ${BR}
                    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
                else
                    f_git branch -d ${BR}
                    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
                fi
            fi
        done
        echo ""
        cd "$SAVED_PWD"
    done
}

function git-branch-test-tag-exists() {
    # 引数で指定した名前のタグが存在するかチェック
    local ARG_TAG_NAME=$1
    if [ -z "$ARG_TAG_NAME" ] ; then
        echo "git-branch-test-tag-exists: tag-name"
        return 1
    fi
    local RESULT=$( git tag -l | egrep -e '^'"$ARG_TAG_NAME"'$' )
    if [ -z "$RESULT" ] ; then
        echo "NOTFOUND"
        return
    fi
    echo "FOUND"
}

function git-branch-test-local-branch-exists() {
    # 引数で指定した名前のローカルブランチが存在するかチェック
    local ARG_BRANCH_NAME=$1
    if [ -z "$ARG_BRANCH_NAME" ] ; then
        echo "git-branch-test-local-branch-exists: branch-name"
        return 1
    fi
    local RESULT=$( git branch -a | sed -e 's/^* /  /g' | awk '{print $1}' | egrep -e '^'"$ARG_BRANCH_NAME"'$' )
    if [ -z "$RESULT" ] ; then
        echo "NOTFOUND"
        return
    fi
    echo "FOUND"
}

function git-branch-test-remote-branch-exists() {
    # 引数で指定した名前のリモートブランチが存在するかチェック
    local ARG_BRANCH_NAME=$1
    if [ -z "$ARG_BRANCH_NAME" ] ; then
        echo "git-branch-test-remote-branch-exists: branch-name"
        return 1
    fi
    local RESULT=$( git branch -a | sed -e 's/^* /  /g' | awk '{print $1}' | grep -e '^remotes/origin/'"$ARG_BRANCH_NAME"'$' )
    if [ -z "$RESULT" ] ; then
        echo "NOTFOUND"
        return
    fi
    echo "FOUND"
}

function git-branch-get-current-branch-name() {
    # ローカルのブランチ名を取得する
    local RESULT=$( f_git branch -a | grep '^* ' | sed -e 's/* /  /g' )
    echo $RESULT
}

function git-branch-new() {
    #
    # 新しいブランチを作成する
    # git-branch-new  branch-name
    #
    # 新しいブランチを作成する。 gitユーザー名/#20180417_163658_subbranchname というブランチ名をつける。
    # git-branch-new  -n  subbranchname
    #
    # 新しいブランチを作成して git add . ; git commit ; git push を一気に行う
    # git-branch-new  -m  "commit message"
    #
    # 新しいブランチ branch_sub_name を作成して git add . ; git commit ; git push を一気に行う
    # git-branch-new  -m  "commit message"  -n branch_sub_name
    #
    # 新しいブランチ branch_sub_name を作成して git add . ; git commit ; git push ; git tag を一気に行う
    # git-branch-new  -m  "commit message"  -n branch_sub_name -t tag_name
    #

    # GITユーザー名を取得する
    local GIT_ID=$( git-user-name )

    local YMD_HMS=$( date +%Y%m%d_%H%M%S )
    local DEFAULT_BRANCH_NAME="$GIT_ID/#$YMD_HMS"
    local BRANCH_NAME=$DEFAULT_BRANCH_NAME
    local COMMIT_COMMENT=
    local ARG_TAG_LIST=

    # 引数解析
    while true
    do
        if [ $# -eq 0 ]; then
            break
        fi

        if [ x"$1"x = x"-m"x ]; then
            # -m comment があった場合は、コミットコメントとして採用。pushまで自動で行う。
            COMMIT_COMMENT=$2
            echo "auto commit mode. commit comment : $COMMIT_COMMENT"
            shift
        elif [ x"$1"x = x"-n"x ]; then
            # -n br-name があった場合、ブランチ名の後ろに付加する
            BRANCH_NAME="${DEFAULT_BRANCH_NAME}_$2"
            echo "named branch mode. new branch name : $BRANCH_NAME"
            shift
        elif [ "$1" = "-t" ]; then
            # -t tag があった場合は、タグ付けまで自動で行う。
            ARG_TAG_LIST="$ARG_TAG_LIST $2"
            echo "auto tag mode. tag : $ARG_TAG_LIST"
            shift
        else
            # 引数があった場合はブランチ名として採用
            BRANCH_NAME=$1
            echo "named branch mode. new branch name : $BRANCH_NAME"
        fi
        shift
    done

    echo "create new branch $BRANCH_NAME"

    # developに戻す
    # f_git checkout develop

    # pullする
    # f_git pull
    # RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # リモートリポジトリでは削除されているブランチは、削除する
    f_git fetch --prune
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # ワークの中に未コミットのファイルがあるかチェック
    local CHKDURTY=$( git-status-check )

    # ローカルブランチが存在するか確認
    local CHK_LOCAL_BRANCH=$( git-branch-test-local-branch-exists $BRANCH_NAME )
    echo "checking local branch ... CHK_LOCAL_BRANCH=$CHK_LOCAL_BRANCH"

    # リモートブランチが存在するか確認
    local CHK_REMOTE_BRANCH=$( git-branch-test-remote-branch-exists $BRANCH_NAME )
    echo "checking remote branch ... CHK_REMOTE_BRANCH=$CHK_REMOTE_BRANCH"

    # 現在のブランチ名とターゲットブランチ名が同じなら、そのまま使う
    CURRENT_BRANCH_NAME=$( git-branch-get-current-branch-name )
    echo "BRANCH_NAME=$BRANCH_NAME"
    echo "CURRENT_BRANCH_NAME=$CURRENT_BRANCH_NAME"
    if [ x"$BRANCH_NAME"x = x"$CURRENT_BRANCH_NAME"x ] ; then
        echo "current branch is $BRANCH_NAME. use it."
    else
        if [ x"$CHK_LOCAL_BRANCH"x = x"FOUND"x ] ; then
            echo "local branch found. "

            # ワーキングに未コミットファイルがある場合、ブランチ変更はできないはず。
            if [ x"$CHKDURTY"x = x"DURTY"x  ] ; then
                echo "WARNING working copy is durty. can not change branch."
            fi

            # ブランチに切り替え
            f_git checkout $BRANCH_NAME
            RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

        elif [ x"$CHK_REMOTE_BRANCH"x = x"FOUND"x ] ; then
            echo "remote branch found. "

            # ワーキングに未コミットファイルがある場合、ブランチ変更はできないはず。
            if [ x"$CHKDURTY"x = x"DURTY"x  ] ; then
                echo "WARNING working copy is durty. can not change branch."
            fi

            # ブランチに切り替え
            f_git checkout $BRANCH_NAME
            RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

        else
            echo "local / remote branch not found. create it."
            # branchを新しく作成する
            f_git branch $BRANCH_NAME
            RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
            # 作成したブランチに切り替え
            f_git checkout $BRANCH_NAME
            RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
            # 新ブランチは upstream を設定してpush実行
            f_git push --set-upstream origin $BRANCH_NAME
            RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
            # リモート情報を確認
            f_git remote -vv
            RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
        fi
    fi

    # ブランチの一覧を表示
    f_git branch -vv
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # 現在のステータスを表示
    f_git status
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    echo ""
    echo "  run below commands:"
    echo "    git add <file> ..."
    echo "    git commit -m comment"
    echo "    git push --set-upstream origin $BRANCH_NAME"
    echo ""

    # コミットコメントがある場合は、add / commit / push まで行う
    if [ ! -z "$COMMIT_COMMENT" ]; then
        if [ x"$CHKDURTY"x = x"DURTY"x ] ; then
            f_git add .
            RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
            f_git commit -m "$COMMIT_COMMENT"
            RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
        fi
        # push を実行
        f_git push --set-upstream origin $BRANCH_NAME
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    fi

    # タグ名付与がある場合はタグ名pushを実行
    for i in $ARG_TAG_LIST
    do
        if [ ! -z "$COMMIT_COMMENT" ]; then
            git-branch-tag-and-push -m "$COMMIT_COMMENT" $i
        else
            git-branch-tag-and-push $i
        fi
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    done
}

# 指定されたタグ名の場所にブランチを作成
# git-branch-new-at-tag  TAG_NAME_1
# 厳密な意味では、タグ名の場所にブランチを作ることはできないらしい(コミットが一つ進むので)
function git-branch-new-at-tag() {
    if [ $# -eq 0 ] ; then
        echo "git-branch-new-at-tag tag-name"
        return 1
    fi
    TAG_NAME=$1
    BRANCH_NAME=${TAG_NAME}-branch
    echo "TAG_NAME is $TAG_NAME"
    echo "BRANCH_NAME is $BRANCH_NAME"

    # 指定タグをチェックアウト
    f_git checkout $TAG_NAME
    RC=$? ; if [ $RC -ne 0 ] ; then return 1 ; fi

    # その場所に新ブランチを作成
    git-branch-new ${BRANCH_NAME}
    RC=$? ; if [ $RC -ne 0 ] ; then return 1 ; fi

    echo ""
    echo "after edit, run git-branch-add -t $TAG_NAME "
    echo ""
}

function git-branch-add-auto-tag() {
    # 自動でタグ名をつけてコミット
    # TEST_IT-20220811-1 みたいなタグを自動で付与してコミットとpushを行う
    # git checkout main
    TAG_NAME_BASE="TEST_IT-$( date +%Y%m%d )"
    CNT=$( git tag | grep "$TAG_NAME_BASE" | wc -l )
    CNT=$(( CNT + 1 ))
    TAG_NAME="${TAG_NAME_BASE}-${CNT}"
    echo "TAG_NAME is $TAG_NAME"
    git-branch-add -m "add auto commit with tag $TAG_NAME" -t $TAG_NAME
}

# ブランチの削除を実施
# git-branch-delete branch-name
function git-branch-delete() {
    if [ $# -eq 0 ] ; then
        echo "git-branch-delete branch-name"
        return 1
    fi

    for BRANCH_NAME in "$@"
    do
        # local ブランチの削除
        f_git branch -d ${BRANCH_NAME}
        RC=$? ; if [ $RC -ne 0 ] ; then return 1 ; fi
        # remote ブランチの削除
        f_git push origin :${BRANCH_NAME}
        RC=$? ; if [ $RC -ne 0 ] ; then return 1 ; fi
    done
}

# ローカルでtagをつけて、それをpushする
# git tagには -m でメッセージを付けないと git describe で表示時にエラーになる
function git-branch-tag-and-push() {
    if [ $# -eq 0 ]; then
        echo "git-branch-tag-and-push [-m tag_message] tag-name [tag-name]"
        return 1
    fi
    local ARG_MESSAGE="add tag"
    if [ x"$1"x = x"-m"x ]; then
        ARG_MESSAGE="$2"
        shift
        shift
    fi
    local ARG_TAG
    for ARG_TAG in "$@"
    do
        # 現在のタグ一覧を取得。一致しているものがあったら、削除する。
        local CUR_TAG_LIST=$( git tag -l )
        local i
        for i in $CUR_TAG_LIST ;
        do
            if [ x"$i"x = x"$ARG_TAG"x ]; then
                echo "git-branch-tag-and-push: tag $ARG_TAG is already set."
                echo "git-branch-tag-and-push: at first , remove tag $ARG_TAG."
                f_git tag -d $ARG_TAG
                RC=$? ; if [ $RC -ne 0 ]; then echo "ERROR. abort." ; return 1; fi
                f_git push origin :$ARG_TAG
                RC=$? ; if [ $RC -ne 0 ]; then echo "ERROR. abort." ; return 1; fi
                break
            fi
        done
        # タグをつけて、originにpushする。
        f_git tag -m "$ARG_MESSAGE" $ARG_TAG
        RC=$? ; if [ $RC -ne 0 ]; then echo "ERROR. abort." ; return 1; fi
        f_git push origin $ARG_TAG
        RC=$? ; if [ $RC -ne 0 ]; then echo "ERROR. abort." ; return 1; fi
    done
}

# ローカルでtagを削除して、それをpushする
function git-branch-tag-remove-and-push() {
    if [ $# -eq 0 ]; then
        echo "git-branch-tag-remove-and-push tag-name"
        return 1
    fi
    local ARG_TAG=$1
    # 現在のタグ一覧を取得。一致しているものがあったら、削除する。
    local CUR_TAG_LIST=$( git tag -l )
    for i in $CUR_TAG_LIST ;
    do
        if [ x"$i"x = x"$ARG_TAG"x ]; then
            echo "git-branch-tag-remove-and-push: remove tag $ARG_TAG."
            f_git tag -d $ARG_TAG
            RC=$? ; if [ $RC -ne 0 ]; then echo "ERROR. abort." ; return 1; fi
            f_git push origin :$ARG_TAG
            RC=$? ; if [ $RC -ne 0 ]; then echo "ERROR. abort." ; return 1; fi
            break
        fi
    done
}

# ブランチからブランチにマージを実施する
# arg1 から arg2 にマージする
function git-branch-merge() {
    local MERGE_MESSAGE="auto merge"
    local ARG_SRC
    local ARG_DST
    local ARG_CNT=0

    while true
    do
        if [ $# -eq 0 ]; then
            break
        fi

        if [ x"$1"x = x"-m"x ]; then
            MERGE_MESSAGE=$2
            shift
        elif [ $ARG_CNT -eq 0 ]; then
            ARG_SRC=$1
            ARG_CNT=$(( ARG_CNT + 1 ))
        elif [ $ARG_CNT -eq 1 ]; then
            ARG_DST=$1
            ARG_CNT=$(( ARG_CNT + 1 ))
        fi
        shift
    done

    # 引数チェック
    if [ -z "$ARG_SRC" -o -z "$ARG_DST" ] ; then
        echo "git-branch-merge  develop  master  ... merge develop into master"
        return 1
    fi

    # pullする
    f_git pull
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # masterをチェックアウトする
    f_git checkout $ARG_DST
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # pullする
    f_git pull
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # developをマージする
    f_git merge -m "$MERGE_MESSAGE" $ARG_SRC
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # commitする
    #f_git commit -m "merge from develop"
    #RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # pushする
    f_git push
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # developをチェックアウトする
    #f_git checkout $ARG_SRC
    #RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # 状態表示
    f_git status
}


# 現在のブランチに対して本家の進捗を取り込んでマージする
# 毎回マージコミットが残るのでちょっと不便
function git-branch-fetch-and-merge() {
    local MERGE_MESSAGE="automatic merge from origin"
    local ARG_SRC
    local ARG_CNT=0

    while true
    do
        if [ $# -eq 0 ]; then
            break
        fi

        if [ x"$1"x = x"-m"x ]; then
            MERGE_MESSAGE=$2
            shift
        elif [ $ARG_CNT -eq 0 ]; then
            ARG_SRC=$1
            ARG_CNT=$(( ARG_CNT + 1 ))
        fi
        shift
    done

    if [ -z "$ARG_SRC" ] ; then
        echo "git-branch-fetch-and-merge  master  ... merge from master into current branch"
        return 1
    fi

    f_git fetch
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # master or main からマージする
    f_git merge -m "$MERGE_MESSAGE" origin $ARG_SRC
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # 状態表示
    f_git status
}



# 現在のブランチに対してstash push -u してからgit pullしてstash popする
# git stash pop した時に手動マージが発生する
function git-branch-pull-stash() {
    local GIT_STATUS=$( git-status-check )
    if [ x"$GIT_STATUS"x = x"DURTY"x ]; then
        f_git stash push -u
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
        f_git pull
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
        f_git stash pop
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    else
        f_git pull
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    fi
}



# コミットしてpushする
# おひとりさまリポジトリだと一番よく使う
function git-branch-add() {
    local COMMIT_COMMENT=
    local ARG_TAG_LIST=

    # 引数解析
    if [ $# -eq 0 ]; then
        echo "git-branch-add  [-m commit-comment ]  [ -t tag ]"
        return 1
    fi
    # 引数解析
    while true
    do
        if [ $# -eq 0 ]; then
            break
        fi

        if [ "$1" = "-m" ]; then
            # -m comment があった場合は、コミットコメントとして採用。pushまで自動で行う。
            COMMIT_COMMENT=$2
            echo "auto commit mode. commit comment : $COMMIT_COMMENT"
            shift
        fi
        if [ "$1" = "-t" ]; then
            # -t tag があった場合は、タグ付けまで自動で行う。
            ARG_TAG_LIST="$ARG_TAG_LIST $2"
            echo "auto tag mode. tag : $ARG_TAG_LIST"
            shift
        fi
        shift
    done

    f_git diff
    f_git status

    local GIT_STATUS=$( git-status-check )
    if [ x"$GIT_STATUS"x = x"DURTY"x ]; then

        f_git add .
        if [ -z "$COMMIT_COMMENT" ]; then
            return 0
        fi

        f_git commit -m "$COMMIT_COMMENT"
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

        f_git push
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    fi

    for i in $ARG_TAG_LIST
    do
        if [ -n "$COMMIT_COMMENT" ] ; then
            git-branch-tag-and-push -m "$COMMIT_COMMENT" $i
        else
            git-branch-tag-and-push $i
        fi
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    done
}

#
#  １コミットの内容だけを他のブランチで取り込みたい場合
#
function git-branch-cherry-pick() {
    local COMMIT_IDS="$@"
    if [ -z "$COMMIT_IDS" ]; then
        echo "git-branch-cherry-pick  commit-id1 [commit-id2...]"
        return 0
    fi

    git cherry-pick  --allow-empty    "$COMMIT_IDS"
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

}

#
# git pull --rebase=true を実施する (非推奨)
#
# master 上で変更された内容を手元に取り込み、 merge commit を作らずにmergeを実施する。
#
# git pull のデフォルトでは、merge commit を作成する。
#
function git-branch-deprecated-pull-rebase-true() {

    echo "git-branch-pull-rebase-true is deprecated."
    echo "use git-branch-fetch-and-merge."

    local GIT_STATUS=$( git-status-check )
    if [ x"$GIT_STATUS"x = x"DURTY"x ]; then

        f_git add .
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

        f_git commit -m "for prepair merge"
        RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    fi

    f_git pull --rebase=true
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
}

#
# git sparse checkout を行う。git 2.25以降。巨大gitプロジェクトの中から一部のディレクトリだけ取り出す。
#
# git-branch-sparse-checkout  http://hoge.git.com/user/proj.git  dir-name-1
#
# git-branch-sparse-checkout -t tag-name  http://hoge.git.com/user/proj.git  dir-name-1  [dir-name-2]
#
function git-branch-sparse-checkout() {
    local ARG_GITURL=$1
    local ARG_PATH_LIST=
    local ARG_TAG_NAME=
    local ARG_CNT=0
    local USAGE_MSG="git-branch-sparse-checkout  [-t tag-name]  git-url  path-1 [path-2...]"

    while true
    do
        if [ $# -eq 0 ] ; then
            break
        fi

        if [ x"$1"x = x"--help"x ] ; then
            echo "$USAGE_MSG"
            return 1
        elif [ x"$1"x = x"-t"x ] ; then
            ARG_TAG_NAME="$2"
            shift
        elif [ $ARG_CNT -eq 0 ] ; then
            ARG_GITURL=$1
            ARG_CNT=$(( ARG_CNT + 1 ))
        elif [ $ARG_CNT -gt 0 ] ; then
            ARG_PATH_LIST="$ARG_PATH_LIST $1"
            ARG_CNT=$(( ARG_CNT + 1 ))
        fi
        shift
    done

    if [ -z "$ARG_GITURL" ] ; then
        echo "$USAGE_MSG"
        return 1
    fi

    git clone --filter=blob:none  $ARG_GITURL
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    local PROJ_SUBDIR=${ARG_GITURL##*/}
    local PROJ_DIR=${PROJ_SUBDIR%%.git}
    pushd $PROJ_DIR
        git sparse-checkout init
        git sparse-checkout set $ARG_PATH_LIST
        # タグ名指定があるなら、指定してチェックアウト実施
        git checkout $ARG_TAG_NAME
    popd

}

#
# 「ええーいリモートが合ってるんだからアイツに合わせたいんだよ！」
# とイライラしたら下記。masterブランチ用。
#
function git-branch-force-master-pull() {
    f_git checkout master
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    f_git fetch origin
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    f_git reset --hard origin/master
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
}

#
# 「ええーいリモートが合ってるんだからアイツに合わせたいんだよ！」
# とイライラしたら下記。mainブランチ用。
#
function git-branch-force-main-pull() {
    f_git checkout main
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    f_git fetch origin
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
    f_git reset --hard origin/main
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
}

#
# git stash 系のコマンド
#

# workspace上の未追跡ファイルも含めて一時的に退避する。gitワークスペースはcleanな状態になる。
function git-stash-push-u() {
    COMMENT="stash saved $(date)"
    if [ $# -gt 0 ] ; then
        COMMENT="$1"
    fi
    f_git stash push -u -m "$COMMENT"
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
}

# stashから戻す。使用したstashは消す。
function git-stash-pop() {
    f_git stash pop
    RC=$? ; if [ $RC -ne 0 ]; then return 1; fi
}

# stashの一覧
function git-stash-list() {
    f_git stash list
}

# stashの内容表示
function git-stash-show() {
    f_git stash show
}

# stashから戻す。popと異なり使用したstashは消さない。
function git-stash-apply() {
    if [ $# -eq 0 ] ; then
        echo "ex: git-stash-apply 0"
        return 0
    fi
    f_git stash apply "stash@{$1}"
}

# 指定した番号のstashを消す
function git-stash-drop() {
    if [ $# -eq 0 ] ; then
        echo "ex: git-stash-drop 0"
        return 0
    fi
    f_git stash drop "stash@{$1}"
}

# 全てのstashを消す
function git-stash-clear() {
    f_git stash clear
}



#
# git backup 系のコマンド
#

# カレントディレクトリ名 + _bkup の名前の一つ上のディレクトリに modified ファイルと untrack ファイルをコピーして保存する
function git-branch-private-backup-upper-dir() {
    if [ $# -eq 0 ] ; then
        echo "git-branch-private-backup-upper-dir: filename"
        return 1
    fi

    FROM="$1"
    if [ $# -ge 2 ] ; then
        DEST_DIR="$2"
    else
        BASE_PWD=$(basename "$PWD")
        DEST_DIR="../${BASE_PWD}_bkup"
    fi

    if [ -f "$FROM" ] ; then
        CP_OPT="    "
    elif [ -d "$FROM" ] ; then
        CP_OPT=" -r "
    else
        echo "git-branch-private-backup-upper-dir: $FROM is not a file"
        return 1
    fi

    DEST="$DEST_DIR/$FROM"

    # echo "DEST is $DEST"
    DIR=$( dirname "$DEST" )
    # echo "DIR is $DIR"

    # echo mkdir -p $DIR
    mkdir -p "$DIR"
    RC=$? ; if [ $RC -ne 0 ] ; then echo "ERROR. abort." ; return 1 ; fi

    echo cp $CP_OPT "$FROM" "$DEST"
    cp $CP_OPT "$FROM" "$DEST"
    RC=$? ; if [ $RC -ne 0 ] ; then echo "ERROR. abort." ; return 1 ; fi
}

# git status の結果から modified ファイルと untracked ファイルの一覧を取得する
function git-branch-list-modified-untrack-files() {
    mapfile -t MODIFIED_LIST < <( f_git status | awk '/modified:/{print $2;}' )
    mapfile -t NEW_FILE_LIST < <( f_git status | awk '/new file:/{print $3;}' )
    mapfile -t UNTRACKED_LIST < <( f_git status | awk '/Untracked/ { F1 = 1; }; ( F1 == 1 ) { print $0; }' | grep -v "Untracked files" | grep -v "to include in what will be committed" | grep -v "no changes added to commit" | grep -v "nothing added to commit" | awk '{print $1}' )
    for i in "${MODIFIED_LIST[@]}" "${NEW_FILE_LIST[@]}" "${UNTRACKED_LIST[@]}"
    do
        echo "$i"
    done
}

# 一つ上のディレクトリに modified ファイルと untrack ファイルをコピーして保存する
function git-branch-backup-modified-untrack-files() {
    # 引数処理
    append_name=""
    while [ $# -gt 0 ]
    do
        arg1="$1"
        shift
        if [ x"$arg1"x = x"-n"x ] ; then
            append_name="_$1"
            shift
        fi
    done
    mapfile -t MODIFIED_UNTRACK_LIST < <( git-branch-list-modified-untrack-files )
    YMD_HMS=$( date +%Y%m%d_%H%M%S)
    BASE_PWD=$(basename "$PWD")
    DEST_DIR="../${BASE_PWD}_bkup_${YMD_HMS}${append_name}"
    for i in "${MODIFIED_UNTRACK_LIST[@]}"
    do
        if [ -f "$i" ] ; then
            git-branch-private-backup-upper-dir "$i" "$DEST_DIR"
            RC=$? ; if [ $RC -ne 0 ] ; then echo "ERROR. abort." ; return 1 ; fi
        fi
        if [ -d "$i" ] ; then
            git-branch-private-backup-upper-dir "$i" "$DEST_DIR"
            RC=$? ; if [ $RC -ne 0 ] ; then echo "ERROR. abort." ; return 1 ; fi
        fi
    done
}

#
# end of file
#
