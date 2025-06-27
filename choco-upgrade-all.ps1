#
#  chocolatey アップグレード用シェル
#
#  スキップするヤツが居ると面倒なので
#
#  2019.12.20
#

# proxy設定
# choco config set proxy <locationandport>
# choco config set proxyUser <username> #optional
# choco config set proxyPassword <passwordThatGetsEncryptedInFile> # optional
# choco config set proxyBypassList "'<bypasslist, comma separated>'" # optional, Chocolatey v0.10.4 required
# choco config set proxyBypassOnLocal true # optional, Chocolatey v0.10.4 required
#
# proxy設定解除
# choco config unset proxy
#


# vagrant は全部止める
f-vagrant-poweroff-all

# WSLも止める
wsl.exe --shutdown

# アップデート用コマンド  (virtualboxは除く)
# choco upgrade -y  all  --except="'virtualbox'"

# アップデート用コマンド (全部)
choco upgrade -y  all

# アップデート用コマンド (全部)（プロキシ設定無視）
# choco upgrade -y  all --proxy=

# あるパッケージの過去バージョンも検索
# choco search ruby --all-versions | Sort-Object
# choco search GoogleChrome --all-versions | Sort-Object
# choco search chromedriver --all-versions | Sort-Object
# choco search nodejs.install --all-versions | Sort-Object
# choco search virtualbox  --all-versions | Sort-Object



# vagrant 2.2.9 は調子が悪い模様。 2020.05.22
# choco upgrade -y  all --proxy=  --except="'vagrant'"

# virtualbox 7.0.20 は調子が悪い。vagrantに認識されない。
# choco upgrade -y  all --proxy=  --except="'virtualbox'"

# バージョン固定でインストールするコマンド。vagrantの場合は手動でコントロールパネルからvagrantをアンインストールしてから実施。
# choco install vagrant --version=2.2.8 --force --yes

# バージョン固定 vagrant 6.0系 強制インストールコマンド
# choco install virtualbox --version=6.0.14 --force --yes

# バージョン固定でChromeをインストール
# choco install GoogleChrome --version=84.0.4147.135 --force --yes --ignore-checksums
# choco install chromedriver --version=84.0.4147.300 --force --yes

