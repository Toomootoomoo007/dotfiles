# Design: wp-backup（対話型 WordPress フルバックアップ CLI）

日付: 2026-08-04  
承認: Tomo（会話上で ok）

## Goal

Mac / WSL 共通の対話型 CLI で、登録済み WP サイトのリモート DB（+ uploads）をローカルにバックアップする。

## Layout

```
~/.dotfiles/bin/wp-backup
~/.local/bin/wp-backup → symlink
~/.dotfiles/config/wp-backup/site.example.conf
~/.config/wp-backup/sites/<id>.conf   # Git外・マシン固有
~/Backups/wp/<site>/<timestamp>/
```

## Behavior

- デフォルトは対話（サイト / db|full / 保存先 / 確認）
- `--site` / `--mode` / `--dest` / `--yes` で非対話も可
- ローカル Docker / WP は変更しない（`sync-from-production` とは分離）
- 成果物: `database.sql`, （full時）`uploads/`, `manifest.txt`

## First site

- nigawa: SSH `sakura`, uploads `/home/tomichael/www/dev-nigawa/wp-content/uploads`

## Out of scope (v1)

- リストア、暗号化、スケジュール、Shortcuts 本体、圧縮アーカイブ
