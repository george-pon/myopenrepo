

# awkのように、文字列を空白で区切って配列を作って返却する
function f-awk-like-split-space {

    # 引数補正 外部から$argsを渡された場合
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    # 結果格納配列
    $resultArray = @()

    # 引数解析
    while ( $args.length -gt 0 ) {

        # get first arg and shift
        $a1, $args = $args;
        $a2, $rest = $args;

        if ( $a1 -eq "--help" ) {
            write-host "f-awk-like-split-space abc def ghi"
            return 0
        }
        else {
            $resultArray += ($a1 -split "\s+")
        }
    }

    return $resultArray
}


function f-winget-upgrade-all {

    # PowerShell 5の場合は Shift_JIS（CP932）で受け取る
    # [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(932)
    # PowerShell 7 以降ではUTF-8が良い
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    $update_list = @()

    # upgrade 対象を１行ずつ処理
    winget upgrade | ForEach-Object {
        $line = "$_"
        $str = $line.Substring($idx)
        $array = f-awk-like-split-space $str
        $cnt = 0
        if ( $array.Length -gt 5) {
            # 右からカウントして４個目の要素を拾う
            for ( $i = $array.Length - 1 ; $i -ge 0 ; $i--) {
                $col = $($array[$i])
                if ( $col -eq "<" ) {
                    continue
                }
                $cnt++
                if ( $cnt -eq 4) {
                    if ( $col -eq "-") {
                        continue
                    }
                    else {
                        write-host "upgradeable " $col
                        $update_list += $col
                    }
                }
            }
        }
    }

    # upgrade 対象を１行ずつ処理
    for ( $i = 0 ; $i -lt $update_list.Length ; $i++ ) {
        $id = $($update_list[$i])
        if ( $id -eq "-") {
            continue
        }
        write-host "winget update $id"
        winget update $id
    }
}


f-winget-upgrade-all

