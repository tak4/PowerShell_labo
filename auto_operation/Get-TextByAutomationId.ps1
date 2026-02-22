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
$automationId1 = "15"
$automationId2 = "TitleBar"


# --- 設定はここまで ---


# =============================================================================
# ■ スクリプト本体：通常、ここから下を変更する必要はありません
# =============================================================================

# UI Automation関連のアセンブリ（ライブラリ）を読み込む
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# 指定されたAutomationIdを持つUI要素からテキストを取得する関数
function Get-TextByAutomationId {
    param(
        [System.Windows.Automation.AutomationElement]$rootElement,
        [string]$automationId
    )

    try {
        # AutomationId が指定されているかチェック
        if ([string]::IsNullOrEmpty($automationId)) {
            Write-Warning "AutomationId が指定されていません。"
            return $null
        }

        # AutomationId を条件としてUI要素を検索
        $searchCondition = New-Object -TypeName System.Windows.Automation.PropertyCondition -ArgumentList @(
            [System.Windows.Automation.AutomationElement]::AutomationIdProperty,
            $automationId
        )

        Write-Host "AutomationId '$automationId' でUI要素を検索しています..."
        $targetElement = $rootElement.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $searchCondition)

        if (-not $targetElement) {
            Write-Warning "AutomationId '$automationId' に一致するUI要素が見つかりませんでした。"
            return $null
        }
        Write-Host "UI要素が見つかりました: $($targetElement.Current.Name)"

        # テキストの取得
        $text = $null
        $valuePattern = $null
        $textPattern = $null

        if ($targetElement.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$valuePattern)) {
            Write-Host "ValuePattern を使用してテキストを取得します..."
            $text = $valuePattern.Current.Value
        }
        elseif ($targetElement.TryGetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern, [ref]$textPattern)) {
            Write-Host "ValuePatternが見つかりません。TextPattern を使用してテキストを取得します..."
            $text = $textPattern.DocumentRange.GetText(-1).Trim()
        }
        elseif (-not [string]::IsNullOrEmpty($targetElement.Current.Name)) {
            Write-Host "ValuePattern/TextPatternが見つかりません。Nameプロパティ を使用してテキストを取得します..."
            $text = $targetElement.Current.Name
        }
        else {
            Write-Warning "このUI要素はテキスト取得をサポートしていません (ValuePattern, TextPattern, Nameプロパティのすべてが利用不可または空です)。"
            return $null
        }
        return $text
    }
    catch {
        Write-Warning "Get-TextByAutomationId 関数内でエラーが発生しました: $($_.Exception.Message)"
        return $null
    }
}


try {
    # 1. プロセスの取得
    Write-Host "プロセス '$processName' を検索しています..."
    $process = Get-Process -Name $processName -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne [System.IntPtr]::Zero } | Select-Object -First 1

    if (-not $process) {
        throw "プロセス '$processName' が見つからないか、表示されているウィンドウがありません。"
    }

    $windowHandle = $process.MainWindowHandle
    Write-Host "ウィンドウが見つかりました。(ハンドル: $windowHandle)"

    # 2. ウィンドウのルートUI要素を取得
    $rootElement = [System.Windows.Automation.AutomationElement]::FromHandle($windowHandle)
    if (-not $rootElement) {
        throw "ウィンドウのUI要素ツリーを取得できませんでした。"
    }

    # 3. 各AutomationIdでテキストを取得
    $text1 = Get-TextByAutomationId -rootElement $rootElement -automationId $automationId1
    $text2 = Get-TextByAutomationId -rootElement $rootElement -automationId $automationId2

    # 4. 結果を結合
    $combinedText = "--- AutomationId: $automationId1 ---`r`n$text1`r`n`r`n" +
                    "--- AutomationId: $automationId2 ---`r`n$text2`r`n"


    # 5. ファイルへ保存
    Write-Host "ファイルへテキストを保存しています... ($outputFilePath)"
    $parentDir = Split-Path -Path $outputFilePath -Parent
    if (-not (Test-Path -Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    Set-Content -Path $outputFilePath -Value $combinedText -Encoding UTF8

    # 成功メッセージを表示
    Write-Host "`n✅ 処理が正常に完了しました。"
    Write-Host "取得したテキストを '$outputFilePath' に保存しました。"

}
catch {
    # tryブロック内でエラーが発生した場合の処理
    Write-Error "❌ エラーが発生しました: $($_.Exception.Message)"
}
