# MD→PDF/HTML

## 概要

Markdown（.md）で作成したマニュアルを HTML と PDF に変換。  
画像サイズとかいい感じに揃う。  
Pandoc と Lua フィルタを活用して、レイアウトの自動整形とスタイル統一を行う。

---

## 必要環境

- Pandoc
-  LuaLaTeX（TeX Live）
-  ImageMagick（画像の自動回転補正のため）
-  PowerShell

---

## 主な機能

- **HTML 出力**
  -  独自テンプレート（`template.html`）+ CSS（`style.css`）
  -  画像クリックでモーダル拡大（`script.js`）
- **PDF 出力**
  - LuaLaTeX によりいいかんじに出力される
  - ページ番号・最終ページ番号の自動設定がなされる
- **画像自動並び（Lua フィルタ）**
  - 複数画像を横並びレイアウトに自動変換
  - HTML / PDF 双方で整列
- **リソースの埋め込み**
  - CSS / JS / 画像を HTML 内にインライン化可能

---

## ビルド方法

### HTMLビルド例

cd XXXX\XXXXX
でフォルダに移ってから、

```powershell
pandoc manuals\Sample\sampleA_v1.md `
  -o output\html\sampleA_v1.html `
  -f markdown-implicit_figures -t html `
  --template shared\template.html `
  --embed-resources --standalone `
  --css shared\style.css `
  --include-after-body shared\script.html `
  --lua-filter shared\html_filter.lua `
  --resource-path "manuals\Sample;shared"
```

### PDFビルド例

```powershell
pandoc manuals\Sample\sampleA_v1.md `
  -o output\pdf\sampleA_v1.pdf `
  --template=shared\template.tex `
  --lua-filter shared\pdf_filter.lua `
  --pdf-engine=lualatex
```

※ LaTeX の最終ページ番号を正しく表示するためには 2回コンパイル推奨。

---

## ファイル構成

```
manuals/           ← 原稿Markdown
shared/
  ├─ template.html ← HTMLテンプレート
  ├─ template.tex  ← PDFテンプレート
  ├─ style.css     ← HTML用CSS
  ├─ script.html   ← HTML末尾に挿入するJS読み込みタグ
  ├─ script.js(※) ← モーダル動作用JavaScript、script.htmlへ移行予定
  ├─ html_filter.lua
  └─ pdf_filter.lua
output/
  ├─ html/         ← HTML出力先
  └─ pdf/          ← PDF出力先
build.ps1          ← ビルドスクリプト
```

