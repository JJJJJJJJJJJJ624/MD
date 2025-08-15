# Markdown→PDF/html
なんか関数使って横並び処理させてると、メンテナンス性悪そうだし、初稿の質の悪さに気づきにくそう。なんとか作り手に優しいものを作りたい。  
↓  
MD方式で書いてたら勝手にいいかんじに画像並ぶやつをちゃんと目指す。

## なんかいい感じに出来そうだった方法
**PDFはluaで頑張って、htmlはjsで頑張る**   
テンプレート機能を使いこなすのがともかく難しいのかもしれない。なるべくシンプルに、luaでカバーできるかテストした  
↓  
画像並べるやつはなんかうまいこといった。
タイトル・作者・日付の配置も無難なんじゃないだろうか

## ファイル構造
project_root/  
├── manuals/ # 各マニュアル専用フォルダ  
│ ├── A001_Manual1/  
│ │ ├── A001_Manual1_v1.2.md # ★ 最新版 Markdown  
│ │ ├── img/ # 最新版で使う画像  
│ │ │ └── fig1.png  
│ │ └── oldversions/ # 旧バージョン収納  
│ │ │ ├── A001_Manual1_v1.0  
│ │ │ │ ├── A001_Manual1_v1.0.md  
│ │ │ │ └── img/ # 旧バージョン収納  
│ │ │ └── A001_Manual1_v1.1/ ...  
│ └── A002_Manual2/ ...  
│  
├── shared/ # 共有テンプレート・フィルタ  
│ ├── filter.lua  
│ └── なんかいろいろhtmlいいかんじに出力させるやつ  
│  
├── output/ # ★ バッチ生成物を集中管理  
│ ├── html/ # latest 版のみ  
│ │ ├── A001_Manual1.html  
│ │ ├── A002_Manual2.html  
│ │ └── index.html # 自動生成の目次  
│ └── pdf/  
│ ├── A001_Manual1.pdf  
│ └── A002_Manual2.pdf  
│  
├── convert.ps1 # PowerShell 自動変換スクリプト  
└── README.md  

## とりあえずのpandoc変換

html変換  
プロジェクトルートで実行するやつを以下に書いておく
```txt
pandoc manuals/sample.md `
  -o output/html/sample.html `
  --embed-resources `
  --standalone `
  --css shared/style.css `
  --include-after-body=shared/script.js `
  --resource-path=manuals
```

pdf変換  
なんかcd使って移動しないとうまく動作しなかった。
```txt
cd manuals  (マニュアルが置いてあるフォルダに移る)
pandoc sample.md `  
  -o ../output/pdf/sample.pdf `  
  --pdf-engine=lualatex `  
  -H ../shared/header.tex `  
  --lua-filter=../shared/filter.lua
```

##  build.py ― 変換スクリプト
バージョン名同じままでも、内容が更新されていたら生成しなおす処理させるpyを作った。  
(前はps1ファイルだったけど、単体テストもしやすいpyを採用した。)  
夜間バッチ働かせたいなら、ps1ファイルか、batを作成する。  
batなら、  
```bat
@echo off
cd /d C:\Users\YourName\project
python build.py
```
ps1なら、
```ps1
# build.ps1
$projectPath = "C:\Users\YourName\project"
cd $projectPath

# 仮想環境があれば有効化
if (Test-Path ".\venv\Scripts\Activate.ps1") {
    . .\venv\Scripts\Activate.ps1
}

# スクリプト実行 & ログ出力
try {
    python build.py | Tee-Object -FilePath build.log
} catch {
    Write-Error "Build failed: $_"
}
```
