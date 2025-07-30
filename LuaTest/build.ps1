Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding  = [System.Text.Encoding]::UTF8

# ==== 0. パス定義 ====
$Root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManDir   = Join-Path $Root 'manuals'
$OutHtml  = Join-Path $Root 'output/html'
$OutPdf   = Join-Path $Root 'output/pdf'
$Share    = Join-Path $Root 'shared'

$Css      = Join-Path $Share 'style.css'
$Js       = Join-Path $Share 'script.js'
$Filter   = Join-Path $Share 'filter.lua'
$HTML_Filter   = Join-Path $Share 'html_filter.lua'
$Header   = Join-Path $Share 'header.tex'
$Pandoc   = 'pandoc'

# ==== 0. util関数 ====

# ====  ShortPathの取得    ====
function Get-ShortPath($path) {
    $fso = New-Object -ComObject Scripting.FileSystemObject
    return $fso.GetFile($path).ShortPath
}

# ==== 1. バージョン比較関数 ====
function Compare-Version {
    param ([string]$a, [string]$b)
    $segA = $a.Split('.') | ForEach-Object { [int]$_ }
    $segB = $b.Split('.') | ForEach-Object { [int]$_ }
    $max  = [Math]::Max($segA.Count, $segB.Count)
    $segA = $segA + (0) * ($max - $segA.Count)
    $segB = $segB + (0) * ($max - $segB.Count)
    for ($i = 0; $i -lt $max; $i++) {
        if ($segA[$i] -gt $segB[$i]) { return  1 }
        if ($segA[$i] -lt $segB[$i]) { return -1 }
    }
    return 0
}

# ==== 2. 最新バージョンの Markdown 検出 ====
$re = '_ve?r?([\d\.]+)\.md$'
$latest = @{}
Get-ChildItem $ManDir -Recurse -Filter '*_v*.md' | Where-Object {
    $_.FullName -notmatch '\\old\\' -and $_.Directory.Name -notmatch '_v\d'
} | ForEach-Object {
    if ($_ -match $re) {
        $ver = $Matches[1]
        $key = $_.Directory.FullName
        if (-not $latest.ContainsKey($key) -or (Compare-Version $ver $latest[$key].Ver) -gt 0) {
            $latest[$key] = [pscustomobject]@{ File = $_; Ver = $ver }
        }
    }
}

# ==== 3. 実行ヘルパ ====
function Run-Bin {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [Parameter(Mandatory)][string[]]$ArgList
    )
    # 実行コマンドと行番号を表示
    Write-Host "[$($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)] Run $Exe with arguments: $ArgList"

    # プロセス実行
    $proc = Start-Process -FilePath $Exe -ArgumentList $ArgList -NoNewWindow -Wait -PassThru

    # 終了コードをチェックし、エラーがあれば位置情報と一緒に表示
    if ($proc.ExitCode -ne 0) {
        throw "[$($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)] $Exe failed with exit code $($proc.ExitCode)."
    }

}

# ==== 4. 変換処理 ====
foreach ($info in $latest.Values) {
    $md        = $info.File.FullName
    $manualDir = $info.File.Directory.FullName

    $relStem = $md.Substring($ManDir.Length + 1) -replace '_v.*\.md$',''
    $htmlOut = Join-Path $OutHtml "$relStem.html"
    $pdfOut  = Join-Path $OutPdf  "$relStem.pdf"

    if ( (Test-Path $htmlOut) -and (Test-Path $pdfOut) ) {
        $srcTime  = (Get-Item $md).LastWriteTimeUtc
        $htmlTime = (Get-Item $htmlOut).LastWriteTimeUtc
        $pdfTime  = (Get-Item $pdfOut).LastWriteTimeUtc
        if (($htmlTime -ge $srcTime) -and ($pdfTime -ge $srcTime)) {
            Write-Host "Skip (up-to-date): $relStem"
            continue
        }
    }

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
        "--embed-resources",
        "--standalone",
        "--css=`"$Css`"",
        "--include-after-body=`"$Js`"",
        "--resource-path=`"$manualDir`"",
        "--resource-path=`"$Share`""
    )
    # markdown-implicit_figures-yaml_metadata_block
    Run-Bin -Exe $Pandoc -ArgList $argsHtml

    # PDF 出力
    Push-Location $manualDir

    # (1) .tex を生成
    $texOut = Join-Path $OutPdf "$relStem.tex"
    $argsTex = @(
        "`"$md`"",
        "-f", "markdown-implicit_figures",
        "-t", "latex",
        "--lua-filter=`"$Filter`"",  # Lua フィルタがあれば適宜指定
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
    Run-Bin -Exe $Pandoc -ArgList $argsTex

    # (2) lualatex で PDF を生成 (texファイルと同じフォルダに出力したい)
    $pdfOut = (Get-Item $texOut).BaseName
#    $texOut = Get-ShortPath($texOut)
    $texDir = Split-Path $texOut     # 「.tex と同じフォルダ」を取得
#    $texOut = Get-ShortPath($texOut)
    $argsLaTeX = @(
        "-output-directory=$($texDir -replace '\\', '/')",  # 出力先ディレクトリ指定
        "-interaction=nonstopmode",      # コンパイルエラーでも止まらず処理継続
        "-jobname=`"$($pdfOut -replace '\\', '/')`"",
        "`"$($texOut -replace '\\', '/')`""     # 対象の .tex ファイル
    )
    Write-Output $argsLaTeX
    Run-Bin -Exe "lualatex" -ArgList $argsLaTeX
    Start-Sleep -Seconds 1   # ← ここで1秒待機
    Run-Bin -Exe "lualatex" -ArgList $argsLaTeX   # 2回コンパイル（必要に応じて）

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

# ==== 5. インデックス生成 ====
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
