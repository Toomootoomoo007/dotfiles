# dotfiles

青木智博の環境設定管理

## 構成

```
~/.dotfiles/
├── setup.sh              ← 新PCでこれを実行
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

## 新しいPCのセットアップ手順

```bash
# 1. このリポジトリをクローン
git clone git@github.com:<username>/dotfiles.git ~/.dotfiles

# 2. セットアップスクリプトを実行（シムリンクを張る）
cd ~/.dotfiles
chmod +x setup.sh
./setup.sh

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
