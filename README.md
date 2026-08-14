# dotfiles

青木智博の環境設定管理

## 構成

```
~/.dotfiles/
├── setup.sh              ← 新PCでこれを実行
├── bin/
│   └── wp-backup         ← WPリモートバックアップ（対話CLI）
├── zsh/
│   └── functions.zsh     ← 自作コマンド（関数・エイリアス）
├── config/wp-backup/
│   └── site.example.conf ← サイト設定の見本
├── docs/
└── claude/
    ├── settings.json     ← Claude Code グローバル設定
    ├── skills/
    │   └── para-file-organizer/   ← グローバルスキル
    ├── commands/
    │   └── diary.md      ← カスタムコマンド
    └── plugins/
        ├── known_marketplaces.json   ← マーケットプレイス一覧
        └── installed_plugins.json    ← インストール済みプラグイン一覧
```

サイト実設定は Git 外: `~/.config/wp-backup/sites/*.conf`  
バックアップ保存先デフォルト: `~/Backups/wp/`

## 自作コマンド

| コマンド | 内容 | 実体 |
|---|---|---|
| `wp-backup` | リモートWPのDB/uploadsバックアップ（対話CLI） | `bin/wp-backup` |
| `gpush` | `git add . && commit -m "update" && push` | `zsh/functions.zsh` |
| `claude-sync` | `~/.claude/skills` を dotfiles に同期して push | 〃 |
| `gas-use <acct>` | clasp のログイン切替（personal/facil/church） | 〃 |
| `gas-whoami` | 現在のGASアカウント確認 | 〃 |
| `g-form-master <acct> "<名前>"` | フォームマスターのスプレッドシート新規作成 | 〃 |
| `g-form-push [acct]` | 既存マスターへコード配布 | 〃 |

`zsh/functions.zsh` は `~/.zshrc` から `source` される（`setup.sh` が1行を追記）。  
**`.zshrc` 本体は symlink しない** — PHP/pyenv/nvm 等のパスがマシン固有のため。  
新しい自作コマンドは `.zshrc` に直書きせず `zsh/functions.zsh` に追加すること。

## 新しいPCのセットアップ手順

```bash
# 1. このリポジトリをクローン
git clone git@github.com:<username>/dotfiles.git ~/.dotfiles

# 2. セットアップスクリプトを実行（シムリンク＋.zshrcへのsource追記）
cd ~/.dotfiles
chmod +x setup.sh
./setup.sh

# 2-b. 自作コマンドを有効化して確認
source ~/.zshrc
type gas-use   # → shell function from ~/.dotfiles/zsh/functions.zsh と出れば成功

# 3. Obsidian Vault をクローン（vault固有のスキル・フック・設定が入っている）
git clone git@github.com:<username>/obsidian-vault.git ~/Documents/Obsidian\ Vault

# 4. Claude Code を起動してプラグインを再インストール
# user スコープ（どこでも使う）
/plugin install superpowers@claude-plugins-official

# vault ディレクトリ内で（project スコープ）
/plugin install arscontexta@agenticnotetaking
/plugin install obsidian@obsidian-skills

# 5. /reload-plugins を実行
```

## 注意事項

- `plugins/installed_plugins.json` の project スコープのパスはマシン固有 → 新PCでは再インストールが必要
- `projects/` (Claude のメモリ) は同期していない → 必要なら手動コピー
- vault 固有の設定は Obsidian Vault リポジトリ側 (`.claude/`) で管理
