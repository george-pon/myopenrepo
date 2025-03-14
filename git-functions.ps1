﻿#
# git操作共通関数
#
function f_git {
    Write-Output  "git $args"
    git $args
    $RC = $LASTEXITCODE
    if ( $RC -ne 0 ) {
        Write-Host "ERROR: git $args failed."
    }
}

function git-branch-config {
    # git config の情報を表示する
    Write-Output ""
    Write-Output "### システム全体設定"
    f_git config --list --system
    Write-Output ""
    Write-Output "### ユーザー毎の設定"
    f_git config --list --global
    Write-Output ""
    Write-Output "### リポジトリ毎の設定"
    f_git config --list --local
}


function git-user-name {
    # GIT_IDを取得する
    # スペースはアンダースコアに変換
    $GIT_ID = & git config --local --list | select-string -pattern "user.name" | ForEach-Object { $_ -replace "user.name=", "" -replace " ", "_" }
    if ( ! $GIT_ID ) {
        $GIT_ID = & git config --global --list | select-string -pattern "user.name" | ForEach-Object { $_ -replace "user.name=", "" -replace " ", "_" }
    }
    if ( ! $GIT_ID ) {
        Write-Host "user.name is null."
        return ""
    }
    return $GIT_ID
}

function git-status-check {
    $GIT_STATUS_CLEAN = & git status | select-string -pattern "nothing to commit, working tree clean"
    if ( $GIT_STATUS_CLEAN.Length -ne 0 ) {
        Write-Output "CLEAN"
    }
    else {
        Write-Output "DURTY"
    }
}


function git-lol {
    f_git log --graph --decorate --pretty=oneline --abbrev-commit
}

function git-lola {
    f_git log --graph --decorate --pretty=oneline --abbrev-commit --all
}

function git-ls-files {
    # ファイルのアクセス許可属性の表示
    f_git ls-files -s
}

function git-branch-a {
    # "ブランチ一覧"
    f_git branch -a
}

function git-branch-vv {
    # ブランチが追跡しているorigin一覧
    Write-Output "ブランチが追跡しているorigin一覧"
    Write-Output "追跡するリモートブランチを設定する場合は git branch --set-upstream-to=origin/[ブランチ名]"
    f_git branch -vv
}

# よくあるgitの初期化を実施する
function git-initialize {
    # コミットする時に保存されるユーザー名とメールアドレス
    git config --global user.name "Jun Obama"
    git config --global user.email "george@yk.rim.or.jp"

    # 日本語パス名の文字化け対策
    git config --global core.quotepath false

    # 改行コードの自動変換の無効化。デフォルトはtrue。
    # git config --global core.autocrlf false

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


    #if ( Test-Path ".git" ) {
    # ファイル名の大文字小文字の変動を追尾する(各gitリポジトリ内で実施)
    #    git config core.ignorecase false
    # git pull した時の戦略。マージする。(rebaseはしない)(各gitリポジトリ内で実施)
    #    git config pull.rebase false
    #}

}

# git 対象ディレクトリを探索する
function git-dirs {
    # 全階層のgit clone のリストを作成する。
    # git clone した場合、.git ディレクトリは不可視属性で作成される
    $GIT_CLONE_DIR_LIST = ( get-childitem -recurse -hidden -filter ".git" | Where-Object { $_.PSIsContainer } | foreach-object { $_.Parent.FullName }  )
    # 別のツールでディレクトリをコピーした場合、不可視属性がはずれるので、そちらも探す
    $GIT_CLONE_DIR_LIST += ( get-childitem -recurse  -filter ".git" | Where-Object { $_.PSIsContainer } | foreach-object { $_.Parent.FullName }  )
    return $GIT_CLONE_DIR_LIST
}

# 再帰してgitの状態を表示
function git-branch-status-all {
    $GIT_CLONE_DIR_LIST = ( git-dirs )
    Write-Output $GIT_CLONE_DIR_LIST | foreach-object {
        $SAVED_PWD = $PWD
        Set-Location $_
        Write-Output "------------------------------"
        Write-Output "----- $_  "
        Write-Output "------------------------------"
        # git fetch --prune
        f_git status
        Write-Output ""
        Set-Location $SAVED_PWD
    }
}


# pull request が全部消化された時に、developに戻す際に使う
# ユーザー名が含まれており、ローカルにだけあるブランチは消す （！注意！）
# dep,pkgというディレクトリの下の.gitは無視する。depコマンドで拾った依存ライブラリはgit pullしない。
function git-branch-clean-all() {
    $GIT_ID = ( git-user-name )
    $GIT_CLONE_DIR_LIST = ( git-dirs )
    Write-Output "#"
    Write-Output "# delete ${GIT_ID}'s branches"
    Write-Output "#"

    # リスト毎に"$GIT_ID/#*"ブランチを削除する。
    Write-Output $GIT_CLONE_DIR_LIST | foreach-object {
        $GIT_CLONE_DIR = $_
        $GIT_DEFAULT_BRANCH_NAME = "develop"
        $SAVED_PWD = $PWD
        Set-Location $GIT_CLONE_DIR
        write-output "------------------------------"
        write-output "----- $GIT_CLONE_DIR "
        write-output "------------------------------"
        # fetch する。リモートリポジトリでは削除されているブランチは、削除する。
        f_git fetch --prune
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
        # カレントブランチを取得する
        $CUR_BRANCH = ( git branch | select-string -pattern '^\*' | ForEach-Object { $_ -replace "^\*", " " -replace "  ", "" } )
        # ブランチ一覧を取得する
        $BR_LIST = ( git branch | ForEach-Object { $_ -replace "^\*", " " } )
        # リモートブランチ一覧取得
        $BR_LIST_2 = ( git branch -a | select-string -pattern "remotes/origin" | foreach-object { $_ -replace "^\*", " " } )
        # リモートブランチにdevelopがない場合は、デフォルトブランチ名はmasterとする
        # リモートブランチにdevelopがある場合は、developを採用。次に master, main を検索していく。
        $BR_LIST_3 = ( Write-Output $BR_LIST_2 | select-string "develop" )
        if ( $BR_LIST_3 ) {
            $GIT_DEFAULT_BRANCH_NAME = "develop"
        }
        $BR_LIST_3 = ( Write-Output $BR_LIST_2 | select-string "master" )
        if ( $BR_LIST_3 ) {
            $GIT_DEFAULT_BRANCH_NAME = "master"
        }
        $BR_LIST_3 = ( Write-Output $BR_LIST_2 | select-string "main" )
        if ( $BR_LIST_3 ) {
            $GIT_DEFAULT_BRANCH_NAME = "main"
        }
        Write-Output "GIT_DEFAULT_BRANCH_NAME is $GIT_DEFAULT_BRANCH_NAME"
        # カレントブランチがdirtyではなく、developまたはmasterまたはmainの場合は、git pullを行う
        $STATUS = ( f_git status | select-string -pattern "nothing to commit" )
        if ( $STATUS -ne "" ) {
            Write-Output "CUR_BRANCH is $CUR_BRANCH"
            if ( ($CUR_BRANCH -eq "master") -or ($CUR_BRANCH -eq "develop") -or ($CUR_BRANCH -eq "main") ) {
                f_git pull
                $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
            }
            else {
                Write-Output "workspace is not master nor develop nor main branch.  skip git pull."
            }
        }
        else {
            Write-Output "workspace is durty.  skip git pull."
        }

        # ローカルブランチの掃除
        if ( $null -ne $BR_LIST ) {
            write-output $BR_LIST | ForEach-Object {
                $BR = $_.trim()
                $HAS_REMOTE = ( echo $BR_LIST_2 | select-string "$BR" )
                # 自分のユーザー名を含むブランチのみお掃除対象
                if ( $BR.contains($GIT_ID) ) {
                    Write-Output " contains $GIT_ID "
                    $STATUS = ( f_git status | select-string "nothing to commit" )
                    if ( $STATUS -eq "" ) {
                        # カレントブランチがdirtyな場合は掃除しない
                        write-output "directory: $GIT_CLONE_DIR , branch: $CUR_BRANCH is not clean. skip git branch -d $BR."
                    }
                    elseif ( $null -ne $HAS_REMOTE ) {
                        # remoteブランチに残っている場合は残す
                        write-output "directory: $GIT_CLONE_DIR , branch: $BR has remote branch. skip git branch -d $BR."
                    }
                    elseif ( $BR -eq $CUR_BRANCH ) {
                        write-output "directory: $GIT_CLONE_DIR , branch: $BR has not remote branch.  remove $BR."
                        # currentブランチがリモートにない場合はデフォルトブランチ名(developまたはmaster)に戻してブランチは削除する
                        f_git checkout $GIT_DEFAULT_BRANCH_NAME
                        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
                        f_git pull
                        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
                        f_git branch -d ${BR}
                        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
                    }
                    else {
                        write-output "directory: $GIT_CLONE_DIR , branch: $BR other case. remove $BR."
                        f_git branch -d ${BR}
                        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
                    }
                }
            }
        }
        write-output ""
        set-location $SAVED_PWD
    }
}

function git-branch-test-tag-exists {
    # 引数で指定した名前のタグが存在するかチェック
    # get first arg and shift
    $ARG_TAG_NAME, $args = $args;
    echo "ARG_TAG_NAME is $ARG_TAG_NAME"
    if ( $ARG_TAG_NAME.Length -eq 0 ) {
        Write-Host "git-branch-test-tag-exists: tag-name"
        $RC = 1
        return
    }
    $RESULT = & git tag -l | select-string -pattern "^${ARG_TAG_NAME}$"
    echo "RESULT is $RESULT"
    if ( $RESULT.Length -eq 0 ) {
        Write-Output "NOTFOUND"
        return
    }
    Write-Output "FOUND"
}

function git-branch-test-local-branch-exists {
    # 引数で指定した名前のローカルブランチが存在するかチェック
    $ARG_BRANCH_NAME, $args = $args;
    if ( $ARG_BRANCH_NAME.Length -eq 0 ) {
        Write-Host "git-branch-test-local-branch-exists: branch-name"
        $RC = 1
        return
    }
    $RESULT = & git branch -a | foreach-object {
        $tmp1 = $_ -replace "^\* ", "  "
        $tmp2 = $tmp1 -replace "^  ", ""
        $tmp3 = $tmp2.Split(" ")[0]
        Write-Output $tmp3
    }  | select-string -pattern "^${ARG_BRANCH_NAME}$"
    if ( $RESULT.Length -eq 0 ) {
        Write-Output "NOTFOUND"
        return
    }
    Write-Output "FOUND"
}

function git-branch-test-remote-branch-exists {
    # 引数で指定した名前のリモートブランチが存在するかチェック
    $ARG_BRANCH_NAME, $args = $args;
    if ( $ARG_BRANCH_NAME.Length -eq 0 ) {
        Write-Output "git-branch-test-remote-branch-exists: branch-name"
        return
    }
    $RESULT = & git branch -a  | foreach-object {
        $tmp1 = $_ -replace "^\* ", "  "
        $tmp2 = $tmp1 -replace "^  ", ""
        $tmp3 = $tmp2.Split(" ")[0]
        Write-Output $tmp3
    } | select-string -pattern "^remotes/origin/${ARG_BRANCH_NAME}$"
    if ( $RESULT.Length -eq 0 ) {
        Write-Output "NOTFOUND"
        return
    }
    Write-Output "FOUND"
}

function git-branch-get-current-branch-name {
    # ローカルのブランチ名を取得する
    $RESULT = & git branch -a | select-string -pattern "^\* "
    $RESULT2 = $RESULT -replace "^\* ", ""
    Write-Output $RESULT2
}

function git-branch-new {
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

    # GITユーザー名を取得する
    $GIT_ID = ( git-user-name )

    $YMD_HMS = ( Get-Date -Format "yyyyMMdd_HHmmss" )
    $DEFAULT_BRANCH_NAME = ( $GIT_ID + "/#" + $YMD_HMS )
    $BRANCH_NAME = $DEFAULT_BRANCH_NAME
    $COMMIT_COMMENT = ""
    $ARG_TAG_LIST = @();

    # 引数解析
    while ( $args.length -gt 0 ) {

        # get first arg and shift
        $a1, $args = $args;

        if ( $a1 -eq "-m" ) {
            # -m comment があった場合は、コミットコメントとして採用。pushまで自動で行う。
            $a2, $args = $args;
            $COMMIT_COMMENT = $a2
            Write-Output "auto commit mode. commit comment : $COMMIT_COMMENT"
        }
        elseif ( $a1 -eq "-n" ) {
            # -n br-name があった場合、ブランチ名の後ろに付加する
            $a2, $args = $args;
            $BRANCH_NAME = "${DEFAULT_BRANCH_NAME}_$a2"
            Write-Output "named branch mode. new branch name : $BRANCH_NAME"
        }
        elseif ( $a1 -eq "-t" ) {
            # -t tag があった場合は、タグ付けまで自動で行う。
            $a2, $args = $args
            $ARG_TAG_LIST += $a2
            Write-Output "auto tag mode. tag : $ARG_TAG_LIST"
        }
        else {
            # 引数があった場合はブランチ名として採用
            $BRANCH_NAME = $a1
            Write-Output "named branch mode. new branch name : $BRANCH_NAME"
        }
    }

    Write-Output "create new branch $BRANCH_NAME"

    # developに戻す
    # f_git checkout develop

    # pullする
    # f_git pull
    # RC=$? ; if [ $RC -ne 0 ]; then return ; fi

    # リモートリポジトリでは削除されているブランチは、削除する
    f_git fetch --prune
    $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }


    # ワークの中に未コミットのファイルがあるかチェック
    $CHKDURTY = ( git-status-check )

    # ローカルブランチが存在するか確認
    $CHK_LOCAL_BRANCH = ( git-branch-test-local-branch-exists $BRANCH_NAME )
    Write-Output "checking local branch ... CHK_LOCAL_BRANCH=$CHK_LOCAL_BRANCH"

    # リモートブランチが存在するか確認
    $CHK_REMOTE_BRANCH = ( git-branch-test-remote-branch-exists $BRANCH_NAME )
    Write-Output "checking remote branch ... CHK_REMOTE_BRANCH=$CHK_REMOTE_BRANCH"

    # 現在のブランチ名とターゲットブランチ名が同じなら、そのまま使う
    $CURRENT_BRANCH_NAME = ( git-branch-get-current-branch-name )
    Write-Output "BRANCH_NAME=$BRANCH_NAME"
    Write-Output "CURRENT_BRANCH_NAME=$CURRENT_BRANCH_NAME"
    if ( $BRANCH_NAME -eq $CURRENT_BRANCH_NAME ) {
        Write-Output "current branch is $BRANCH_NAME. use it."
    }
    else {
        if ( $CHK_LOCAL_BRANCH -eq "FOUND" ) {
            Write-Output "local branch found. "

            # ワーキングに未コミットファイルがある場合、ブランチ変更はできないはず。
            if ( $CHKDURTY -eq "DURTY" ) {
                Write-Output "WARNING working copy is durty. can not change branch."
            }

            # ブランチに切り替え
            f_git checkout $BRANCH_NAME
            $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
        }

        elseif ( $CHK_REMOTE_BRANCH -eq "FOUND" ) {
            Write-Output "remote branch found. "

            # ワーキングに未コミットファイルがある場合、ブランチ変更はできないはず。
            if ( $CHKDURTY -eq "DURTY" ) {
                Write-Output "WARNING working copy is durty. can not change branch."
            }

            # ブランチに切り替え
            f_git checkout $BRANCH_NAME
            $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return; }

        }
        else {
            Write-Output "local / remote branch not found. create it."
            # branchを新しく作成する
            f_git branch $BRANCH_NAME
            $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
            # 作成したブランチに切り替え
            f_git checkout $BRANCH_NAME
            $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
            # 新ブランチは upstream を設定してpush実行
            f_git push --set-upstream origin $BRANCH_NAME
            $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
            # リモート情報を確認
            f_git remote -vv
            $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
        }
    }

    # ブランチの一覧を表示
    f_git branch -vv
    $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }

    # 現在のステータスを表示
    f_git status
    $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }

    Write-Output ""
    Write-Output "  run below commands:"
    Write-Output "    git add <file> ..."
    Write-Output "    git commit -m comment"
    Write-Output "    git push --set-upstream origin $BRANCH_NAME"
    Write-Output ""

    # コミットコメントがある場合は、add / commit / push まで行う
    if ( $COMMIT_COMMENT.length -ne 0 ) {
        f_git add .
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
        f_git commit -m "$COMMIT_COMMENT"
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
        f_git push --set-upstream origin $BRANCH_NAME
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
    }

    # タグ付与が必要ならばタグ付与を行う
    Write-Output $ARG_TAG_LIST |  foreach-object {
        $i = $_
        if ( $COMMIT_COMMENT.length -ne 0) {
            git-branch-tag-and-push -m "$COMMIT_COMMENT" $i
        }
        else {
            git-branch-tag-and-push $i
        }
        $RC = $LASTEXITCODE ; if ($RC -ne 0 ) { return ; }
    }


}

# ブランチの削除を実施
# git-branch-delete branch-name
function git-branch-delete {
    if ( $args.length -eq 0 ) {
        echo "git-branch-delete branch-name"
        return
    }

    # 引数解析
    while ( $args.length -gt 0 ) {

        # 最初の引数を取得
        $BRANCH_NAME, $args = $args;

        # local ブランチの削除
        f_git branch -d ${BRANCH_NAME}
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }

        # remote ブランチの削除
        f_git push origin :${BRANCH_NAME}
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { return ; }
    }
}

# ローカルでtagをつけて、それをpushする
# git tagには -m でメッセージを付けないと git describe で表示時にエラーになる
function git-branch-tag-and-push {
    if ( $args.length -eq 0 ) {
        Write-Output "git-branch-tag-and-push [-m tag-comment] tag-name [tag-name]"
        return
    }

    $COMMIT_COMMENT = "add tag"
    $TAG_NAMES = @();

    # 引数解析
    while ( $args.length -gt 0 ) {

        # get first arg and shift
        $a1, $args = $args;
        $a2, $rest = $args;

        if ( $a1 -eq "-m" ) {
            # -m comment があった場合は、コメントとして採用。
            $COMMIT_COMMENT = $a2
            Write-Output "tag comment : $COMMIT_COMMENT"
            # shift
            $a3, $args = $args;
        }
        else {
            # 引数があった場合はタグ名として採用
            $TAG_NAMES += $a1
            Write-Output "tag name : $a1"
        }
    }

    Write-Output $TAG_NAMES | foreach-object {
        $ARG_TAG = $_
        # 現在のタグ一覧を取得。一致しているものがあったら、削除する。
        $CUR_TAG_LIST = ( f_git tag -l )
        Write-Output $CUR_TAG_LIST | ForEach-Object {
            $i = $_
            if ( $i -eq $ARG_TAG ) {
                Write-Output "git-branch-tag-and-push: tag $ARG_TAG is already set."
                Write-Output "git-branch-tag-and-push: at first , remove tag $ARG_TAG."
                f_git tag -d $ARG_TAG
                $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
                f_git push origin ":$ARG_TAG"
                $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. but continue." ; }
            }
        }
        # タグをつけて、originにpushする。
        f_git tag -m "$COMMIT_COMMENT" $ARG_TAG
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
        f_git push origin $ARG_TAG
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
    }
}

# ローカルでtagを削除して、それをpushする
function git-branch-tag-remove-and-push {
    if ( $args.Length -eq 0 ) {
        Write-Output "git-branch-tag-remove-and-push tag-name"
        return
    }

    Write-Output $args | foreach-object {
        $ARG_TAG = $_
        # 現在のタグ一覧を取得。一致しているものがあったら、削除する。
        $CUR_TAG_LIST = ( f_git tag -l )
        Write-Output $CUR_TAG_LIST | ForEach-Object {
            $i = $_
            if ( $i -eq $ARG_TAG ) {
                Write-Output "git-branch-tag-remove-and-push: remove tag $ARG_TAG."
                f_git tag -d $ARG_TAG
                $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
                f_git push origin ":$ARG_TAG"
                $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
            }
        }
    }
}

# ブランチからブランチにマージを実施する
# arg1 から arg2 にマージする
function git-branch-merge() {
    $MERGE_MESSAGE = "auto merge"
    $ARG_SRC = ""
    $ARG_DST = ""
    $ARG_CNT = 0

    # 引数解析
    while ($args.Length -gt 0) {
        $a1, $args = $args
        $a2, $rest = $args
        if ( $a1 -eq "-m" ) {
            $MERGE_MESSAGE = $a2
        }
        elseif ($ARG_CNT -eq 0) {
            $ARG_SRC = $a1
            $ARG_CNT = $ARG_CNT + 1
        }
        elseif ($ARG_CNT -eq 1) {
            $ARG_DST = $a1
            $ARG_CNT = $ARG_CNT + 1
        }
    }

    # 引数チェック
    if (( $ARG_SRC.Length -eq 0 ) -or ($ARG_DST.Length -eq 0)) {
        Write-Output "git-branch-merge  develop  master  ... merge develop into master"
        return
    }

    # pullする
    f_git pull
    $RC = $LASTEXITCODE ; if ($RC -ne 0) { return ; }

    # マージする先masterをチェックアウトする
    f_git checkout $ARG_DST
    $RC = $LASTEXITCODE ; if ($RC -ne 0) { return ; }

    # pullする
    f_git pull
    $RC = $LASTEXITCODE ; if ($RC -ne 0) { return ; }

    # developをマージする
    f_git merge -m "$MERGE_MESSAGE" $ARG_SRC
    $RC = $LASTEXITCODE ; if ($RC -ne 0) { return ; }

    # commitする
    #f_git commit -m "merge from develop"
    #RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # pushする
    f_git push
    $RC = $LASTEXITCODE ; if ($RC -ne 0) { return ; }

    # developをチェックアウトする
    #f_git checkout $ARG_SRC
    #RC=$? ; if [ $RC -ne 0 ]; then return 1; fi

    # 状態表示
    f_git status
}


# 現在のブランチに対して本家の進捗を取り込んでマージする
# 毎回マージコミットが残るのでちょっと不便
function git-branch-fetch-and-merge {
    $MERGE_MESSAGE = "automatic merge from origin"
    $ARG_SRC = ""
    $ARG_CNT = 0

    # 引数解析
    while ( $args.length -gt 0 ) {

        # get first arg and shift
        $a1, $args = $args;

        if ( $a1 -eq "-m") {
            $a2, $args = $args;
            MERGE_MESSAGE = $a2
        }
        elseif ( $ARG_CNT -eq 0 ) {
            $ARG_SRC = $a1
            $ARG_CNT = $ARG_CNT + 1
        }
    }

    if ( $ARG_SRC -eq 0 ) {
        echo "git-branch-fetch-and-merge  master  ... merge from master into current branch"
        return
    }

    f_git fetch
    $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }

    # master or main からマージする
    f_git merge -m "$MERGE_MESSAGE" origin $ARG_SRC
    $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }

    # 状態表示
    f_git status
}



# 現在のブランチに対してstash push -u してからgit pullしてstash popする
# git stash pop した時に手動マージが発生する
function git-branch-pull-stash {
    $GIT_STATUS = git-status-check
    if ( $GIT_STATUS -eq "DURTY") {
        f_git stash push -u
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
        f_git pull
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
        f_git stash pop
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
    }
    else {
        f_git pull
        $RC = $LASTEXITCODE ; if ( $RC -ne 0 ) { Write-Output "ERROR. abort." ; return ; }
    }
}



# コミットしてpushする
# おひとりさまリポジトリだと一番よく使う
function git-branch-add {
    $COMMIT_COMMENT = ""
    $ARG_TAG_LIST = @();

    # 引数解析
    if ( $args.Length -eq 0 ) {
        Write-Output "git-branch-add    -m commit-comment    -t tag"
    }
    # 引数解析
    while ( $args.length -gt 0 ) {

        $arg1, $args = $args
        if ( $arg1 -eq "-m" ) {
            # -m comment があった場合は、コミットコメントとして採用。pushまで自動で行う。
            $arg2, $args = $args
            $COMMIT_COMMENT = $arg2
            Write-Output "auto commit mode. commit comment : $COMMIT_COMMENT"
        }
        if ( $arg1 -eq "-t" ) {
            # -t tag があった場合は、タグ付けまで自動で行う。
            $arg2, $args = $args
            $ARG_TAG_LIST += $arg2
            Write-Output "auto tag mode. tag : $ARG_TAG_LIST"
        }
    }

    f_git diff
    f_git status

    $GIT_STATUS = git-status-check
    if ( $GIT_STATUS -eq "DURTY") {

        f_git add .
        $RC = $LASTEXITCODE ; if ($RC -ne 0 ) { return ; }

        if ( $COMMIT_COMMENT.length -ne 0) {
            f_git commit -m "$COMMIT_COMMENT"
            $RC = $LASTEXITCODE ; if ($RC -ne 0 ) { return ; }

            f_git push
            $RC = $LASTEXITCODE ; if ($RC -ne 0 ) { return ; }
        }
    }

    Write-Output $ARG_TAG_LIST |  foreach-object {
        $i = $_
        if ( $COMMIT_COMMENT.length -ne 0) {
            git-branch-tag-and-push -m "$COMMIT_COMMENT" $i
        }
        else {
            git-branch-tag-and-push $i
        }
        $RC = $LASTEXITCODE ; if ($RC -ne 0 ) { return ; }
    }
}

#
# 「ええーいリモートが合ってるんだからアイツに合わせたいんだよ！」
# とイライラしたら下記。masterブランチ用。
#
function git-branch-force-master-pull {
    f_git checkout master
    RC=$LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
    f_git fetch origin
    RC=$LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
    f_git reset --hard origin/master
    RC=$LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
}

#
# 「ええーいリモートが合ってるんだからアイツに合わせたいんだよ！」
# とイライラしたら下記。mainブランチ用。
#
function git-branch-force-main-pull {
    f_git checkout main
    RC=$LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
    f_git fetch origin
    RC=$LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
    f_git reset --hard origin/main
    RC=$LASTEXITCODE ; if ( $RC -ne 0 ) { return; }
}

#
# git stash 系のコマンド
#

# workspace上の未追跡ファイルも含めて一時的に退避する。gitワークスペースはcleanな状態になる。
function git-stash-push-u {
    $dateString = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $COMMENT = "stash saved ${dateString}"
    if ($args.Length -gt 0 ) {
        $a1, $args = $args
        COMMENT="$a1"
    }
    f_git stash push -u -m "$COMMENT"
    $RC = $LASTEXITCODE ; if ($RC -ne 0 ) { return ; }
}

# stashから戻す。使用したstashは消す。
function git-stash-pop {
    f_git stash pop
    $RC = $LASTEXITCODE ; if ($RC -ne 0 ) { return ; }
}

# stashの一覧
function git-stash-list {
    f_git stash list
}

# stashの内容表示
function git-stash-show {
    f_git stash show
}

# stashから戻す。popと異なり使用したstashは消さない。
function git-stash-apply {
    if ( $args.Length -eq 0 ) {
        Write-Output "ex: git-stash-apply 0"
        return
    }
    $arg1, $args = $args
    f_git stash apply "stash@{$arg1}"
}

# 指定した番号のstashを消す
function git-stash-drop {
    if ( $args.Length -eq 0 ) {
        Write-Output "ex: git-stash-drop 0"
        return
    }
    $arg1, $args = $args
    f_git stash drop "stash@{$arg1}"
}

# 全てのstashを消す
function git-stash-clear {
    f_git stash clear
}
#
# end of file
#
