﻿#
# powershell 便利関数
#

function f-getcwd {
    # スクリプトの実行位置を取得。
    $result = $PSScriptRoot
    if ( $result -eq "" ) {
        $result = (Get-Location).tostring()
    }
    return $result
}


# IPv4アドレスを取得する関数。第1引数に "イーサネット" などのアダプタ名をとる。
function f-get-ipv4 {
    # 引数受け取り
    $arg1, $rest = $args

    $interface = (Get-NetIPAddress | Where-Object { $_.InterfaceAlias -eq $arg1 } )
    if ( ! $interface ) {
        return "null"
    }

    $ipv4obj = (Get-NetIPAddress | Where-Object { $_.InterfaceAlias -eq $arg1 } | Where-Object { $_.AddressFamily -eq "IPv4" } )
    if ( ! $ipv4obj ) {
        return "null"
    }

    $ipv4 = $ipv4obj.IPAddress
    if ( ! $ipv4 ) {
        return "null"
    }
    return $ipv4
}

# 環境変数 DEFAULT_IPV4_ADDR
if ( "" -eq "$env:DEFAULT_IPV4_ADDR" ) {
    # Ethernetとアダプタ名のつくものを選択しています。
    # IPv4を選択しています。
    #
    # このファイルがUTF-8で書かれているとエラーになってしまうな・・・。 UTF-8 with BOM でファイルを書かないといけない。
    $interfaceAliasName = "イーサネット"
    $ipv4addr = f-get-ipv4 $interfaceAliasName
    if ( "null" -eq $ipv4addr ) {
        $interfaceAliasName = "Wi-Fi"
        $ipv4addr = f-get-ipv4 $interfaceAliasName
    }
    if ( "null" -eq $ipv4addr ) {
        $interfaceAliasName = "Wi-Fi 2"
        $ipv4addr = f-get-ipv4 $interfaceAliasName
    }
    if ( "null" -eq $ipv4addr ) {
        Write-Output "Can not Get IPv4 Address"
    }
    else {
        $env:DEFAULT_IPV4_ADDR = (Get-NetIPAddress | Where-Object { $_.InterfaceAlias -eq $interfaceAliasName } | Where-Object { $_.AddressFamily -eq "IPv4" } ).IPAddress
        $env:DEFAULT_IPV4_ADDR = $env:DEFAULT_IPV4_ADDR.Trim()
        $buffer = $env:DEFAULT_IPV4_ADDR.Split(" ")
        $env:DEFAULT_IPV4_ADDR = $buffer[0]
        $env:DEFAULT_IPV4_ADDR = $env:DEFAULT_IPV4_ADDR.Trim()
        Write-Output "DEFAULT_IPV4_ADDR=$env:DEFAULT_IPV4_ADDR"
    }
}

# 環境変数DISPLAY設定
if ( "" -eq "$env:DISPLAY" ) {
    if ( "" -eq "$env:DEFAULT_IPV4_ADDR" ) {
        $hostname = & hostname
        $env:DISPLAY = "${hostname}:0.0"
    }
    else {
        $env:DISPLAY = "${env:DEFAULT_IPV4_ADDR}:0.0"
    }
}

# powershell プロンプトを指定する
function prompt {
    "PS " + $env:USERNAME + "@" + $env:COMPUTERNAME + " " + $(get-location) + " > "
}


# 別ウィンドウでminttyを開いてgit bashを起動する
# 引数があればコマンドと見なして実行する
function f-git-bash {

    # mintty config file 作成
    $mintty_config_file = "${HOME}/.minttyrc"
    if ( Test-Path $mintty_config_file ) {
        Remove-Item $mintty_config_file
    }
    Write-Output "BoldAsFont=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Ricty Diminished" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Consolas" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Font=Cascadia Mono" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "FontHeight=12" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Columns=120" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Rows=28" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "RightClickAction=paste" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Transparency=low" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CursorType=block" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "BackgroundColour=0,30,0" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Language=ja" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "ForegroundColour=255,255,255" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CopyAsRTF=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"

    if ( $args.Length -eq 0 ) {
        & "C:/Program Files/Git/usr/bin/mintty.exe" --config "${mintty_config_file}" "--exec" "/usr/bin/bash"  "--login" "-i"
    }
    else {
        & "C:/Program Files/Git/usr/bin/mintty.exe" --config "${mintty_config_file}" "--exec" "/usr/bin/bash"  "--login" "-c" "$args"
    }
}

# 別ウィンドウでminttyを開いてgit bashを起動する
# 引数があればコマンドと見なして実行する
function f-git-bash-sjis {

    # mintty config file 作成
    $mintty_config_file = "${HOME}/.minttyrc-sjis"
    if ( Test-Path $mintty_config_file ) {
        Remove-Item $mintty_config_file
    }
    Write-Output "BoldAsFont=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Ricty Diminished" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Font=Consolas" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Cascadia Mono" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "FontHeight=14" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Columns=92" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Rows=26" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "RightClickAction=paste" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Transparency=low" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CursorType=block" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "BackgroundColour=0,30,0" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Language=ja" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "ForegroundColour=255,255,255" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CopyAsRTF=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Locale=ja_JP" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Charset=SJIS" | Add-Content -Encoding UTF8 "${mintty_config_file}"

    $old_lang = "$env:LANG"
    $env:LANG = "ja_JP.SJIS"

    if ( $args.Length -eq 0 ) {
        & "C:/Program Files/Git/usr/bin/mintty.exe" --config "${mintty_config_file}" "--exec" "/usr/bin/bash"  "--login" "-i"
    }
    else {
        & "C:/Program Files/Git/usr/bin/mintty.exe" --config "${mintty_config_file}" "--exec" "/usr/bin/bash"  "--login" "-c" "$args"
    }
    $env:LANG = $old_lang
}

# sudo git bash terminal
# 環境変数を引き継がないモードになるので使い勝手は微妙
function f-sudo-git-bash {
    $cmd_prog = 'C:/Program Files/Git/usr/bin/mintty.exe'
    if ( $args.Length -eq 0 ) {
        # カンマ区切りの引数を生成する
        $cmd_args = f-list-to-comma-str("/usr/bin/bash", "--login")
        powershell start-process "'$cmd_prog'" -ArgumentList $cmd_args -verb runas
    }
    else {
        # カンマ区切りの引数を生成する
        $cmd_args = f-list-to-comma-str("/usr/bin/bash", "--login", "-c", $args)
        powershell start-process "'$cmd_prog'" -ArgumentList $cmd_args -verb runas
    }
}

# PowerShell ウィンドウ内にgit bashの方を起動する
# bash for windows ,  Windows Subsystem for Linux , Ubuntu をインストールすると bash.exe は Ubuntu の方になるので。
# MSYS2がインストールされていると結局MSYS2の環境が使われる...。
function f-git-bash-here {
    if ( $args.Length -eq 0 ) {
        & "C:\Program Files\Git\bin\bash.exe"
    }
    else {
        & "C:\Program Files\Git\bin\bash.exe" -c "$args"
    }
}

# msys64のbashを起動。winpty経由で起動する。時々テキストの行が2行ほと飛んで入れ替わる謎。
# mintty の設定ファイルは、 /etc/minttyrc, $APPDATA/mintty/config, ~/.config/mintty/config, ~/.minttyrc, の順に検索する。
# ~/.minttyrc をコピーして、 .minttyrc-utf8 を作成する。
function f-msys-bash-via-winpty {
    $env:HOME = $HOME
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"
    # mintty config file 作成
    $mintty_config_file = "${HOME}/.minttyrc-utf8"
    Copy-Item "${HOME}/.minttyrc" "${mintty_config_file}"
    Write-Output "Locale=ja_JP" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Charset=UTF-8" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    if ( $args.Length -eq 0 ) {
        & "C:/tools/msys64/usr/bin/mintty.exe" --config "${mintty_config_file}" "--exec"  "/usr/bin/winpty" "/usr/bin/bash" "--login" "-i"
    }
    else {
        & "C:/tools/msys64/usr/bin/mintty.exe" --config "${mintty_config_file}"  "/usr/bin/bash"  "--login"  "-c"  "$args"
    }
}

# msys64のbashを起動。paste動作確認用。貼り付け時に少し待ってEnterの入力が必要だがpaste入力は安定する。
# mintty の設定ファイルは、 /etc/minttyrc, $APPDATA/mintty/config, ~/.config/mintty/config, ~/.minttyrc, の順に検索する。
# ~/.minttyrc をコピーして、 .minttyrc-utf8 を作成する。
function f-msys-bash {
    $env:HOME = $HOME
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"

    # mintty config file 作成
    $mintty_config_file = "${HOME}/.minttyrc-utf8"
    if ( Test-Path $mintty_config_file ) {
        Remove-Item $mintty_config_file
    }
    Write-Output "BoldAsFont=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Ricty Diminished" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Consolas" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Font=Cascadia Mono" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "FontHeight=12" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Columns=120" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Rows=28" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "RightClickAction=paste" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Transparency=low" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CursorType=block" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "BackgroundColour=0,30,0" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Locale=ja_JP" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Charset=UTF-8" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Language=ja" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "ForegroundColour=255,255,255" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CopyAsRTF=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"

    $old_lang = "$env:LANG"
    $env:LANG = "ja_JP.UTF-8"
    if ( $args.Length -eq 0 ) {
        & "C:/tools/msys64/usr/bin/mintty.exe" --config "${mintty_config_file}" "--exec"  "/usr/bin/bash" "--login" "-i"
    }
    else {
        # & "C:\Program Files\Git\usr\bin\mintty.exe" --config "${mintty_config_file}"  "/usr/bin/bash"  "--login"  "-c"  "$args"
        & "C:/tools/msys64/usr/bin/mintty.exe" --config "${mintty_config_file}"  "/usr/bin/bash"  "--login"  "-c"  "$args"
    }
    $env:LANG = $old_lang
}

# SJIS用のmsys-bash。vagrantは端末の文字コードがSJISでないと怒るので。
function f-msys-bash-sjis {
    $env:HOME = $HOME
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"

    # mintty config file 作成
    $mintty_config_file = "${HOME}/.minttyrc-sjis"
    if ( Test-Path $mintty_config_file ) {
        Remove-Item $mintty_config_file
    }
    Write-Output "BoldAsFont=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Ricty Diminished" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Consolas" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Font=Cascadia Mono" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "FontHeight=12" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Columns=120" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Rows=28" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "RightClickAction=paste" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Transparency=low" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CursorType=block" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "BackgroundColour=0,30,0" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Locale=ja_JP" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Charset=UTF-8" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Language=ja" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "ForegroundColour=255,255,255" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CopyAsRTF=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Locale=ja_JP" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Charset=SJIS" | Add-Content -Encoding UTF8 "${mintty_config_file}"

    $old_lang = "$env:LANG"
    $env:LANG = "ja_JP.SJIS"
    if ( $args.Length -eq 0 ) {
        # & "C:\Program Files\Git\usr\bin\mintty.exe" --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash" --login
        & "C:/tools/msys64/usr/bin/mintty.exe" --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash" --login
    }
    else {
        # & "C:\Program Files\Git\usr\bin\mintty.exe" --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash"  --login -c  "$args"
        & "C:/tools/msys64/usr/bin/mintty.exe" --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash"  --login -c  "$args"
    }
    $env:LANG = $old_lang
}

# PowerShell ウィンドウ内にmsys2 bashの方を起動する
# bash for windows ,  Windows Subsystem for Linux , Ubuntu をインストールすると bash.exe は Ubuntu の方になるので。
function f-msys-bash-here {
    $env:HOME = $HOME
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"
    # & msys2_shell.cmd -defterm -here -use-full-path -no-start

    # remove Git for Windows PATH
    #f-path-remove "C:\Program Files\Git\cmd"
    #f-path-remove "C:\Program Files\Git\mingw64\bin"
    #f-path-remove "C:\Program Files\Git\usr\bin"
    #f-path-remove "C:\Program Files\Git\bin"

    # prepend MSYS2 PATH
    f-path-prepend "C:\tools\msys64\bin"
    f-path-prepend "C:\tools\msys64\usr\bin"
    f-path-prepend "C:\tools\msys64\usr\local\bin"
    f-path-prepend "C:\tools\msys64\mingw64\bin"

    if ( $args.Length -eq 0 ) {
        & "C:\tools\msys64\usr\bin\bash" --login
    }
    else {
        & "C:\tools\msys64\usr\bin\bash" -c "$args"
    }
}

# PowerShell ウィンドウ内にgit bashの方を起動する
# bash for windows ,  Windows Subsystem for Linux , Ubuntu をインストールすると bash.exe は Ubuntu の方になるので。
function f-msys-bash-here-sjis {
    $env:HOME = $HOME
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"
    # LANGの設定
    $old_lang = "$env:LANG"
    $env:LANG = "ja_JP.SJIS"
    # & msys2_shell.cmd -defterm -here -use-full-path -no-start
    if ( $args.Length -eq 0 ) {
        & "C:\tools\msys64\usr\bin\bash" --login
    }
    else {
        & "C:\tools\msys64\usr\bin\bash" --login -c "$args"
    }
    $env:LANG = $old_lang
}

# sudo msys bash terminal
# 環境変数を引き継がないモードになるので使い勝手は微妙
function f-sudo-msys-bash {
    $env:HOME = $HOME
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"
    if ( $args.Length -eq 0 ) {
        # カンマ区切りの引数を生成する
        $cmd_args = f-list-to-comma-str("/usr/bin/bash", "--login")
        powershell start-process "C:/tools/msys64/usr/bin/mintty.exe" -ArgumentList $cmd_args -verb runas
    }
    else {
        # カンマ区切りの引数を生成する
        $cmd_args = f-list-to-comma-str("/usr/bin/bash", "--login", "-c", $args)
        powershell start-process "C:/tools/msys64/usr/bin/mintty.exe" -ArgumentList "$cmd_args" -verb runas
    }
}


# 仮想マシンプラットフォーム一覧(WSL2やWindowsサンドボックスで使う)
function f-virtual-machine-platform-list {
    hcsdiag list
}

#----------------------------------------------------------------------
# for wsl
#

# WSL bash
function f-wsl-bash {
    # Write-Output "bash.exe interface is deprecated."
    # & "C:\Windows\System32\bash.exe"

    # WSL側に引き継ぎたい環境変数
    $env:WSLENV = "DEFAULT_IPV4_ADDR"

    if ( $args.Length -eq 0 ) {
        & wsl.exe bash
    }
    else {
        & wsl.exe bash -c "$args"
    }
}

# WSL list
function f-wsl-list {
    & wsl --list -v
}

function f-wsl-shutdown {
    if ( f-type-silent wsl ) {
        wsl --shutdown
    }
}



#
# PATH操作関数
#

function f-path-show {
    $env:PATH -replace ";", "`n"
}

# PATHに追加する。すでにある場合は何もしない。
function f-path-add {
    foreach ( $j in $args ) {
        $localpath = $env:PATH
        $localarray = $localpath -split ";"
        $hitflag = 0
        foreach ( $i in $localarray) {
            if ( $i -eq $j ) {
                $hitflag = 1
                break
            }
        }
        if ( $hitflag -eq 0 ) {
            if ( $env:PATH.Length -gt 0 ) {
                $lastchar = $env:PATH.Substring($env:PATH.Length - 1, 1);
                if ( $lastchar -ne ";" ) {
                    $env:PATH += ";"
                }
            }
            $env:PATH += $j
            # Write-Output "add to PATH ... $j"
        }
    }
}

# PATHの先頭に追加する。すでにある場合は一度消して先頭に追加する。
function f-path-prepend {
    foreach ( $j in $args ) {
        $localpath = $env:PATH
        $localarray = $localpath -split ";"
        $hitflag = 0
        foreach ( $i in $localarray) {
            if ( $i -eq $j ) {
                $hitflag = 1
                break
            }
        }
        if ( $hitflag -ne 0 ) {
            f-path-remove "$j"
        }
        $env:PATH = $j + ";" + $env:PATH
        # Write-Output "prepend to PATH ... $j"
    }
}

# PATHから指定のパスを取り除く。存在しない場合は何もしない。
function f-path-remove {
    $localpath = $env:PATH
    $localarray = $localpath -split ";"
    $result = "";
    foreach ( $j in $localarray ) {
        $hitflag = 0
        foreach ( $i in $args) {
            if ( $i -eq $j ) {
                $hitflag = 1
                # Write-Output "remove from PATH ... $i"
            }
        }
        if ( $hitflag -eq 0 ) {
            if ( $result -gt 0 ) {
                $lastchar = $result.Substring($result.Length - 1, 1);
                if ( $lastchar -ne ";" ) {
                    $result += ";"
                }
            }
            $result += $j
        }
    }
    # 結果の格納
    if ( $result.Length -gt 0 ) { $env:PATH = $result }
}

# PATHからcygwin1.dllが存在するパスを取り除く。存在しない場合は何もしない。
function f-path-remove-cygwin1dll {
    if ( $args.Length -eq 0 ) {
        $args = "cygwin1.dll"
    }
    $localpath = $env:PATH
    $localarray = $localpath -split ";"
    $result = "";
    foreach ( $j in $localarray ) {
        $hitflag = 0
        foreach ( $i in $args ) {
            # ディレクトリが存在する
            if ( Test-Path $j ) {
                # ディレクトリの下に指定ファイルが存在する
                if ( test-path $j/$i ) {
                    $hitflag = 1
                    Write-Output "remove from PATH ... $j"
                }
            }
        }
        if ( $hitflag -eq 0 ) {
            if ( $result.Length -gt 0 ) {
                $lastchar = $result.Substring($result.Length - 1, 1);
                if ( $lastchar -ne ";" ) {
                    $result += ";"
                }
            }
            $result += $j
        }
    }
    # 結果の格納
    if ( $result.Length -gt 0 ) { $env:PATH = $result }
}

# add bash.exe and mintty.exe path ( Git for Windows )
if ( Test-Path "C:\Program Files\Git\bin" ) {
    f-path-add "C:\Program Files\Git\bin"
    f-path-add "C:\Program Files\Git\usr\bin"
}

# add VcXsrv path
if ( Test-Path "C:\Program Files\VcXsrv" ) {
    f-path-add "C:\Program Files\VcXsrv"
}



# for Cygwin
# chocolateyでインストールしたrsyncのdllをパスから外さないといけない
# C:\ProgramData\chocolatey\lib\rsync\cwRsync_5.5.0_x86_Free\bin\
# cygwin.dllバージョン違いでコマンドが実行できなくなる
function f-cygwin-bash {
    # 末尾が - の場合は、ログイン起動する動作。
    # & C:\tools\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico -

    # 長く書くとログイン動作は以下になる。
    # & C:\tools\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico  --exec /usr/bin/bash --login -i

    # パス文字列のバックアップを取得
    $bkupcygwinbashpath = $env:PATH
    if ( $args.Length -eq 0 ) {
        # loginしないで現在の環境変数を引き継いで起動する場合
        # 以下を使う場合は、cygwin側の ~/.bashrc の中で、 PATH=/usr/local/bin:/usr/bin:$PATH ; export PATH をしておく必要がある。
        #f-path-remove-cygwin1dll
        #f-path-remove "C:\ProgramData\chocolatey\lib\rsync\cwRsync_5.5.0_x86_Free\bin"
        #f-path-remove "C:\Program Files\Git\bin"
        #f-path-remove "C:\Program Files\Git\usr\bin"

        # bash に --login オプションをつけておけば、環境変数は一度クリアされ色々と初期化されるが、
        # 環境変数が引き継がれないとかカレントディレクトリが変わるなど不便な点もある。
        # & C:\tools\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico  --exec /usr/bin/bash --login -i
        & C:\tools\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico  --exec /usr/bin/bash  -i
    }
    else {
        # loginしないで現在の環境変数を引き継いで起動する場合
        # 以下を使う場合は、cygwin側の ~/.bashrc の中で、 PATH=/usr/local/bin:/usr/bin:$PATH ; export PATH をしておく必要がある。
        #f-path-remove-cygwin1dll
        #f-path-remove "C:\ProgramData\chocolatey\lib\rsync\cwRsync_5.5.0_x86_Free\bin"
        #f-path-remove "C:\Program Files\Git\bin"
        #f-path-remove "C:\Program Files\Git\usr\bin"

        # bash に --login オプションをつけておけば、環境変数は一度クリアされ色々と初期化されるが、
        # 環境変数が引き継がれないとかカレントディレクトリが変わるなど不便な点もある。
        # 環境変数PATHが空っぽになるのがつらいｗ
        # cygwin側の .bash_profile または .bashrc の中で PATH の設定が必要になる
        & C:\tools\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico --hold always  --exec  /usr/bin/bash --rcfile /home/george/.bash_profile -c  "$args"
    }
    # PATH文字列を復元
    $env:Path = $bkupcygwinbashpath
}

# 別ウィンドウでPowerShellを実行
function f-powershell {
    if ( $args.Length -eq 0 ) {
        Start-Process powershell.exe
    }
    else {
        $proc = Start-Process powershell.exe -PassThru -ArgumentList $args
        $proc.WaitForExit()
    }
}


# 同じウィンドウでPowerShellを実行
function f-powershell-here {
    if ( $args.Length -eq 0 ) {
        powershell.exe
    }
    else {
        powershell.exe -Command "$args"
    }
}


function f-sudo-powershell {
    if ( $args.Length -eq 0 ) {
        Start-Process powershell.exe -Verb runas
    }
    else {
        $proc = Start-Process powershell.exe -Verb runas -PassThru -ArgumentList $args
        $proc.WaitForExit()
    }
}

# for powershell-core 7
function f-pwsh {
    if ( $args.Length -eq 0 ) {
        Start-Process pwsh.exe
    }
    else {
        $proc = Start-Process pwsh.exe -PassThru -ArgumentList "-i -c $args"
        # $proc.WaitForExit()
    }
}

# 同じウィンドウでPowerShellを実行
function f-pwsh-here {
    if ( $args.Length -eq 0 ) {
        pwsh.exe
    }
    else {
        pwsh.exe -Command "$args"
    }
}

function f-sudo-pwsh {
    if ( $args.Length -eq 0 ) {
        Start-Process pwsh.exe -Verb runas
    }
    else {
        $proc = Start-Process pwsh.exe -Verb runas -PassThru -ArgumentList "-i -c $args"
        # $proc.WaitForExit()
    }
}

#
# Windows Terminal
#
function f-windows-terminal {
    if ( $args.Length -eq 0 ) {
        wt.exe new-tab --startingDirectory "$PWD"
    }
    else {
        wt.exe new-tab --startingDirectory "$PWD" $args
    }
}

# 引数のリストをカンマ区切りの文字列に変換する
function f-list-to-comma-str {
    # 引数補正
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    # カンマ区切りの引数を生成する
    $cmd_args = ""
    foreach ( $j in $args ) {
        if ( $cmd_args.length -ne 0 ) {
            $cmd_args += ","
        }
        $cmd_args += "$j"
    }
    return $cmd_args
}

# sudo windows terminal
function f-sudo-windows-terminal {
    if ( $args.Length -eq 0 ) {
        # カンマ区切りの引数を作成する
        $cmd_args = f-list-to-comma-str("--startingDirectory", "$PWD")
        # powershell Start-Process wt -Verb runas
        powershell Start-Process wt -ArgumentList "$cmd_args" -Verb runas
    }
    else {
        # カンマ区切りの引数を作成する
        $cmd_args = f-list-to-comma-str("--startingDirectory", "$PWD", $args)
        # powershell Start-Process wt -Verb runas
        powershell Start-Process wt -ArgumentList "$cmd_args" -Verb runas
    }
}


# マウスふるふる(PowerShell版) ver.2.0  (C)2020 INASOFT/T.Yabuki
# 50秒おきに、マウスを微妙に左右に揺らし、スクリーン セーバー等への移行の阻止を試みます。
# Ctrl+C を押すか、[×]ボタンを押すと終了。
# https://www.inasoft.org/talk/h202005a.html 「マウスふるふる」の機能を実現するPowerShellスクリプトを作ってみる - INASOFT 管理人のふたこと
function f-furufuru {
    # 実行時には特権が必要
    Set-ExecutionPolicy RemoteSigned -Scope Process

    # .NETのCursorクラスを利用するためにSystem.Windows.Formsをロード
    add-type -AssemblyName System.Windows.Forms

    $signature = @'
        [DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
        public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
'@

    $SendMouseEvent = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions -passThru

    echo "Ctrl+Cで終了します。"

    # マウス移動
    $MOUSEEVENTF_MOVE = 0x00000001

    # スリープ秒数
    $SleepSec = 50

    # マウスの振れ幅
    # ・マウスの移動イベント生成用の振れ幅
    $MoveMouseDistance = 1
    # ・マウスの座標を左右にずらす用の振れ幅
    $MoveMouseDistanceX = 1

    # 偶数回数目は左へ、奇数回数目で右へずらすためのフラグ
    $Flag = $true

    # 永久ループ
    while ($true) {
        # スリープ
        Start-Sleep $SleepSec

        # 現在のマウスのX,Y座標を取得
        $x = [System.Windows.Forms.Cursor]::Position.X
        $y = [System.Windows.Forms.Cursor]::Position.Y

        # マウス座標を少しずらす（マウスイベントを監視するOS(スクリーンセーバー、スリープ)対策）
        $SendMouseEvent::mouse_event($MOUSEEVENTF_MOVE, - $MoveMouseDistance, 0, 0, 0)

        # マウス座標を少し右にずらす（マウスイベントを監視するOS(スクリーンセーバー、スリープ)対策）
        $SendMouseEvent::mouse_event($MOUSEEVENTF_MOVE, $MoveMouseDistance, 0, 0, 0)

        # 座標を監視するアプリ対策(座標を左か右に1ピクセル分ずらすだけにする)
        if ($Flag) {
            $x += $MoveMouseDistanceX
            $Flag = $false;
        }
        else {
            $x -= $MoveMouseDistanceX
            $Flag = $true
        }
        [System.Windows.Forms.Cursor]::Position = new-object System.Drawing.Point($x, $y)
        $x = [System.Windows.Forms.Cursor]::Position.X
        $y = [System.Windows.Forms.Cursor]::Position.Y
    }

}



# chromeをシークレットモードで起動する
function f-chrome-secret {
    & "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --incognito  https://www.yahoo.co.jp/
}

# すぐに再起動する
function f-shutdown-r-now {
    f-vagrant-poweroff-all
    shutdown.exe /r /t 5 /f
}

# すぐにシャットダウンする
function f-shutdown-h-now {
    f-vagrant-poweroff-all
    shutdown.exe /s /t 5 /f
}

# 8時間後にシャットダウンする
function f-shutdown-h-8-hours {
    f-vagrant-poweroff-all
    shutdown.exe /s /t 28800
}

# afxwを別ウィンドウで起動する
# 起動中のafxw画面を使う場合は -s オプションを追加すること
function f-afxw {
    AFXW.EXE -L"$PWD\\" -R"$PWD\\"
}

function f-which {
    Get-Command $args | Format-List
}

function f-utf8 {
    chcp 65001
    $env:LANG = "ja_JP.UTF-8"
}

function f-sjis {
    chcp 932
    $env:LANG = "ja_JP.SJIS"
}

# ファイル名の一覧と抽出
function f-find {
    $pat, $rest = $args
    if ( $args.length -eq 0 ) {
        get-childitem -recurse -exclude ".git/" | foreach-object { $_.FullName }
    }
    else {
        get-childitem -recurse -exclude ".git/" | foreach-object { $_.FullName } | foreach-object { write-output $_ | select-string -pattern $pat }
    }
}

# ファイルの内容で検索する
function f-find-grep {
    $pat, $rest = $args
    $srcdir, $rest = $rest
    get-childitem -recurse -exclude ".git/" $srcdir  | foreach-object { if ( ! $_.PSIsContainer ) { Write-Output $_.FullName } } | foreach-object { select-string -pattern $pat -path $_ }
}

# ファイルの内容で検索する
function f-grep-r {
    $pat, $rest = $args
    $srcdir, $rest = $rest
    get-childitem -recurse -exclude ".git/" $srcdir  | foreach-object { if ( ! $_.PSIsContainer ) { Write-Output $_.FullName } } | foreach-object { select-string -pattern $pat -path $_ }
}



# bashのtypeみたいなコマンド
function f-type {
    $cmd, $args = $args
    Get-Command  $cmd | Select-Object -ExpandProperty Definition
}

# コマンドが存在するかチェックだけする
# コマンドが存在すればTrueを返却
function f-type-silent {
    $cmd, $args = $args
    Get-Command  $cmd  -ea SilentlyContinue | Out-Null
    $RC = $?
    return $RC
}

# bash の time みたいなコマンド
function f-bash-time {
    # 引数補正
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    $Command = "$args"
    Measure-Command { Invoke-Expression $Command 2>&1 | out-default }
}

# BOMなしUTF-8テキストファイル(LF)をカレントディレクトリに作成する
# $textにヒアドキュメント @' ～ '@ で複数行のテキスト内容を設定。
# # ヒアドキュメントで設定した文字列の改行コードはLFになる。
# f-write-to-text-file-utf8  sample.txt  $text
function f-write-to-text-file-utf8 {
    $file, $text = $args
    $dir = Get-Location
    $outfile = $dir.tostring() + '\' + $file
    [IO.File]::WriteAllLines($outfile, $text);
}


# BOMなしUTF-8テキストファイル(CRLF)をカレントディレクトリに作成する
# $textにヒアドキュメント @' ～ '@ で複数行のテキスト内容を設定。
# ヒアドキュメントで設定した文字列の改行コードはLFになるようなので、string[]に変換する。
# WriteAllLinesは、改行コードはCRLFで出力する
#
# 使い方 f-write-to-text-file-utf8-crlf  sample.txt  $text
#
function f-write-to-text-file-utf8-crlf {
    $file, $text = $args
    $dir = Get-Location
    $outfile = $dir.tostring() + '\' + $file
    $text2 = $text.Replace("`r", "")
    $textarray = $text2.Split("`n")
    [IO.File]::WriteAllLines($outfile, $textarray);
}


# Windows CPU 負荷が30%以下で安定するのを待つ
function f-windows-wait-cpu-ready {
    $cpu_rate = 30
    $num_count = 10
    $outputfile = "output.csv"

    while ( $TRUE ) {
        if ( Test-Path $outputfile ) {
            Remove-Item  $outputfile
        }
        $formatted_date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Write-Output "$formatted_date waiting for typeperf.exe $num_count seconds..."
        $sc_count = $num_count + 2
        typeperf.exe  -sc $sc_count -o $outputfile  "\processor(_total)\% processor time"
        $cpu_table = Import-Csv $outputfile  -Encoding Default  -Header "col1", "col2"
        $sum = 0
        $cnt = 0
        $ave = 0
        foreach ( $cpu_line in $cpu_table ) {
            $d = 0
            if ( [double]::TryParse($cpu_line.col2, [ref] $d) ) {
                $sum += $d
                $cnt++
            }
        }
        $ave = $sum / $cnt
        Write-Output "sum is $sum , cnt is $cnt , ave is $ave"
        if ( $ave -lt $cpu_rate ) {
            Write-Output "CPU ready"
            break
        }
        else {
            Get-Content $outputfile
            Start-Sleep 5
        }
    }
    Remove-Item $outputfile
}


#
# mkdir -p 相当
#
function f-mkdir {
    # 引数補正
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    while ( $args.length -gt 0 ) {

        # 引数１個取得
        $a1, $rest = $args
        $args = $rest

        if ( ! (Test-Path "$a1") ) {
            New-Item -ItemType Directory -Path "$a1" -Force
        }

    }
}

#
# rm -rf 相当。 .git は特殊な属性を持っているので icacls と takeown で属性を変えてから消す。
#
function f-rm-rf-force {
    # 引数補正
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
        $target_dir, $rest = $args;
        $args = $rest

        if ( test-path "$target_dir" ) {

            # whoami は hostname\username という結果を返すので、デバイス名とユーザー名に分割する
            $whoami = whoami
            $device_name , $user_name = $whoami.Split("\")

            # 削除 (rm -rf) に相当
            Write-Output "removing ... ${target_dir}"
            Remove-Item "$target_dir" -Recurse -Force
            if ( $LASTEXITCODE -ne 0 ) {
                return $LASTEXITCODE
            }
        }
    }
}


#
# ファイル属性を現在のユーザーのものに設定する。 icacls と takeown で属性を変える。
#
function f-takeown-rf {
    # 引数補正
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
        $target_dir, $rest = $args;
        $args = $rest

        if ( test-path "$target_dir" ) {

            # whoami は hostname\username という結果を返すので、デバイス名とユーザー名に分割する
            $whoami = whoami
            $device_name , $user_name = $whoami.Split("\")

            # 所有者変更 (Linux の chown に相当)
            #  /r はサブフォルダーを含めて再帰的に処理
            Write-Output "takeown ... ${target_dir}"
            takeown /s $device_name /u $user_name /f "$target_dir" /r
            if ( $LASTEXITCODE -ne 0 ) {
                return $LASTEXITCODE
            }

            # 権限変更 (chmod に相当)
            #   :F は指定ユーザーにフルコントロール権限を与えるフラグ
            #   /T はサブフォルダーを含めて再帰的に処理
            Write-Output "icacls ... ${target_dir}"
            icacls "$target_dir" /grant ${user_name}:F /T
            if ( $LASTEXITCODE -ne 0 ) {
                return $LASTEXITCODE
            }

        }
    }
}


#
# 便利関数。配列の中からランダムで選択する。
#
# 使い方。 $result = f-random-select-array "a" "b" "c"
#
function f-random-select-array {

    # 引数補正 外部から$argsを渡された場合
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    $array = $args
    $i = Get-Random
    $i = ($i % $array.length)
    $result = $array[$i]
    return $result
}



function f-edit-hosts {
    notepad.exe  \windows\system32\drivers\etc\hosts
}

# PowerShellのプロファイルの編集。PowerShell6 と PowerShell5 同時。
function f-edit-profile {
    & winmergeu.exe "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" "C:\Users\george\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
}


# 16桁のパスワードを生成する
function f-generate-password {
    (1..16) | ForEach-Object {
        $str = -join ((1..16) | ForEach-Object { Get-Random -input ([char[]]((48..57) + (65..90) + (97..122))) })
        Write-Output $str
    }
}



#----------------------------------------------------------------------
# ドライブレターの一覧を取得する
# ドライブ変更を行っていない場合はCurrentLocationが空になるので、条件によっては良くない。。。
function f-get-drive-letter-list {
    return Get-PSDrive -PSProvider FileSystem | ForEach-Object { if ( $_.CurrentLocation ) { Write-Output $_.Name } }
}

#----------------------------------------------------------------------
# 各 disk の idle percent の最大値を取得する
#
function f-getDiskPerf {
    $max_idle = 0;

    # ドライブレターの一覧を取得する
    $driveList = f-get-drive-letter-list

    foreach ( $drv in $driveList ) {
        $samples = Get-Counter -Counter "\LogicalDisk(${drv}:)\% Disk Time" -SampleInterval 1 -MaxSamples 3;
        $idle = $samples.CounterSamples.CookedValue | Measure-Object -Average | Select-Object -ExpandProperty Average;
        Write-Output "idle : $idle"
        if ( $idle -gt $max_idle ) {
            $max_idle = $idle
        }
    }

    Write-Output "max_idle : $max_idle"
    return $max_idle
}



# ------------------------------------------------
# Windows イベントを表示する
# powershell 6 だと動かない；；
function f-event-log {
    # イベントの種類一覧
    Get-EventLog -list

    # システムイベントの最新１５件
    Get-EventLog System -newest 15

    # アプリイベントの最新１５件
    Get-EventLog Application -newest 15

    # Windows PowerShell イベントの最新１５件
    Get-EventLog "Windows PowerShell" -newest 15
}


#
# Javaの環境設定
#
function f-java-setup {
    $dir_list = @( "C:\Program Files\OpenJDK\jdk-13.0.2" )
    # $dir_list = @( "C:\Program Files\OpenJDK\jdk-12.0.2" )
    $dir_list += Get-ChildItem "C:\Program Files\OpenJDK" | foreach-object { $_.FullName } | Sort-Object -Descending
    foreach ( $i in $dir_list ) {
        if ( Test-Path "$i/bin" ) {
            $env:JAVA_HOME = "$i"
            f-path-remove "$i/bin"
            f-path-prepend "$i/bin"
            Write-Output "set JAVA_HOME to $env:JAVA_HOME"
            break
        }
    }
}

#
# python の venv の初期化
#
function f-python-venv {
    if ( Test-Path "./venv/Scripts/Activate.ps1" ) {
        . ./venv/Scripts/Activate.ps1
    }
    f-type python
}


function f-cat-hosts {
    Get-Content "c:\Windows\System32\drivers\etc\hosts"
}


function f-invoke-webrequest {
    # キャッシュ付き invoke webrequest

    $uri = ""
    $outfile = ""

    # 引数補正
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    # ワーキングディレクトリを取得
    if ( $null -eq $work_dir ) {
        $work_dir = f-getcwd
    }
    elseif ( $work_dir -eq "" ) {
        $work_dir = f-getcwd
    }

    # 引数処理ループ
    while ( $args.length -gt 0 ) {

        # 引数１個取得
        $a1, $rest = $args
        $args = $rest

        if ( $a1 -eq "-Uri" ) {
            # 引数１個取得
            $a2, $rest = $args
            $args = $rest
            $uri = $a2
        }
        elseif ( $a1 -eq "-Outfile" ) {
            # 引数１個取得
            $a2, $rest = $args
            $args = $rest
            $outfile = $a2
        }
        else {
            echo "invalid argument $a1 abort."
            return
        }

    }

    # 引数チェック
    if ( $uri -eq "" ) {
        echo "f-invoke-webrequest needs -Uri uri"
        return
    }
    if ( $outfile -eq "" ) {
        echo "f-invoke-webrequest needs -Outfile file"
        return
    }

    # キャッシュディレクトリの準備
    $cache_dir = "$work_dir\web-req-cache"
    echo "cache_dir is $cache_dir"
    if ( ! (Test-Path "$cache_dir") ) {
        # キャッシュディレクトリを新規作成
        New-Item -ItemType Directory -Path $cache_dir -Force
    }

    # ファイル名取得
    $cache_file_name = Split-Path $outfile -Leaf
    $cache_file_name = $cache_dir + "/" + $cache_file_name
    echo "cache_file_name is $cache_file_name"

    # 出力先チェック
    if ( Test-Path $outfile ) {
        echo "output file $outfile is already exist. return."
        return
    }

    # キャッシュの中にあればコピー
    if ( Test-Path $cache_file_name ) {
        echo "use cache file. copy it."
        Copy-Item "$cache_file_name" "$outfile"
        return
    }

    # 取得処理
    Invoke-Webrequest -Uri $uri  -Outfile $outfile

    # キャッシュにコピー
    Copy-Item "$outfile" "$cache_file_name"
}


#-----------------------------------------------------
# 登録ディレクトリ
#

function cdhome {
    $env:HOMEDRIVE
    Set-Location $env:HOMEPATH
}

function cdd {
    $env:HOMEDRIVE
    Set-Location $HOME\Desktop
}

function cdappdata {
    $env:HOMEDRIVE
    Set-Location $env:APPDATA
}



function f-winget-upgrade-all {
    winget upgrade --all
}

#
# end of file
#