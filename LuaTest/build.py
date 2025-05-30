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

def generate_index(target_dir: Path, suffix: str, title: str):
    entries = []
    for file in sorted(target_dir.rglob(f"*.{suffix}")):
        rel_path = file.relative_to(target_dir)
        entries.append(f'<li><a href="{rel_path.as_posix()}">{rel_path}</a></li>')

    index_html = f"""<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>{title}</title>
</head>
<body>
  <h1>{title}</h1>
  <p>最終更新: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
  <ul>
    {''.join(entries)}
  </ul>
</body>
</html>
"""
    (target_dir / "index.html").write_text(index_html, encoding="utf-8")
    print(f"✅ index.html generated in {target_dir}")

# ==== インデックス生成 ====
generate_index(HTML_DIR, "html", "マニュアル一覧（HTML）")
generate_index(PDF_DIR,  "pdf",  "マニュアル一覧（PDF）")
