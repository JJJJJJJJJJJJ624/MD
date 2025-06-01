from pathlib import Path
import subprocess
import os
import contextlib
import re
import hashlib
from datetime import datetime

# ==== 設定 ====
ROOT = Path(__file__).resolve().parent
MANUALS = ROOT / "manuals"
OUTPUT = ROOT / "output"
HTML_DIR = OUTPUT / "html"
PDF_DIR = OUTPUT / "pdf"
HASH_DIR = OUTPUT / ".hash"
SHARED = ROOT / "shared"

CSS = SHARED / "style.css"
JS = SHARED / "script.js"
FILTER = SHARED / "filter.lua"
HEADER = SHARED / "header.tex"

HASH_DIR.mkdir(parents=True, exist_ok=True)

# ==== 実行補助 ====
@contextlib.contextmanager
def cd(path):
    prev = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(prev)

def sh(cmd):
    print(f"\u25b6 {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def md5sum(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()

# ==== 最新バージョンだけ抽出 ====
latest = {}
version_re = re.compile(r'_v(\d+(?:\.\d+)*)\.md$')

for md in MANUALS.rglob("*_v*.md"):
    if "oldversions" in md.parts:
        continue
    match = version_re.search(md.name)
    if not match:
        continue
    ver_str = match.group(1)
    ver = tuple(map(int, ver_str.split(".")))
    key = md.parent
    if key not in latest or ver > latest[key][1]:
        latest[key] = (md, ver)

# ==== HTML / PDF 生成 ====
for manual_dir, (md, ver) in latest.items():
    rel = md.relative_to(MANUALS).with_suffix("")
    html_out = HTML_DIR / rel.with_suffix(".html")
    pdf_out  = PDF_DIR  / rel.with_suffix(".pdf")
    hash_file = HASH_DIR / rel.with_suffix(".md5")

    html_out.parent.mkdir(parents=True, exist_ok=True)
    pdf_out.parent.mkdir(parents=True, exist_ok=True)
    hash_file.parent.mkdir(parents=True, exist_ok=True)

    current_hash = md5sum(md)
    previous_hash = hash_file.read_text().strip() if hash_file.exists() else None

    if previous_hash == current_hash:
        print(f"⏩ Skip (no change): {rel}")
        continue

    # HTML生成
    sh(f"pandoc {md} -o {html_out} "
       f"--embed-resources --standalone "
       f"--css {CSS} "
       f"--include-after-body={JS} "
       f"--resource-path={manual_dir}")

    # PDF生成
    with cd(manual_dir):
        sh(f"pandoc {md.name} -o {pdf_out} "
           f"--lua-filter={FILTER} "
           f"--pdf-engine=lualatex "
           f"-H {HEADER}")

    hash_file.write_text(current_hash)
    print(f"✅ Built: {rel}")

function Generate-Index {
    param (
        [string]$TargetDir,
        [string]$Suffix,
        [string]$Title
    )

    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entries = @()

    # ファイルを再帰的に探索し、ソート
    Get-ChildItem -Path $TargetDir -Recurse -Filter "*.$Suffix" | Sort-Object FullName | ForEach-Object {
        $relPath = $_.FullName.Substring($TargetDir.Length).TrimStart('\','/')
        $relPathHtml = $relPath -replace '\\', '/'
        $entries += "    <li><a href=""$relPathHtml"">$relPathHtml</a></li>"
    }

    $htmlContent = @"
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>$Title</title>
</head>
<body>
  <h1>$Title</h1>
  <p>最終更新: $now</p>
  <ul>
$($entries -join "`n")
  </ul>
</body>
</html>
"@

    $indexPath = Join-Path $TargetDir "index.html"
    $htmlContent | Out-File -FilePath $indexPath -Encoding utf8
    Write-Host "index.html generated in $TargetDir"
}
