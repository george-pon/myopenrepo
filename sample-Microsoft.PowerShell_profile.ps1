#
# powershell 7 profile (mytools)
#

#
# 共通部
#

function f-path-show {
    $env:PATH -replace ";", "`n"
}

# 言語設定
$env:LANG = "ja_JP.UTF-8"

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# 個人のベースディレクトリ
if ( Test-Path "$HOME\Desktop\obama"  ) {
    $env:PERSONAL_BASE_DIR = "$HOME\Desktop\obama"
}
elseif ( Test-Path "C:\HOME" ) {
    $env:PERSONAL_BASE_DIR = "C:\HOME"
}

# GITのベースディレクトリ
$checkGitBase = "$env:PERSONAL_BASE_DIR\git"
if ( Test-Path "$checkGitBase" ) {
    $env:GIT_BASE_DIR = "$checkGitBase"
}

# オレ専用GITディレクトリ指定
if ( Test-Path "$env:GIT_BASE_DIR\george-pon" ) {
    $env:GIT_GEORGE_PON_DIR = "$env:GIT_BASE_DIR\george-pon"
}

# read my setup
if ( Test-Path "$env:GIT_GEORGE_PON_DIR\mytools" ) {
    . $env:GIT_GEORGE_PON_DIR\mytools\powershell_profile.ps1
    . $env:GIT_GEORGE_PON_DIR\mytools\git-functions.ps1
    . $env:GIT_GEORGE_PON_DIR\mytools\docker-functions.ps1
    . $env:GIT_GEORGE_PON_DIR\mytools\kubernetes-functions.ps1
}
elseif ( Test-Path "$env:GIT_GEORGE_PON_DIR\myopenrepo" ) {
    . $env:GIT_GEORGE_PON_DIR\myopenrepo\powershell_profile.ps1
    . $env:GIT_GEORGE_PON_DIR\myopenrepo\git-functions.ps1
}

# mytools path 追加
if ( Test-Path "$env:GIT_GEORGE_PON_DIR\mytools" ) {
    f-path-add "$env:GIT_GEORGE_PON_DIR\mytools"
}

# myopenrepo path 追加
if ( Test-Path "$env:GIT_GEORGE_PON_DIR\myopenrepo" ) {
    f-path-add "$env:GIT_GEORGE_PON_DIR\myopenrepo"
}

# maven path 追加
if ( Test-Path "C:/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3/bin" ) {
    f-path-add "C:/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3/bin"
}

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

# prepend bash.exe and mintty.exe path for git for windows SDK
# if ( Test-Path "C:\home\01-desktop-tools\git-for-windows-sdk\usr\bin" ) {
# $env:PATH = "C:\home\01-desktop-tools\git-for-windows-sdk\usr\bin" + ";" + $env:Path
# }
# if ( Test-Path "$env:APPDATA\git-for-windows-sdk\usr\bin" ) {
# $env:PATH = "$env:APPDATA\git-for-windows-sdk\usr\bin" + ";" + $env:Path
# }

#
# 環境依存部
#

#
# 以下はマシンごと設定で上書きすること
#

function f-setup-site-scripts-path {
    # pipでインストールした便利コマンドにpathを通す。
    if ( Test-Path "C:\Users\george\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.10_qbz5n2kfra8p0\LocalCache\local-packages\Python310\Scripts" ) {
        f-path-add "C:\Users\george\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.10_qbz5n2kfra8p0\LocalCache\local-packages\Python310\Scripts"
    }
}
f-setup-site-scripts-path



# 2種類の $profile ファイルを編集する
function f-edit-profile {
    & winmergeu.exe  $HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1  $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
}

# .bashrc のサンプルを更新する
function f-edit-bashrc-sample {
    & winmergeu.exe $HOME\.bashrc    $env:GIT_GEORGE_PON_DIR/mytools/sample-bashrc.sh
}

# powershell profile のサンプルを更新する
function f-edit-powershell-profile-sample {
    & winmergeu.exe  $profile  $env:GIT_GEORGE_PON_DIR/mytools/sample-Microsoft.PowerShell_profile.ps1
}

function cdtomcat {
    C:
    Set-Location "\Program Files\Apache Software Foundation\Tomcat 10.1"
}



#
# end of file
#
