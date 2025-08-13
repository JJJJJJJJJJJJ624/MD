Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding  = [System.Text.Encoding]::UTF8

# ==== 0. パス定義 ====
$Root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManDir   = Join-Path $Root 'src'
$OutHtml  = Join-Path $Root 'output/html'
$OutPdf   = Join-Path $Root 'output/pdf'
$Share    = Join-Path $Root 'shared'
$ErrDir   = Join-Path $ManDir 'Err'

# バージョン情報を保存するテキストファイルのパス
$versionFile = Join-Path $Root "latest_versions.txt"

$Css      = Join-Path $Share 'style.css'
# $Js       = Join-Path $Share 'script.js'
$Js       = Join-Path $Share 'script.html'
$Filter   = Join-Path $Share 'filter.lua'
$HTML_Filter   = Join-Path $Share 'html_filter.lua'
$HTML_Temlate = Join-Path $Share 'template.html'
$TeX_Temlate = Join-Path $Share 'template.tex'
$Header   = Join-Path $Share 'header.tex'
$Pandoc   = 'pandoc'

# ==== 0. バージョン情報読み込み ====
# テキストを「ディレクトリパス|バージョン」の形で記録している想定
$storedVersions = @{}
if (Test-Path $versionFile) {
    $lines = Get-Content $versionFile | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and $_ -notmatch '^#'
    }
    foreach ($line in $lines) {
        $parts = $line -split '\|'
        if ($parts -is [System.Array] -and $parts.Count -ge 2) {
            $dir = $parts[0]
            $ver = $parts[1]
            $storedVersions[$dir] = $ver
        }
    }
}


# ====  ShortPathの取得    ====
#function Get-ShortPath($path) {
#    $fso = New-Object -ComObject Scripting.FileSystemObject
#    return $fso.GetFile($path).ShortPath
#}

# ==== 1. バージョン比較関数 ====
function Compare-Version {
    param ([string]$a,
        [string]$b)

    # a,b が空なら "0" にしておく
    if ([string]::IsNullOrEmpty($a)) {
        $a = "0"
    }
    if ([string]::IsNullOrEmpty($b)) {
        $b = "0"
    }
    # '.' で分割し、try-catch で数値変換できない部分は 0 とみなす
    $segA = @($a.Split('.') | ForEach-Object {
        try {
            [int]$_
        } catch {
            0
        }
    })
    $segB = @($b.Split('.') | ForEach-Object {
        try {
            [int]$_
        } catch {
            0
        }
    })
    # 要素数が異なる場合は、短い方を 0 で埋める
    $max = [Math]::Max($segA.Count, $segB.Count)
    $segA = $segA + (0) * ($max - $segA.Count)
    $segB = $segB + (0) * ($max - $segB.Count)

    # 上から順番に比較
    for ($i = 0; $i -lt $max; $i++) {
        if ($segA[$i] -gt $segB[$i]) { return 1 }
        if ($segA[$i] -lt $segB[$i]) { return -1 }
    }
    return 0

}

# ==== 2. 最新バージョンの Markdown 検出 ====
$re = '_ve?r?([\d\.]+)\.md$'
$latest = @{}
Get-ChildItem $ManDir -Recurse -Filter '*_v*.md' | Where-Object {
    $_.FullName -notmatch '\\old\\' -and
    $_.Directory.Name -notmatch '_v\d' -and
    $_.FullName -notmatch '\\Err\\'　-and
    $_.FullName -notmatch '\\Editing\\'

} | ForEach-Object {
    if ($_ -match $re) {
        $ver = $Matches[1]
        $key = $_.Directory.FullName
#        if (-not $latest.ContainsKey($key) -or (Compare-Version $ver $latest[$key].Ver) -gt 0) {
#            $latest[$key] = [pscustomobject]@{ File = $_; Ver = $ver }
#        }

        # ==== 既存バージョンと比較 ====
        $oldVer = if ($storedVersions.ContainsKey($key)) {
            $storedVersions[$key]
        } else {
            # oldVer が無い場合はとりあえず "0" として扱う
            "0"
        }
        if ((Compare-Version $ver $oldVer) -gt 0) {
            # より新しい場合だけ更新
            $storedVersions[$key] = $ver  # テキスト出力用連想配列も先に更新
            $latest[$key] = [pscustomobject]@{
                File = $_
                Ver  = $ver
            }
        }
    }
}

# ==== 3. 実行ヘルパ ====
#function Run-Bin {
#    param(
#        [Parameter(Mandatory)][string]$Exe,
#        [Parameter(Mandatory)][string[]]$ArgList
#    )
#    # 実行コマンドと行番号を表示
#    Write-Host "[$($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)] Run $Exe with arguments: $ArgList"
#
#    # プロセス実行
#    $proc = Start-Process -FilePath $Exe -ArgumentList $ArgList -NoNewWindow -Wait -PassThru
#
#    # 終了コードをチェックし、エラーがあれば位置情報と一緒に表示
#    if ($proc.ExitCode -ne 0) {
#        throw "[$($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)] $Exe failed with exit code $($proc.ExitCode)."
#    }
#
#}

function Run-Bin {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [Parameter(Mandatory)][string[]]$ArgList,
        [Parameter(Mandatory)][string]$SourceFilePath
    )

    $LogFile = [System.IO.Path]::ChangeExtension($SourceFilePath, ".log")
    $ErrFile = [System.IO.Path]::ChangeExtension($SourceFilePath, ".err")
    if (Test-Path $LogFile) {
        Remove-Item $LogFile
    }
    if (Test-Path $ErrFile) {
        Remove-Item $ErrFile
    }

    # 実行コマンドと行番号を表示
    Write-Host "[$($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)] Run $Exe with arguments: $ArgList"

    # プロセス実行
    $proc = Start-Process -FilePath $Exe -ArgumentList $ArgList -NoNewWindow -Wait -PassThru -RedirectStandardOutput $LogFile -RedirectStandardError $ErrFile
#    & $Exe $ArgList *>> $LogFile
#    $ExitCode = $LASTEXITCODE

    # 終了コードをチェック
    if ($proc.ExitCode -ne 0) {
        # エラー内容を出力
        Write-Warning "[$($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)] $Exe failed with exit code $($proc.ExitCode)."

        # 先頭または末尾にあるシングルクォート/ダブルクォートを取り除くための正規表現パターン
        $pattern = '^["'']+|["'']+$'
        # パターンを使って先頭・末尾クォートを削除
        $unquotedPath = $SourceFilePath -replace $pattern, ''
        $parentDir    = Split-Path $unquotedPath -Parent
        $relativePath = $parentDir.Substring($ManDir.Length).TrimStart("[\/]")  # manuals より下を切り出し
        $topDir = $relativePath.Split('\')[0]                                # 最初の要素(ルート直下のフォルダ名)


        # $ManDir 以下の相対パスを取得し、Err フォルダに同じ階層構造で配置する
        $destination  = Join-Path $ErrDir (Split-Path $relativePath)
        $parentDir    = Split-Path $unquotedPath -Parent

        # フォルダ構成を事前に作成してから移動
        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Set-Location $ManDir
        Copy-Item -Path $parentDir -Destination $destination -Force -Recurse
#        Remove-Item -Path $parentDir -Recurse -Force -ErrorAction SilentlyContinue

        Write-Warning "エラーが発生したファイルを以下に移動しました: $destination"

        # throw せずに処理を続行する場合は return や continue で抜ける
        Write-Warning "スクリプトは継続されます。"
        return $false

    }
    return $true
}



# ==== 4. 変換処理 ====
foreach ($info in $latest.Values) {
    $md        = $info.File.FullName
    $manualDir = $info.File.Directory.FullName

    $relStem = $md.Substring($ManDir.Length + 1) -replace '_v.*\.md$',''
    $htmlOut = Join-Path $OutHtml "$relStem.html"
    $pdfOut  = Join-Path $OutPdf  "$relStem.pdf"

#    タイムスタンプより最新かを判断、NAS上だど時間情報がでたらめなので消去
#    if ( (Test-Path $htmlOut) -and (Test-Path $pdfOut) ) {
#        $srcTime  = (Get-Item $md).LastWriteTimeUtc
#        $htmlTime = (Get-Item $htmlOut).LastWriteTimeUtc
#        $pdfTime  = (Get-Item $pdfOut).LastWriteTimeUtc
#        if (($htmlTime -ge $srcTime) -and ($pdfTime -ge $srcTime)) {
#            Write-Host "Skip (up-to-date): $relStem"
#            continue
#        }
#    }

    # 出力先フォルダの作成
    New-Item -ItemType Directory -Path (Split-Path $htmlOut) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path $pdfOut ) -Force | Out-Null

    # (A) 画像自動回転（EXIFに従い、上書き保存 + バックアップ）
    $imgDir = Join-Path $manualDir 'img'
    $backupDir = Join-Path $imgDir '_backup_img'
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    Get-ChildItem -Path $imgDir -Include *.jpg, *.jpeg | ForEach-Object {
        $imgPath = $_.FullName
        $relPath = $imgPath.Substring($imgDir.Length).TrimStart('\')
        $bakPath = Join-Path $backupDir $relPath
        New-Item -ItemType Directory -Path (Split-Path $bakPath) -Force | Out-Null
        Copy-Item -Path $imgPath -Destination $bakPath -Force
        try {
            Run-Bin -Exe 'magick' -ArgList @('mogrify', '-auto-orient', "`"$imgPath`"")
        } catch {
            Write-Warning "画像の回転に失敗しました: $imgPath"
        }
    }

    # HTML 出力
    $argsHtml = @(
        "`"$md`"",
        "-o", "`"$htmlOut`"",
        "-f markdown-implicit_figures -t html",
        "--lua-filter=`"$HTML_Filter`"",
        "--template=`"$HTML_Temlate`"",
        "--embed-resources",
        "--standalone",
        "--css=`"$Css`"",
        "--include-after-body=`"$Js`"",
        "--resource-path=`"$manualDir`"",
        "--resource-path=`"$Share`""
    )
    # markdown-implicit_figures-yaml_metadata_block
    $result = Run-Bin -Exe $Pandoc -ArgList $argsHtml -SourceFilePath $md
    if (-not $result) {
        Remove-Item -Path (Split-Path $htmlOut) -Recurse -Force -ErrorAction SilentlyContinue
        $storedVersions.Remove((Split-Path $md))
        # スキップして次のアイテムへ移る
        continue
    }

    # PDF 出力
    Push-Location $manualDir

    # (1) .tex を生成
    $texOut = Join-Path $OutPdf "$relStem.tex"
    $argsTex = @(
        "`"$md`"",
        "-f", "markdown-implicit_figures",
        "-t", "latex",
        "--lua-filter=`"$Filter`"",  # Lua フィルタがあれば適宜指定
        "--template=`"$TeX_Temlate`"",
        "-H", "`"$Header`"",         # header.tex 指定用
        "-V", "documentclass=jlreq",
        "-V", "luatexjapresetoptions=ipa",
        "-V", "indent",
        "--resource-path=`"$manualDir`"",
        "--resource-path=`"$Share`"",
        "-o", "`"$texOut`"",
        "--verbose"
    )
    # markdown-implicit_figures-yaml_metadata_block
    $result = Run-Bin -Exe $Pandoc -ArgList $argsTex -SourceFilePath $md
    if (-not $result) {
        Remove-Item -Path (Split-Path $htmlOut) -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Split-Path $pdfOut ) -Recurse -Force -ErrorAction SilentlyContinue
        $storedVersions.Remove((Split-Path $md))
        # スキップして次のアイテムへ移る
        continue
    }

    # (2) lualatex で PDF を生成 (texファイルと同じフォルダに出力したい)
    $texDir = Split-Path $texOut     # 「.tex と同じフォルダ」を取得
    $argsLaTeX = @(
        "-output-directory=`"$($texDir -replace '\\', '/')`"",  # 出力先ディレクトリ指定
        "-interaction=nonstopmode",      # コンパイルエラーでも止まらず処理継続
        "`"$($texOut -replace '\\', '/')`""     # 対象の .tex ファイル
    )
    Write-Output $argsLaTeX
    $result = Run-Bin -Exe "lualatex" -ArgList $argsLaTeX -SourceFilePath $md
    if (-not $result) {
        Remove-Item -Path (Split-Path $htmlOut) -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Split-Path $pdfOut ) -Recurse -Force -ErrorAction SilentlyContinue
        $storedVersions.Remove((Split-Path $md))
        # スキップして次のアイテムへ移る
        continue
    }
    Start-Sleep -Seconds 1   # ← ここで1秒待機
    $result = Run-Bin -Exe "lualatex" -ArgList $argsLaTeX -SourceFilePath $md   # 2回コンパイル（必要に応じて）
    if (-not $result) {
        Remove-Item -Path (Split-Path $htmlOut) -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Split-Path $pdfOut ) -Recurse -Force -ErrorAction SilentlyContinue
        $storedVersions.Remove((Split-Path $md))
        # スキップして次のアイテムへ移る
        continue
    }

#    # .texファイルのフルパスが入っていると仮定
#    $texFileFullPath = $texOut  # ここに .tex ファイルのパスが入っている
#
#    # PDF出力先を組み立てる (拡張子を .pdf に)
#    $pandocPdfOutPath = Join-Path ($texDir) ("$pdfOut.pdf")
#
#    # もし LuaLaTeX の lua-filter を使う必要があれば、--lua-filter=... の指定を入れる
#    # 例: '--lua-filter="C:\Users\Palladium\Documents\PycharmProjects\MD\LuaTest\shared\filter.lua"'
#    $pandocArgs = @(
#        '-f', 'latex',               # 入力フォーマット: LaTeX
#        '-t', 'pdf',                 # 出力フォーマット: PDF
#        '--pdf-engine=lualatex',     # PDF生成に LuaLaTeX を使う
#        "-H", "`"$Header`"",         # header.tex 指定用
#        "-V", "documentclass=jlreq",
#        "-V", "luatexjapresetoptions=ipa",
#        "-V", "indent",
#        "--resource-path=`"$manualDir`"",
#        "--resource-path=`"$Share`"",
#        '-o', "`"$pandocPdfOutPath`"",     # 出力先指定
#        "`"$texFileFullPath`""            # 入力ファイル(.tex)
#    )
#
#    Write-Output $pandocArgs
#
#    # 上記で用意した引数をもとに pandoc を実行
#    Run-Bin -Exe "pandoc" -ArgList $pandocArgs



    Pop-Location

}

# ==== 5. バージョン情報の保存 ====
# 今回確定したバージョン($storedVersions)をテキストファイルに上書き
@("# DirectoryFullPath|Version") | Out-File -FilePath $versionFile -Encoding UTF8
$storedVersions.GetEnumerator() | ForEach-Object {
    "$($_.Key)|$($_.Value)"
} | Out-File -FilePath $versionFile -Append -Encoding UTF8

# ==== 6. インデックス生成 ====

function New-IndexHtml {
    param(
        [Parameter(Mandatory)][string]$TargetDir,
        [Parameter(Mandatory)][string]$Suffix,
        [Parameter(Mandatory)][string]$Title
    )
    $dir = Resolve-Path $TargetDir
    if (-not $dir) { Write-Warning "No such dir: $TargetDir"; return }
    $items = Get-ChildItem -Path $dir -Recurse -Filter "*.$Suffix" |
             Sort-Object FullName |
             ForEach-Object {
                 $rel = $_.FullName.Substring($dir.Path.Length + 1) -replace '\\','/'
                 "<li><a href='$rel'>$rel</a></li>"
             }
    $now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $html = @"
<!DOCTYPE html>
<html lang=\"ja\">
<head>
  <meta charset=\"UTF-8\">
  <title>$Title</title>
  <style>
    body{font-family:YuGothic,Arial,Helvetica,sans-serif;margin:2rem;}
    li{margin:4px 0;}
  </style>
</head>
<body>
  <h1>$Title</h1>
  <p>Last updated date: $now</p>
  <ul>
    $($items -join "`n    ")
  </ul>
</body>
</html>
"@
    $indexPath = Join-Path $dir 'index.html'
    $html | Out-File -Encoding UTF8 $indexPath
    Write-Host "index.html generated -> $indexPath"
}


New-IndexHtml -TargetDir $OutHtml -Suffix 'html' -Title 'Manuals(HTML)'
New-IndexHtml -TargetDir $OutPdf -Suffix 'pdf' -Title 'Manuals(PDF)'
