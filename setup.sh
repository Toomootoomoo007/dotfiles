#!/usr/bin/env bash
# ~/.dotfiles/setup.sh
# 別PCで git clone 後にこれを実行すると環境が再現される

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== dotfiles セットアップ開始 ==="
echo "dotfiles: $DOTFILES_DIR"
echo "claude:   $CLAUDE_DIR"
echo ""

# Claude ディレクトリの準備
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/plugins"

# シムリンク作成関数（既存ファイルはバックアップ）
link() {
  local src="$1"
  local dst="$2"

  if [ -L "$dst" ]; then
    echo "  skip (already symlinked): $dst"
    return
  fi

  if [ -e "$dst" ]; then
    echo "  backup: $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi

  ln -s "$src" "$dst"
  echo "  linked: $dst → $src"
}

echo "--- Claude Code 設定 ---"
link "$DOTFILES_DIR/claude/settings.json"                    "$CLAUDE_DIR/settings.json"
link "$DOTFILES_DIR/claude/commands/diary.md"                "$CLAUDE_DIR/commands/diary.md"
link "$DOTFILES_DIR/claude/skills/para-file-organizer"       "$CLAUDE_DIR/skills/para-file-organizer"
link "$DOTFILES_DIR/claude/plugins/known_marketplaces.json"  "$CLAUDE_DIR/plugins/known_marketplaces.json"
link "$DOTFILES_DIR/claude/plugins/installed_plugins.json"   "$CLAUDE_DIR/plugins/installed_plugins.json"

echo ""
echo "=== 完了 ==="
echo ""
echo "次のステップ:"
echo "  1. claude を起動してプラグインを再インストール:"
echo "     /plugin install superpowers@claude-plugins-official"
echo "     /plugin install arscontexta@agenticnotetaking  (vault プロジェクト内で)"
echo "     /plugin install obsidian@obsidian-skills       (vault プロジェクト内で)"
echo "  2. /reload-plugins を実行"
