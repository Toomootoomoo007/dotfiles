#!/usr/bin/env bash
# ~/.dotfiles/setup.sh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

IS_WSL=false
IS_MAC=false
if grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
elif [[ "$(uname)" == "Darwin" ]]; then
  IS_MAC=true
fi

echo "=== dotfiles セットアップ開始 ==="
echo "dotfiles: $DOTFILES_DIR"
echo "claude:   $CLAUDE_DIR"
$IS_WSL && echo "環境:     WSL2"
$IS_MAC && echo "環境:     macOS"
echo ""

if $IS_WSL; then
  echo "--- WSL2: 改行コード正規化 ---"
  git -C "$DOTFILES_DIR" config core.autocrlf false
  git -C "$DOTFILES_DIR" config core.eol lf
  if command -v dos2unix &>/dev/null; then
    find "$DOTFILES_DIR/claude" \( -name "*.json" -o -name "*.md" -o -name "*.sh" \) \
      -exec dos2unix -q {} \;
    echo "  改行コード変換完了"
  else
    echo "  ⚠️  dos2unix がありません: sudo apt install dos2unix を推奨"
  fi
  echo ""
fi

mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/plugins"

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

win_copy() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -d "$src" ]; then
    cp -r "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
  echo "  copied: $dst"
}

echo "--- Claude Code 設定 (symlink) ---"
link "$DOTFILES_DIR/claude/settings.json"                   "$CLAUDE_DIR/settings.json"
link "$DOTFILES_DIR/claude/commands/diary.md"               "$CLAUDE_DIR/commands/diary.md"
link "$DOTFILES_DIR/claude/plugins/known_marketplaces.json" "$CLAUDE_DIR/plugins/known_marketplaces.json"

for skill_src in "$DOTFILES_DIR/claude/skills"/*/; do
  skill_name=$(basename "$skill_src")
  link "$skill_src" "$CLAUDE_DIR/skills/$skill_name"
done
echo ""

if $IS_WSL; then
  echo "--- Windows側 .claude に同期 ---"
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
  WIN_CLAUDE="/mnt/c/Users/$WIN_USER/.claude"

  if [ -d "/mnt/c/Users/$WIN_USER" ]; then
    mkdir -p "$WIN_CLAUDE/skills" "$WIN_CLAUDE/commands" "$WIN_CLAUDE/plugins"

    win_copy "$DOTFILES_DIR/claude/settings.json"                   "$WIN_CLAUDE/settings.json"
    win_copy "$DOTFILES_DIR/claude/commands/diary.md"               "$WIN_CLAUDE/commands/diary.md"
    win_copy "$DOTFILES_DIR/claude/plugins/known_marketplaces.json" "$WIN_CLAUDE/plugins/known_marketplaces.json"

    for skill_src in "$DOTFILES_DIR/claude/skills"/*/; do
      skill_name=$(basename "$skill_src")
      win_copy "$skill_src" "$WIN_CLAUDE/skills/$skill_name"
    done

    echo "  同期先: $WIN_CLAUDE"
  else
    echo "  ⚠️  Windowsユーザーディレクトリが見つかりません"
  fi
  echo ""
fi

echo "=== 完了 ==="
echo ""
echo "次のステップ:"
echo "  pluginは各環境で手動インストール:"
echo "     /plugin install superpowers@claude-plugins-official"
echo "     /plugin install arscontexta@agenticnotetaking  (vault プロジェクト内で)"
echo "     /plugin install obsidian@obsidian-skills       (vault プロジェクト内で)"
