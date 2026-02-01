<#
.SYNOPSIS
WindowsデスクトップアプリケーションのUI要素からテキストを取得し、ファイルに保存します。AutomationIdを使用して要素を検索します。

.DESCRIPTION
このスクリプトは、Windows UI Automation を利用して、指定したプロセス（アプリケーション）内で、指定した AutomationId を持つUI要素（テキストボックスなど）を検索し、その内容をテキストファイルとして保存するものです。
スクリプト冒頭の「設定項目」を、お使いの環境に合わせて修正してご利用ください。

.EXAMPLE
# メモ帳（notepad.exe）で AutomationId が "15" の要素（テキスト入力欄）の内容を、デスクトップの 'captured_text.txt' に保存する場合
# （スクリプトのデフォルト設定）
.\Get-TextByAutomationId.ps1
#>

# =============================================================================
# ■ 設定項目：ここを環境に合わせて変更してください
# =============================================================================

# 1. 対象アプリケーションのプロセス名
#    タスクマネージャーの「詳細」タブで確認できる、".exe" を除いた名前です。
#    例: "notepad", "putty", "explorer"
$processName = "notepad"

# 2. テキストを保存するファイルパス
#    取得したテキストをどこに保存するかを指定します。
#    $env:USERPROFILE はユーザーのホームディレクトリ（例: C:\Users\YourName）を指します。
$outputFilePath = "$env:USERPROFILE\Desktop\captured_text_by_id.txt"

# 3. テキストボックスを特定するための AutomationId
#    ウィンドウ内のどのUI要素からテキストを抽出するかを指定するためのIDです。
#
#    ★ AutomationId を調べる方法 ★
#    Microsoft公式ツール「Accessibility Insights for Windows」を使うと、アプリケーションの
#    UI要素のプロパティ（AutomationId, Name, ControlTypeなど）を簡単に確認でき、
#    正確なID指定に役立ちます。
#
#    以下は、Win32版メモ帳のメインのテキスト入力欄の AutomationId "15" を指定する例です。
$automationId = "15"


# --- 設定はここまで ---


# =============================================================================
# ■ スクリプト本体：通常、ここから下を変更する必要はありません
# =============================================================================

# UI Automation関連のアセンブリ（ライブラリ）を読み込む
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

try {
    # AutomationId が指定されているかチェック
    if ([string]::IsNullOrEmpty($automationId)) {
        throw "AutomationId が指定されていません。スクリプト上部の `$automationId` を設定してください。"
    }

    # 1. プロセスの取得
    Write-Host "プロセス '$processName' を検索しています..."
    # 指定されたプロセス名で実行中のプロセスを取得し、ウィンドウハンドルを持つ（＝表示されているウィンドウがある）ものを最初の1つだけ選択
    $process = Get-Process -Name $processName -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne [System.IntPtr]::Zero } | Select-Object -First 1

    # プロセスが見つからなかった場合の処理
    if (-not $process) {
        throw "プロセス '$processName' が見つからないか、表示されているウィンドウがありません。"
    }

    # 見つかったウィンドウのハンドル（一意の識別子）を取得
    $windowHandle = $process.MainWindowHandle
    Write-Host "ウィンドウが見つかりました。(ハンドル: $windowHandle)"

    # 2. ウィンドウのルートUI要素を取得
    #    ウィンドウハンドルを元に、UI Automationツリーの起点となる要素を取得します。
    $rootElement = [System.Windows.Automation.AutomationElement]::FromHandle($windowHandle)
    if (-not $rootElement) {
        throw "ウィンドウのUI要素ツリーを取得できませんでした。"
    }

    # 3. AutomationId を条件としてテキストボックスを検索
    $searchCondition = New-Object -TypeName System.Windows.Automation.PropertyCondition -ArgumentList @(
        [System.Windows.Automation.AutomationElement]::AutomationIdProperty,
        $automationId
    )

    Write-Host "AutomationId '$automationId' でUI要素を検索しています..."
    # Descendantsスコープで、ルート要素配下のすべての子孫要素から条件に一致する最初の要素を探す
    $targetElement = $rootElement.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $searchCondition)

    # UI要素が見つからなかった場合の処理
    if (-not $targetElement) {
        throw "AutomationId '$automationId' に一致するUI要素が見つかりませんでした。`n'Accessibility Insights for Windows' などのツールでIDを確認してください。"
    }
    Write-Host "UI要素が見つかりました: $($targetElement.Current.Name)"

    # 4. テキストの取得
    $text = $null
    # UI要素からテキストを取得するには、いくつかのパターン（方法）があるため、順番に試行します。

    # パターンA: ValuePattern を試す (書き込み可能なテキストボックスでよく使われる)
    $valuePattern = $null
    $textPattern = $null
    # TryGetCurrentPatternは、パターンがサポートされていればtrueを返し、第二引数にパターンオブジェクトを格納する
    if ($targetElement.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$valuePattern)) {
        Write-Host "ValuePattern を使用してテキストを取得します..."
        $text = $valuePattern.Current.Value
    }
    # パターンB: TextPattern を試す (読み取り専用の要素やドキュメントなどで使われる)
    elseif ($targetElement.TryGetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern, [ref]$textPattern)) { # $textPattern を [ref] で渡す
        Write-Host "ValuePatternが見つかりません。TextPattern を使用してテキストを取得します..."
        # ドキュメント全体の範囲を取得し、そのテキストを-1（すべて）取得し、前後の余白を削除
        $text = $textPattern.DocumentRange.GetText(-1).Trim()
    }
    # パターンC: Nameプロパティを試す (上記パターンが使えない場合の代替手段)
    elseif (-not [string]::IsNullOrEmpty($targetElement.Current.Name)) {
        Write-Host "ValuePattern/TextPatternが見つかりません。Nameプロパティ を使用してテキストを取得します..."
        $text = $targetElement.Current.Name
    }
    # すべてのパターンが失敗した場合
    else {
        throw "このUI要素はテキスト取得をサポートしていません (ValuePattern, TextPattern, Nameプロパティのすべてが利用不可または空です)。"
    }

    # 5. ファイルへ保存
    Write-Host "ファイルへテキストを保存しています... ($outputFilePath)"
    # 保存先パスの親ディレクトリが存在するか確認
    $parentDir = Split-Path -Path $outputFilePath -Parent
    if (-not (Test-Path -Path $parentDir)) {
        # 存在しない場合は、ディレクトリを作成する
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    # Set-Contentでファイルにテキストを書き込む。文字コードはUTF-8を指定。
    Set-Content -Path $outputFilePath -Value $text -Encoding UTF8

    # 成功メッセージを表示
    Write-Host "`n✅ 処理が正常に完了しました。"
    Write-Host "取得したテキストを '$outputFilePath' に保存しました。"

}
catch {
    # tryブロック内でエラーが発生した場合の処理
    # $_.Exception.Message でエラーメッセージ本文を取得して表示
    Write-Error "❌ エラーが発生しました: $($_.Exception.Message)"
}
