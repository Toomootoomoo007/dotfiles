 青少年委員会　議事録
開催日時：2026年5月24日(日) 12:10
開催場所：フランシス館
参加者：てるは、さぶろー、とも、よーこ、ジェニー、みお、大西父、ゆうま
【共有】
ブロック合同子供ミサの調整状況
5月24日(日) 8:30集合（仁川教会8:15集合）
最終参加
宝塚：24名
伊丹：11名
仁川：25名
タウに載せる
次回は2月 in 宝塚教会
阪神地区青少年委員会
5月31日(日) 14時から@フランシス館
侍者会 5/17(日)
内容
「侍者とは」や「名称」等
次回は？
日曜学校登録用紙
返答あり：中嶋さん、さくら、ゆうし、
返答待ち：ゆうと、ライナー、青木家
青年とこどもの練成会（セコレン）
大阪高松教区が8/9 ~ 11日に実施。
仁川教会からはかなちゃんがリーダーで参加
【検討事項】
初聖体
6/7 ニコラス
当日、日曜学校はないが、パーティーを行う。
評議会のため、一部大人がいないが、いるスタッフで実施。
日曜学校の予定
5/31: ゼノ神父様の話
6/21: 未定
7/19: 未定
8/23: 未定
アントニオのお祝い
共同祈願を中高生会で作成済み
ベトナムと一緒
BBQ at 仁川
予算
　参加者　500円
　補助金　立替で行う
人数の把握が必要：
中高生会
第１回：4月26日(日)
第２回：6月14日(日)
第３回：6月28日(日)
日曜学校のキャンプ
８月２２or２３日　デイキャンプ
アントニオ練成会
日程検討中
6月14日に確認して、決めたい
シルバーウィーク？
平和旬間
特に青少年委員会主体の活動はなし。社活から声がけが掛かったら検討。→社会活動委員による
7/20(月・祝) 10時〜からイベントとミサ。 阪神地区合同の平和祈願ミサの予定。
献金奉納の依頼あり。
被昇天 8/15 の献金奉納
奉納する
【次回】
 6月28日(日)
#!/usr/bin/env bash
# ~/.dotfiles/setup.sh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# ── OS判定 ────────────────────────────────────────────────────────────────
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

# ── WSL2: 改行コード対策 ──────────────────────────────────────────────────
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

# ── ~/.claude ディレクトリの準備 ──────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/plugins"

# ── シムリンク作成関数 ────────────────────────────────────────────────────
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

# ── Windowsへのコピー関数 ─────────────────────────────────────────────────
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
link "$DOTFILES_DIR/claude/settings.json"                    "$CLAUDE_DIR/settings.json"
link "$DOTFILES_DIR/claude/commands/diary.md"                "$CLAUDE_DIR/commands/diary.md"
link "$DOTFILES_DIR/claude/skills/para-file-organizer"       "$CLAUDE_DIR/skills/para-file-organizer"
link "$DOTFILES_DIR/claude/plugins/known_marketplaces.json"  "$CLAUDE_DIR/plugins/known_marketplaces.json"
link "$DOTFILES_DIR/claude/plugins/installed_plugins.json"   "$CLAUDE_DIR/plugins/installed_plugins.json"
echo ""

# ── WSL2: Windows側にコピー ───────────────────────────────────────────────
if $IS_WSL; then
  echo "--- Windows側 .claude に同期 ---"
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
  WIN_CLAUDE="/mnt/c/Users/$WIN_USER/.claude"

  if [ -d "/mnt/c/Users/$WIN_USER" ]; then
    mkdir -p "$WIN_CLAUDE/skills" "$WIN_CLAUDE/commands" "$WIN_CLAUDE/plugins"

    win_copy "$DOTFILES_DIR/claude/settings.json"                   "$WIN_CLAUDE/settings.json"
    win_copy "$DOTFILES_DIR/claude/commands/diary.md"               "$WIN_CLAUDE/commands/diary.md"
    win_copy "$DOTFILES_DIR/claude/skills/para-file-organizer"      "$WIN_CLAUDE/skills/para-file-organizer"
    win_copy "$DOTFILES_DIR/claude/plugins/known_marketplaces.json" "$WIN_CLAUDE/plugins/known_marketplaces.json"
    win_copy "$DOTFILES_DIR/claude/plugins/installed_plugins.json"  "$WIN_CLAUDE/plugins/installed_plugins.json"
    echo "  同期先: $WIN_CLAUDE"
  else
    echo "  ⚠️  Windowsユーザーディレクトリが見つかりません"
  fi
  echo ""
fi

echo "=== 完了 ==="
echo ""
echo "次のステップ:"
echo "  1. claude を起動してプラグインを再インストール:"
echo "     /plugin install superpowers@claude-plugins-official"
echo "     /plugin install arscontexta@agenticnotetaking  (vault プロジェクト内で)"
echo "     /plugin install obsidian@obsidian-skills       (vault プロジェクト内で)"
echo "  2. /reload-plugins を実行"#!/usr/bin/env bash
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
