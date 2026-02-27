#
# リモートデスクトップにパスワード入力無しでログインするバッチファイル,powershell
# https://orebibou.com/2015/06/%E3%83%AA%E3%83%A2%E3%83%BC%E3%83%88%E3%83%87%E3%82%B9%E3%82%AF%E3%83%88%E3%83%83%E3%83%97%E3%81%AB%E3%83%91%E3%82%B9%E3%83%AF%E3%83%BC%E3%83%89%E5%85%A5%E5%8A%9B%E7%84%A1%E3%81%97%E3%81%A7%E3%83%AD/ リモートデスクトップにパスワード入力無しでログインするバッチファイル | 俺的備忘録 〜なんかいろいろ〜
#
# 2020.01.23
#
#  f-remote-desktop /user "username" /pass "password" /ip "192.168.1.2"
#

function f-remote-desktop-connect {

    $SERVER = ""
    $USERNAME = ""
    $PASSWORD = ""

    # 引数補正 外部から$argsを渡された場合
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    # 引数解析
    while ( $args.length -gt 0 ) {

        # get first arg and shift
        $a1, $args = $args;
        $a2, $rest = $args;

        if ( $a1 -eq "/user" ) {
            $USERNAME = $a2
            $a1, $args = $args;
            Write-Output "USERNAME is set to $USERNAME"
        } elseif ( $a1 -eq "/pass" ) {
            $PASSWORD = $a2
            $a1, $args = $args;
            Write-Output "PASSWORD is set to $PASSWORD"
        } elseif ( $a1 -eq "/ip" ) {
            $SERVER = $a2
            $a1, $args = $args;
            Write-Output "SERVER is set to $SERVER"
        } else {
            Write-Output "unknown option $a1 . abort."
            return 1
        }
    }

    if ( $USERNAME -eq "" ) {
        Write-Output "f-remote-desktop-connect  /ip ip-address /user username /pass password"
        return 0
    }
    if ( $PASSWORD -eq "" ) {
        Write-Output "f-remote-desktop-connect  /ip ip-address /user username /pass password"
        return 0
    }
    if ( $SERVER -eq "" ) {
        Write-Output "f-remote-desktop-connect  /ip ip-address /user username /pass password"
        return 0
    }

    # 認証情報登録
    Cmdkey /generic:TERMSRV/$SERVER /user:$USERNAME /pass:$PASSWORD
    # リモートデスクトップ接続
    Start-Process mstsc -ArgumentList "/v:$SERVER", "/w:1280", "/h:768"
    # ちょっと待機
    Start-Sleep 5
    # 認証情報解除
    Cmdkey /delete:TERMSRV/$SERVER

}

# スクリプトの引数をコピーしておく
$script_args = $args

f-remote-desktop-connect $script_args

#
# end of file
#
