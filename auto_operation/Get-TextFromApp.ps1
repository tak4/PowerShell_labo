<#
.SYNOPSIS
Windowsデスクトップアプリケーションのテキストボックスからテキストを取得し、ファイルに保存します。

.DESCRIPTION
このスクリプトは、Windows UI Automation を利用して、指定したプロセス（アプリケーション）内のUI要素（テキストボックスなど）を検索し、
その内容をテキストファイルとして保存するものです。
スクリプト冒頭の「設定項目」を、お使いの環境に合わせて修正してご利用ください。

.EXAMPLE
# メモ帳（notepad.exe）のテキスト入力欄の内容を、デスクトップの 'captured_text.txt' に保存する場合
# （スクリプトのデフォルト設定）
.\Get-TextFromApp_with_comments_ja.ps1
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
$outputFilePath = "$env:USERPROFILE\Desktop\captured_text.txt"

# 3. テキストボックスを特定するための条件
#    ウィンドウ内のどのUI要素からテキストを抽出するかを指定するための条件です。
#
#    ★ 要素のプロパティを調べる方法 ★
#    Microsoft公式ツール「Accessibility Insights for Windows」を使うと、アプリケーションの
#    UI要素のプロパティ（AutomationId, Name, ControlTypeなど）を簡単に確認でき、
#    正確な条件指定に役立ちます。
#
#    【よく使われるプロパティ】
#    - ControlType: 要素の種類（Edit, Document, Text, Paneなど）
#    - AutomationId: 開発者によって割り当てられた一意のID
#    - Name: ユーザーに見えるラベル名
#    - ClassName: ウィンドウのクラス名
#
#    以下は、メモ帳のメインのテキスト入力欄を指定する例です。

# UI Automation関連のアセンブリ（ライブラリ）を読み込む
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# 設定項目に AutomationId と ElementName を追加
$automationId = $null # AutomationId で検索する場合に指定
$elementName = "テキスト エディター" # Name で検索する場合に指定 (UWP版メモ帳のテキストエリアの名前)

# 条件を配列として定義します。
$conditions = @()

# ControlType が 'Document' であること (メモ帳のテキストエリア)
$conditions += New-Object -TypeName System.Windows.Automation.PropertyCondition -ArgumentList @(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Document
)

# AutomationId が指定されている場合、条件に追加
if (-not [string]::IsNullOrEmpty($automationId)) {
    $conditions += New-Object -TypeName System.Windows.Automation.PropertyCondition -ArgumentList @(
        [System.Windows.Automation.AutomationElement]::AutomationIdProperty,
        $automationId
    )
}

# Name が指定されている場合、条件に追加
if (-not [string]::IsNullOrEmpty($elementName)) {
    $conditions += New-Object -TypeName System.Windows.Automation.PropertyCondition -ArgumentList @(
        [System.Windows.Automation.AutomationElement]::NameProperty,
        $elementName
    )
}


# 配列から $null の要素（コメントアウトされた行などによって生じる可能性がある）を取り除く
$conditions = $conditions | Where-Object { $_ -ne $null }

# --- 設定はここまで ---


# =============================================================================
# ■ スクリプト本体：通常、ここから下を変更する必要はありません
# =============================================================================

try {
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

    # 3. 条件を結合してテキストボックスを検索
    $searchCondition = $null
    if ($conditions.Count -eq 1) {
        # 条件が1つだけの場合は、そのまま使用
        $searchCondition = $conditions[0]
    } elseif ($conditions.Count -gt 1) {
        # 条件が複数ある場合は、AndConditionで結合 (すべての条件に一致する要素を探す)
        $searchCondition = New-Object System.Windows.Automation.AndCondition($conditions)
    } else {
        # 条件が1つも指定されていない場合はエラー
        throw "テキストボックスを特定するための条件が指定されていません。"
    }

    Write-Host "指定された条件でUI要素を検索しています..."
    # Descendantsスコープで、ルート要素配下のすべての子孫要素から条件に一致する最初の要素を探す
    $textBoxElement = $rootElement.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $searchCondition)

    # UI要素が見つからなかった場合の処理
    if (-not $textBoxElement) {
        throw "指定された条件に一致するUI要素が見つかりませんでした。`n'Accessibility Insights for Windows' などのツールで条件を確認してください。"
    }
    Write-Host "UI要素が見つかりました: $($textBoxElement.Current.Name)"

    # 4. テキストの取得
    $text = $null
    # UI要素からテキストを取得するには、いくつかのパターン（方法）があるため、順番に試行します。

    # パターンA: ValuePattern を試す (書き込み可能なテキストボックスでよく使われる)
    $valuePattern = $null
    $textPattern = $null
    # TryGetCurrentPatternは、パターンがサポートされていればtrueを返し、第二引数にパターンオブジェクトを格納する
    if ($textBoxElement.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$valuePattern)) {
        Write-Host "ValuePattern を使用してテキストを取得します..."
        $text = $valuePattern.Current.Value
    }
    # パターンB: TextPattern を試す (読み取り専用の要素やドキュメントなどで使われる)
    elseif ($textBoxElement.TryGetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern, [ref]$textPattern)) { # $textPattern を [ref] で渡す
        Write-Host "ValuePatternが見つかりません。TextPattern を使用してテキストを取得します..."
        # ドキュメント全体の範囲を取得し、そのテキストを-1（すべて）取得し、前後の余白を削除
        $text = $textPattern.DocumentRange.GetText(-1).Trim()
    }
    # パターンC: Nameプロパティを試す (上記パターンが使えない場合の代替手段)
    elseif (-not [string]::IsNullOrEmpty($textBoxElement.Current.Name)) {
        Write-Host "ValuePattern/TextPatternが見つかりません。Nameプロパティ を使用してテキストを取得します..."
        $text = $textBoxElement.Current.Name
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