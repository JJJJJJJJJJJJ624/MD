from pathlib import Path
import subprocess
import os
import contextlib
import re
import sys
from datetime import datetime

# ==== 設定 ====
ROOT = Path(__file__).resolve().parent
MANUALS = ROOT / "manuals"
OUTPUT = ROOT / "output"
HTML_DIR = OUTPUT / "html"
PDF_DIR = OUTPUT / "pdf"
SHARED = ROOT / "shared"

CSS = SHARED / "style.css"
JS = SHARED / "script.js"
FILTER = SHARED / "filter.lua"
HEADER = SHARED / "header.tex"

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
    print(f"▶ {cmd}")
    try:
        subprocess.run(cmd, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running: {cmd}\n{e}", file=sys.stderr)

# ==== 最新バージョンだけ抽出 ====
latest = {}
version_re = re.compile(r'_v(\d+(?:\.\d+)?)\.md$')  # v1.2対応

for md in MANUALS.rglob("*_v*.md"):
    # 旧バージョン格納ディレクトリに含まれるものは除外
    if any(part.lower().startswith("old") for part in md.parts):
        continue

    match = version_re.search(md.name)
    if not match:
        continue

    try:
        ver = float(match.group(1))
    except ValueError:
        continue

    key = md.parent  # A001_Manual1/
    if key not in latest or ver > latest[key][1]:
        latest[key] = (md, ver)

# ==== HTML / PDF 生成 ====
for manual_dir, (md, ver) in latest.items():
    rel = md.relative_to(MANUALS).with_suffix("")
    html_out = HTML_DIR / rel.with_suffix(".html")
    pdf_out  = PDF_DIR  / rel.with_suffix(".pdf")
    html_out.parent.mkdir(parents=True, exist_ok=True)
    pdf_out.parent.mkdir(parents=True, exist_ok=True)

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
           f"-H {HEADER} "
           f"--resource-path=.")


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
    print(f"index.html generated in {target_dir}")

# ==== インデックス生成 ====
generate_index(HTML_DIR, "html", "マニュアル一覧（HTML）")
generate_index(PDF_DIR,  "pdf",  "マニュアル一覧（PDF）")