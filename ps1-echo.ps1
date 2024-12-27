#
# コマンドライン引数に指定された文字列をウィンドウ表示する PowerShell
#
# 2024.12.07
#

function f-echo {

    # 引数補正 外部から$argsを渡された場合
    if ( $args.gettype().name -eq "Object[]" ) {
        if ( $args.length -ge 1 ) {
            if ( $args[0].gettype().name -eq "Object[]" ) {
                $args = $args[0]
            }
        }
    }

    # 引数が指定されていない場合、エラーメッセージを表示して終了
    if (-not $args[0]) {
        Write-Host "使用方法: ps1-echo.ps1 <表示する文字列>"
        return 1
    }

    # コマンドライン引数から文字列を取得
    $textToDisplay = ""

    # 引数解析
    while ( $args.length -gt 0 ) {

        # get first arg and shift
        $a1, $args = $args;
        $a2, $rest = $args;

        $textToDisplay += $a1 + " ";
    }

    # 必要なアセンブリを読み込む
    Add-Type -AssemblyName PresentationCore, PresentationFramework

    # WPF ウィンドウを作成
    $window = New-Object System.Windows.Window
    $window.Title = "文字列コピー"
    $window.Width = 500
    $window.Height = 350
    $window.WindowStartupLocation = "CenterScreen"

    # StackPanel (レイアウト) を作成
    $stackPanel = New-Object System.Windows.Controls.StackPanel
    $stackPanel.Margin = "10"

    # テキストエリア (スクロール可能なテキストボックス) を作成
    $textArea = New-Object System.Windows.Controls.TextBox
    $textArea.Text = $textToDisplay
    $textArea.Margin = "0,0,0,10"
    $textArea.HorizontalAlignment = "Stretch"
    $textArea.VerticalAlignment = "Stretch"
    $textArea.AcceptsReturn = $true
    $textArea.TextWrapping = "Wrap"
    $textArea.VerticalScrollBarVisibility = "Auto"
    $textArea.IsReadOnly = $true
    $textArea.Height = 150
    $textArea.SelectAll()

    # メッセージエリア (コピー完了メッセージを表示するラベル) を作成
    $messageArea = New-Object System.Windows.Controls.TextBlock
    $messageArea.Text = ""
    $messageArea.Margin = "0,10,0,10"
    $messageArea.HorizontalAlignment = "Center"
    $messageArea.TextAlignment = "Center"
    $messageArea.Foreground = [System.Windows.Media.Brushes]::Green
    $messageArea.FontSize = 14

    # ボタンを作成
    $button = New-Object System.Windows.Controls.Button
    $button.Content = "クリップボードにコピー"
    $button.Width = 200
    $button.HorizontalAlignment = "Center"

    # ボタンのクリックイベントを定義
    $button.Add_Click({
            Add-Type -AssemblyName PresentationCore
            [System.Windows.Clipboard]::SetText($textArea.Text)
            $messageArea.Text = "文字列がクリップボードにコピーされました！"
        })

    # レイアウトに要素を追加
    $stackPanel.Children.Add($textArea)
    $stackPanel.Children.Add($button)
    $stackPanel.Children.Add($messageArea)

    # ウィンドウにレイアウトを設定
    $window.Content = $stackPanel

    # ウィンドウを表示
    $window.ShowDialog()
    return
}

f-echo $args

#
# end of file
#
