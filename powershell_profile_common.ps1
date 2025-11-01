#
# powershell 便利関数
#

#
# 共通部
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

# Chocolatey package list
function f-choco-list {
    choco list
    # choco export --include-version-numbers
    # Get-Content ./packages.config
}

# vagrant provider指定 (hyperv or virtualbox)
# 現在Hyper-Vが有効かどうかにしたがって環境変数VAGRANT_DEFAULT_PROVIDERを設定する
function f-hyperv-check {
    if ([string]::IsNullOrEmpty($env:VAGRANT_DEFAULT_PROVIDER)) {
        $RESULT = bcdedit /enum | Select-String "hypervisorlaunchtype"
        if ( Write-Output $RESULT | Select-String "Auto" ) {
            # echo "Hyper-V is ON"
            $env:VAGRANT_DEFAULT_PROVIDER = "hyperv"
        }
        if ( Write-Output $RESULT | Select-String "Off" ) {
            # echo "Hyper-V is OFF"
            $env:VAGRANT_DEFAULT_PROVIDER = "virtualbox"
        }
    }
}

# hyperv check 実施
f-hyperv-check

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
    Write-Output "Rows=30" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "RightClickAction=paste" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Transparency=low" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CursorType=block" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "BackgroundColour=0,30,0" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Language=ja" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "ForegroundColour=255,255,255" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CopyAsRTF=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Locale=ja_JP" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Charset=UTF-8" | Add-Content -Encoding UTF8 "${mintty_config_file}"

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
        & "C:\Program Files\Git\bin\bash.exe" --login
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
# 環境変数 F_MSYS_BASH_FONT_HEIGHT が定義されていればその値を使う
function f-msys-bash {
    $env:HOME = $HOME
    $env:MSYS = "nocase"
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"

    # mintty config file 作成
    $mintty_config_file = "${HOME}/.minttyrc-utf8"
    if ( Test-Path $mintty_config_file ) {
        Remove-Item $mintty_config_file
    }
    # font height
    $font_height = "12"
    if ( $env:F_MSYS_BASH_FONT_HEIGHT -ne "" ) {
        $font_height = $env:F_MSYS_BASH_FONT_HEIGHT
    }
    Write-Output "BoldAsFont=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Ricty Diminished" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Cascadia Mono" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Font=Consolas" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "FontHeight=$font_height" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Columns=120" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Rows=30" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "RightClickAction=paste" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Transparency=low" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CursorType=block" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "BackgroundColour=0,30,0" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Locale=ja_JP" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Charset=UTF-8" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Language=ja" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "ForegroundColour=255,255,255" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "CopyAsRTF=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"

    if ( Test-Path "C:/tools/msys64/usr/bin/mintty.exe" ) {
        $MSYS_MINTTY = "C:/tools/msys64/usr/bin/mintty.exe"
    }
    if ( Test-Path "C:/msys64/usr/bin/mintty.exe" ) {
        $MSYS_MINTTY = "C:/msys64/usr/bin/mintty.exe"
    }

    $old_lang = "$env:LANG"
    $env:LANG = "ja_JP.UTF-8"
    if ( $args.Length -eq 0 ) {
        # 2025.07.10 winpty を経由すると、 Ctrl-C が入力できない。。。
        # & $MSYS_MINTTY --config "${mintty_config_file}" "--exec"  "/usr/bin/winpty" "/usr/bin/bash" "--login" "-i"
        & $MSYS_MINTTY --config "${mintty_config_file}" "--exec"   "/usr/bin/bash" "--login" "-i"
    }
    else {
        # & "C:\Program Files\Git\usr\bin\mintty.exe" --config "${mintty_config_file}"  "/usr/bin/bash"  "--login"  "-c"  "$args"
        & $MSYS_MINTTY --config "${mintty_config_file}"  "/usr/bin/bash"  "--login"  "-c"  "$args"
    }
    $env:LANG = $old_lang
}

# SJIS用のmsys-bash。vagrantは端末の文字コードがSJISでないと怒るので。
function f-msys-bash-sjis {
    $env:HOME = $HOME
    $env:MSYS = "nocase"
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"

    # mintty config file 作成
    $mintty_config_file = "${HOME}/.minttyrc-sjis"
    if ( Test-Path $mintty_config_file ) {
        Remove-Item $mintty_config_file
    }
    # font height
    $font_height = "12"
    if ( $env:F_MSYS_BASH_FONT_HEIGHT -ne "" ) {
        $font_height = $env:F_MSYS_BASH_FONT_HEIGHT
    }
    Write-Output "BoldAsFont=no" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Ricty Diminished" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "# Font=Cascadia Mono" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Font=Consolas" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "FontHeight=$font_height" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Columns=120" | Add-Content -Encoding UTF8 "${mintty_config_file}"
    Write-Output "Rows=30" | Add-Content -Encoding UTF8 "${mintty_config_file}"
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

    if ( Test-Path "C:/tools/msys64/usr/bin/mintty.exe" ) {
        $MSYS_MINTTY = "C:/tools/msys64/usr/bin/mintty.exe"
    }
    if ( Test-Path "C:/msys64/usr/bin/mintty.exe" ) {
        $MSYS_MINTTY = "C:/msys64/usr/bin/mintty.exe"
    }

    $old_lang = "$env:LANG"
    $env:LANG = "ja_JP.SJIS"
    if ( $args.Length -eq 0 ) {
        # & "C:\Program Files\Git\usr\bin\mintty.exe" --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash" --login
        & $MSYS_MINTTY --title "mintty-sjis" --config "${mintty_config_file}" "--exec" "/usr/bin/winpty" "/usr/bin/bash" "--login" "-i"
    }
    else {
        # & "C:\Program Files\Git\usr\bin\mintty.exe" --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash"  --login -c  "$args"
        & $MSYS_MINTTY --title "mintty-sjis" --config "${mintty_config_file}"  "/usr/bin/bash"  --login -c  "$args"
    }
    $env:LANG = $old_lang
}

# PowerShell ウィンドウ内にmsys2 bashの方を起動する
# bash for windows ,  Windows Subsystem for Linux , Ubuntu をインストールすると bash.exe は Ubuntu の方になるので。
function f-msys-bash-here {
    $env:HOME = $HOME
    $env:MSYS = "nocase"
    $env:MSYS2_PATH_TYPE = "inherit"
    $env:CHERE_INVOKING = "enabled_from_arguments"
    # & msys2_shell.cmd -defterm -here -use-full-path -no-start

    # remove Git for Windows PATH
    #f-path-remove "C:\Program Files\Git\cmd"
    #f-path-remove "C:\Program Files\Git\mingw64\bin"
    #f-path-remove "C:\Program Files\Git\usr\bin"
    #f-path-remove "C:\Program Files\Git\bin"

    if ( Test-Path "C:\tools\msys64\usr\bin\bash.exe" ) {
        # prepend MSYS2 PATH
        f-path-prepend "C:\tools\msys64\bin"
        f-path-prepend "C:\tools\msys64\usr\bin"
        f-path-prepend "C:\tools\msys64\usr\local\bin"
        f-path-prepend "C:\tools\msys64\mingw64\bin"
        $MSYS_BASH = "C:\tools\msys64\usr\bin\bash.exe"
    }
    if ( Test-Path "C:\msys64\usr\bin\bash.exe" ) {
        # prepend MSYS2 PATH
        f-path-prepend "C:\msys64\bin"
        f-path-prepend "C:\msys64\usr\bin"
        f-path-prepend "C:\msys64\usr\local\bin"
        f-path-prepend "C:\msys64\mingw64\bin"
        $MSYS_BASH = "C:\msys64\usr\bin\bash.exe"
    }

    if ( $args.Length -eq 0 ) {
        & $MSYS_BASH --login
    }
    else {
        & $MSYS_BASH -c "$args"
    }
}

# PowerShell ウィンドウ内にgit bashの方を起動する
# bash for windows ,  Windows Subsystem for Linux , Ubuntu をインストールすると bash.exe は Ubuntu の方になるので。
function f-msys-bash-here-sjis {
    $env:HOME = $HOME
    $env:MSYS = "nocase"
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
# 使い方サンプル : f-windows-terminal pwsh.exe "$env:GIT_GEORGE_PON_DIR\myopenrepo\furufuru.ps1"
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
        # '"Program Files"' みたいな出力を作る
        $cmd_args += "`'`"$j`"`'"
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

# vagrantのディレクトリに移動してから vagrant-ssh 関数を実行する
# SOCK5環境変数はクリアした上で使用すること。
# ~/.ssh/known_hostsは適宜クリアしておくこと。
function f-vagrant-ssh {
    $sshdata = & vagrant ssh-config
    $targethost = write-output $sshdata | select-string "Hostname " | foreach-object { $_ -replace "HostName", "" }
    $targethost = $targethost.Trim()
    $targetport = write-output $sshdata | select-string "Port " | foreach-object { $_ -replace "Port", "" }
    $targetport = $targetport.Trim()
    $targetuser = write-output $sshdata | select-string "User " | foreach-object { $_ -replace "User", "" }
    $targetuser = $targetuser.Trim()
    $targetidentfile = write-output $sshdata | select-string "IdentityFile " | foreach-object { $_ -replace "IdentityFile", "" }
    $targetidentfile = $targetidentfile -replace "/", "\"
    $targetidentfile = $targetidentfile.Trim()
    & ssh.exe -i ${targetidentfile}  -p ${targetport} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $targetuser@${targethost}
}

# 全体ステータス表示
function f-vagrant-global-status {
    vagrant global-status --prune
}

# 全部のvagrantを停止する
function f-vagrant-poweroff-all {
    # vagrantコマンドチェック
    if ( f-type-silent vagrant ) {
        write-host "vagrant command found."
    }
    else {
        return
    }
    # 開発用ダミーデータ
    $result = @'
id       name   provider   state    directory
----------------------------------------------------------------------------------------
2d90e47  node2  virtualbox poweroff C:/home/git/vagrant/55-vagrant-freebsd12.0-diskadd
9f10aee  node1  virtualbox poweroff C:/home/git/vagrant/11_centos_k3s_1node
4ae0df9  node1  virtualbox running  C:/home/git/vagrant/10_centos_rancher_1node_rke_nfs
'@
    # 実際のデータ取得
    $result = & vagrant global-status
    # 改行で分割
    $lines = $result -split ("\n")
    # 各行でループ
    Write-Output $lines | foreach-object {
        Write-Output "$_"
        $result = $_.trim() -replace "  * ", " "
        $array = $result -split (' ')
        $state = $array[3]
        $vagrantpath = $array[4]
        if ( $state -eq "running" ) {
            Write-Output "state is $state , path is $vagrantpath , do vagrant halt"
            Push-Location $vagrantpath
            vagrant halt
            Pop-Location
        }
    }
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
# New-Item ".\path\to\dir" -ItemType Directory -ErrorAction SilentlyContinue でも良いらしい
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
# ファイルの中の文字列を置換する
#
#  f-sed  from_str  to_str  filename
#
# Get-Contentの部分のカッコは必要。
#
function f-sed {
    # 引数補正
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    # 引数チェック
    if ( $args.length -lt 3) {
        write-host "f-sed from_str to_str filename"
        return
    }

    # 引数解析
    $count = 0
    while ( $args.length -gt 0 ) {
        $arg1, $args = $args
        $count = $count + 1
        if ( $count -eq 1 ) {
            $FROMSTR = $arg1
        }
        elseif ( $count -eq 2 ) {
            $TOSTR = $arg1
        }
        elseif ( $count -eq 3 ) {
            $TARGET = $arg1
        }
    }

    $ENCODING = "UTF8"
    (Get-Content $TARGET -Encoding $ENCODING) | `
        foreach { $_ -replace $FROMSTR, $TOSTR } | `
        Set-Content $TARGET -Encoding $ENCODING

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


# ランダム文字列を生成する
# O と 0 と o は除外
# 1 と l は除外
# 8 と B は除外
# ACDEFGHIJKLMNPQRSTUVWXYZ
# abcdefghijkmnpqrstuvwxyz
# 2345679
function f-random-string-generate {
    $FROM1_STR = ""
    $FROM1_STR = $FROM1_STR + "ACDEFGHIJKLMNPQRSTUVWXYZ"
    $FROM2_STR = ""
    $FROM2_STR = $FROM2_STR + "abcdefghijkmnpqrstuvwxyz"
    $FROM3_STR = ""
    $FROM3_STR = $FROM3_STR + "2345679"
    $FROM4_STR = ""
    $FROM4_STR = $FROM4_STR + $FROM1_STR
    $FROM4_STR = $FROM4_STR + $FROM2_STR
    $FROM4_STR = $FROM4_STR + $FROM3_STR
    # ランダムに16文字を選択
    $random = ""
    $random = $random + -join ((0..($FROM2_STR.Length - 1) | Get-Random -Count 2) | ForEach-Object { $FROM2_STR[$_] })
    $random = $random + -join ((0..($FROM1_STR.Length - 1) | Get-Random -Count 2) | ForEach-Object { $FROM1_STR[$_] })
    $random = $random + -join ((0..($FROM2_STR.Length - 1) | Get-Random -Count 4) | ForEach-Object { $FROM2_STR[$_] })
    $random = $random + -join ((0..($FROM3_STR.Length - 1) | Get-Random -Count 4) | ForEach-Object { $FROM3_STR[$_] })
    $random = $random + -join ((0..($FROM4_STR.Length - 1) | Get-Random -Count 16) | ForEach-Object { $FROM4_STR[$_] })
    echo $random
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

function f-winget-upgrade-all {
    winget upgrade --all
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


#
# edge 操作
#
function f-edge-prof-n {
    $a1 = "1"
    if ( $args.Length -gt 0 ) {
        $a1, $args = $args
    }
    $a2 = ""
    if ( $args.Length -gt 0 ) {
        $a2, $args = $args
    }
    # プロファイルディレクトリ  C:\Users\xxxx\AppData\Local\Microsoft\Edge\User Data\Profile 1
    Set-Location "C:\Program Files (x86)\Microsoft\Edge\Application"
    & .\msedge.exe --profile-directory="Profile $a1" $a2
}

function f-edge-default {
    Set-Location "C:\Program Files (x86)\Microsoft\Edge\Application"
    & .\msedge.exe --profile-directory=Default
}

# kjwikigdocker.war ファイルの dataStorePath を書き換えて tomcat ディレクトリにコピーする
function f-kjwikigdocker-edit-war {
    if ( ! ( Test-Path "kjwikigdocker.war" ) ) {
        write-host "kjwikigdocker.war file not found. abort."
        return 1
    }

    Copy-Item kjwikigdocker.war kjwikigdocker.zip
    if ( ! ( Test-Path "tmpwork" ) ) {
        mkdir -p tmpwork
    }
    Push-Location tmpwork
    unzip ..\kjwikigdocker.zip WEB-INF/classes/kjwikig.properties
    f-sed "authenticationMode=AuthenticationModeMay" "authenticationMode=AuthenticationModeMust"  .\WEB-INF\classes\kjwikig.properties
    f-sed "dataStorePath=/var/lib/kjwikigdocker" "dataStorePath=C:\\var\\lib\\kjwikigdocker"  .\WEB-INF\classes\kjwikig.properties
    zip -u ..\kjwikigdocker.zip .\WEB-INF\classes\kjwikig.properties
    Pop-Location

    Copy-Item kjwikigdocker.zip "C:\Program Files\Apache Software Foundation\Tomcat 10.1\webapps\kjwikigdocker.war"

    Remove-Item -Recurse tmpwork
    Remove-Item kjwikigdocker.zip
}


#
# 各種コマンドPATH設定
#

# add bash.exe and mintty.exe path
if ( Test-Path "C:\Program Files\Git\bin" ) {
    f-path-add "C:\Program Files\Git\bin"
    f-path-add "C:\Program Files\Git\usr\bin"
}

# add VcXsrv path
if ( Test-Path "C:\Program Files\VcXsrv" ) {
    f-path-add "C:\Program Files\VcXsrv"
}

# Docker Desktop for Windows
if ( Test-Path "C:\Program Files\Docker\Docker\resources\bin" ) {
    f-path-prepend "C:\Program Files\Docker\Docker\resources\bin"
}
if ( Test-Path "C:\ProgramData\DockerDesktop\version-bin" ) {
    f-path-prepend "C:\ProgramData\DockerDesktop\version-bin"
}

# Firefox
if ( Test-Path "C:\Program Files\Mozilla Firefox" ) {
    f-path-add "C:\Program Files\Mozilla Firefox"
}

# Chrome
if ( Test-Path "C:\Program Files\Google\Chrome\Application" ) {
    f-path-add "C:\Program Files\Google\Chrome\Application"
}

# sakura editor
if ( Test-Path "C:\Program Files (x86)\sakura" ) {
    f-path-add "C:\Program Files (x86)\sakura"
}

# rapture
if ( Test-Path "$env:PERSONAL_BASE_DIR\01-desktop-tools\rapture-2.4.1" ) {
    f-path-add "$env:PERSONAL_BASE_DIR\01-desktop-tools\rapture-2.4.1"
}

function f-sakura-grep() {
    $searchStr, $args = $args
    $ext = "*"
    if ( $args.Length -gt 0 ) {
        $ext, $args = $args
    }
    $dir = "."
    sakura.exe -GREPMODE -GKEY="$searchStr" -GFILE="*.$ext" -GFOLDER="$dir" -GOPT="SP" -GCODE=99
}

function f-sakura-memo {
    # 引数チェック
    $NEW_SUFFIX = ""
    while ( $args.Length -gt 0 ) {
        $arg1, $args = $args
        if ( $arg1 -eq "-n" ) {
            $arg2, $args = $args
            $NEW_SUFFIX = "_$arg2"
        }
    }
    $NEW_MEMO_FILE = Get-Date -Format "yyyyMMdd_HHmmss"
    $NEW_MEMO_FILE = "$env:PERSONAL_BASE_DIR\Memo_${NEW_MEMO_FILE}${NEW_SUFFIX}.md"
    sakura.exe "$NEW_MEMO_FILE"
}

function f-code-memo {
    # 引数チェック
    $NEW_SUFFIX = ""
    while ( $args.Length -gt 0 ) {
        $arg1, $args = $args
        if ( $arg1 -eq "-n" ) {
            $arg2, $args = $args
            $NEW_SUFFIX = "_$arg2"
        }
    }
    $NEW_MEMO_FILE = Get-Date -Format "yyyyMMdd_HHmmss"
    $NEW_MEMO_FILE = "$env:PERSONAL_BASE_DIR\Memo_${NEW_MEMO_FILE}${NEW_SUFFIX}.md"
    code "$NEW_MEMO_FILE"
}

# listen port 表示
function f-netstat-listen {
    netstat -ant | Select-String -Pattern "TCP" | Select-String -Pattern "LISTENING"
}


#----------------------------------------------------------------------
# Git 関連ディレクトリ
#

if ( "$env:GIT_BASE_DIR" -eq "" ) {
    # GITのベースディレクトリを仮設定
    $env:GIT_BASE_DIR = "C:\home\git"
    # Write-Output "env:GIT_BASE_DIR is set $env:GIT_BASE_DIR"
}

if ( "$env:GIT_GEORGE_PON_DIR" -eq "" ) {
    # オレ専用GITディレクトリ仮設定
    $env:GIT_GEORGE_PON_DIR = "C:\home\git\george-pon"
    # Write-Output "env:GIT_GEORGE_PON_DIR is set $env:GIT_GEORGE_PON_DIR"
}

# mytools path 追加
if ( Test-Path "$env:GIT_GEORGE_PON_DIR\mytools" ) {
    f-path-add "$env:GIT_GEORGE_PON_DIR\mytools"
}

# myopenrepo path 追加
if ( Test-Path "$env:GIT_GEORGE_PON_DIR\myopenrepo" ) {
    f-path-add "$env:GIT_GEORGE_PON_DIR\myopenrepo"
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

function cdgit {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR
}

function cdgitmy {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\george-pon
}

function cdgit-george-pon {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\george-pon
}

function cdmytools {
    $env:HOMEDRIVE
    Set-Location $env:GIT_GEORGE_PON_DIR\mytools
}

function cdmyopenrepo {
    $env:HOMEDRIVE
    Set-Location $env:GIT_GEORGE_PON_DIR\myopenrepo
}

function cdtest1 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test1\test1
}

function cdtest2 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test2\test2
}

function cdtest3 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test3\test3
}

function cdtest4 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test4\test4
}

function cdtest5 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test5\test5
}

function cdtest6 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test6\test6
}

function cdtest7 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test7\test7
}

function cdtest8 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test8\test8
}

function cdtest9 {
    $env:HOMEDRIVE
    Set-Location $env:GIT_BASE_DIR\test9\test9
}



#
# end of file
#
