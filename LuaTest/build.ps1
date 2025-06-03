Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
$re = '_v([\d\.]+)\.md$'
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
    Write-Host "pandoc $ArgList"
    $proc = Start-Process -FilePath $Exe -ArgumentList $ArgList -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        throw "Pandoc failed with exit code $($proc.ExitCode)."
    }
}

# ==== 4. 変換処理 ====
foreach ($info in $latest.Values) {
    $md        = $info.File.FullName
    $manualDir = $info.File.Directory.FullName

    $relStem = $md.Substring($ManDir.Length + 1) -replace '\\.md$',''
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

    # HTML 出力
    $argsHtml = @(
        "`"$md`"",
        "-o", "`"$htmlOut`"",
        "-f markdown -t html",
        "--lua-filter=`"$HTML_Filter`"",
        "--embed-resources",
        "--standalone",
        "--css=`"$Css`"",
        "--include-after-body=`"$Js`"",
        "--resource-path=`"$manualDir`"",
        "--resource-path=`"$Share`""
    )
    Run-Bin -Exe $Pandoc -ArgList $argsHtml

    # PDF 出力
    Push-Location $manualDir
    $argsPdf = @(
        "`"$md`"",
        "-o", "`"$pdfOut`"",
        "-f markdown -t pdf",
        "--lua-filter=`"$Filter`"",
        "--pdf-engine=lualatex",
        "-H", "`"$Header`"",
        "--resource-path=`"$manualDir`"",
        "--resource-path=`"$Share`""
    )
    Run-Bin -Exe $Pandoc -ArgList $argsPdf
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
