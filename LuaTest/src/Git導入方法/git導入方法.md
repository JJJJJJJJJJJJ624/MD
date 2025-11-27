---
title: "Git を自分のPCに導入する方法"
author: "テスト"
approver: "動作テスト"
date: 2025-11-27
---

# Git を自分のPCに導入する方法

---

## 1. Git（Git Bash）の導入

1. ブラウザで「Git for Windows」と検索し、公式サイトからインストーラを入手する。

2. ダウンロードした `.exe` を実行する。

3. 途中の選択は、基本的にそのまま「Next」を選べばよい。以下にポイントのみ示す。

   * **「Choosing the default editor used by Git」**
     → とりあえず `Use Visual Studio Code as Git’s default editor` か `Use Vim` など、好みに応じて。
     VS Code 使う予定なら VS Code を選んでおくと楽。

   * **「Adjusting your PATH environment」**
     → `Git from the command line and also from 3rd-party software` を選んでおくと無難。

   * **「Choosing HTTPS transport backend」**
     → デフォルトのままで問題なし。

   * **「Configuring the line ending conversions」**
     → Windows なら `Checkout Windows-style, commit Unix-style line endings` のままでよいことが多い。

   * 他はデフォルトのままで OK。

4. インストールが終わったら、スタートメニューから「Git Bash」を起動できることを確認する。

---

## 2. GitHub アカウント準備

1. まだ GitHub アカウントがなければ、
   ブラウザで `https://github.com` を開き、Sign up からアカウントを作る。
2. 後で SSH 設定で使うので、GitHub に登録したメールアドレスを覚えておく。

---

## 3. Git Bash の初期設定（ユーザー名・メール）

Git Bash を開いて、次の設定を一度だけ行う。

```bash
# 自分の名前（適当でよいが、GitHubの表示に使われる）
git config --global user.name "Your Name"

# GitHub に登録したメールアドレス
git config --global user.email "your_email@example.com"

# 日本語ファイル名が文字化けしないように（お好み）
git config --global core.quotepath false
```

設定内容を確認したければ:

```bash
git config --global --list
```

---

## 4. SSH 鍵を作って GitHub とつなぐ

HTTPS でも clone はできるが、更新（push）もするつもりなら SSH をおすすめする。

### 4-1. 鍵の作成

Git Bash で以下を実行（メールは自分のものに変える）:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

* 「保存するファイル名を聞かれる」
  → 何も打たずに Enter で OK（既定の `~/.ssh/id_ed25519` に保存）。
* 「パスフレーズを聞かれる」
  → セキュリティ的には入れたほうがよいが、最初は空 Enter でも動く。

### 4-2. ssh-agent に鍵を登録

```bash
# ssh-agent を起動
eval "$(ssh-agent -s)"

# さきほど作った秘密鍵を登録
ssh-add ~/.ssh/id_ed25519
```

### 4-3. 公開鍵を GitHub に登録

1. 公開鍵の中身を表示:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. 出てきた長い1行の文字列を、全部コピーする。

3. ブラウザで GitHub を開き、右上アイコン → `Settings`。

4. 左メニューの `SSH and GPG keys` → `New SSH key`。

5. Title は適当に（例: `My Laptop`）、Key のところにさっきコピーした内容を貼り付け → `Add SSH key`。

### 4-4. 接続テスト

Git Bash で:

```bash
ssh -T git@github.com
```

* 初回は接続してよいか聞かれるので `yes` と入力。
* 成功すると
  `Hi ユーザー名! You've successfully authenticated, ...` みたいなメッセージが出る。

ここまでできれば、GitHub と SSH でつながっている。

---

## 5. GitHub リポジトリをローカルに入れる

### 5-1. 保存先フォルダを決める

例として、`C:\work\github` のような場所を作る。

1. エクスプローラで `C:` 直下に `work` フォルダを作る。
2. Git Bash でそのフォルダに移動:

   ```bash
   cd /c/work
   mkdir github
   cd github
   ```

### 5-2. GitHub 上で clone 用 URL を確認

1. ブラウザで、ローカルに落としたい GitHub リポジトリのページを開く。
2. 緑色の `Code` ボタン → `SSH` タブを選ぶ。
   例: `git@github.com:username/reponame.git`

### 5-3. clone 実行

Git Bash（さっきの `/c/work/github` にいる状態）で:

```bash
git clone git@github.com:username/reponame.git
```

* 実行が終わると、`/c/work/github/reponame` というフォルダができ、その中に GitHub の中身が全部落ちてくる。

### 5-4. 中身を確認

```bash
cd reponame
ls
```

ここに、GitHub 上のファイルが並んでいれば成功。

---

## 6. 以後の更新（pull / push）の基本

### 6-1. GitHub 側の変更をローカルに取り込む（pull）

```bash
cd /c/work/github/reponame
git pull
```

### 6-2. ローカルで編集した内容を GitHub に反映（push）

1. 変更されたファイルを確認:

   ```bash
   git status
   ```

2. 変更をステージに載せる（全部まとめてなら）:

   ```bash
   git add .
   ```

3. 変更にコメントを付けて記録（コミット）:

   ```bash
   git commit -m "作業内容のメモを書く"
   ```

4. GitHub に送る:

   ```bash
   git push
   ```

---

ここまでできれば、

* Git Bash を起動
* 作業フォルダに `cd`
* `git pull` で最新を取得
* 編集
* `git add` → `git commit` → `git push`

という流れで、GitHub とローカルのやり取りができる。