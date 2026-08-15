# ==================================================
# 自作コマンド（dotfiles管理）
# --------------------------------------------------
# ~/.zshrc から source される。
# 読み込み側: [ -f ~/.dotfiles/zsh/functions.zsh ] && source ~/.dotfiles/zsh/functions.zsh
#
# ここには「どのMacでも使いたい自作コマンド」だけを置く。
# PHP/pyenv/nvm 等のマシン固有の環境設定は ~/.zshrc に残すこと。
#
# 一覧: Obsidian Vault の 00_INBOX/Mac自作コマンド一覧_2026-08-15.md
# ==================================================

# --------------------------------------------------
# Git
# --------------------------------------------------

# 全変更をコミットして push する
#   gpush "メッセージ"   … メッセージを指定
#   gpush                … メッセージ省略時は "update"
# コミット前に対象ファイルを表示して [y/N] で確認する。
gpush() {
  local msg="${1:-update}"

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { echo "❌ gitリポジトリではありません"; return 1; }

  local branch="$(git branch --show-current)"
  [[ -z "$branch" ]] && { echo "❌ detached HEAD 状態です。ブランチに切り替えてください"; return 1; }

  if [[ -z "$(git status --porcelain)" ]]; then
    echo "変更はありません"
    return 0
  fi

  echo "📋 コミット対象:"
  git status --short
  echo ""
  echo "ブランチ:   $branch"
  echo "メッセージ: $msg"
  echo ""
  printf "実行しますか? [y/N] "
  local reply
  read -r reply
  [[ "$reply" == [yY] ]] || { echo "中止しました"; return 1; }

  git add -A           || { echo "❌ git add に失敗しました";    return 1; }
  git commit -m "$msg" || { echo "❌ git commit に失敗しました"; return 1; }

  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    git push || { echo "❌ git push に失敗しました"; return 1; }
  else
    echo "upstream 未設定 → -u を付けて push します"
    git push -u origin "$branch" || { echo "❌ git push に失敗しました"; return 1; }
  fi

  echo "✅ 完了: $branch ← \"$msg\""
}

# 日記は Claude Code の /diary コマンド（claude/commands/diary.md）を使う。
# 旧 `alias diary=".../000-system/diary_ai.py"` は参照先が消滅していたため
# 2026-08-15 に削除した。

# --------------------------------------------------
# Claude Code
# --------------------------------------------------

# Claude Code スキルを dotfiles に同期して GitHub に送る
claude-sync() {
  cp -r ~/.claude/skills/* ~/.dotfiles/claude/skills/
  cd ~/.dotfiles
  git add .
  git commit -m "sync: claude skills"
  git push
  echo "✅ 同期完了"
}

# ==================================================
# tomo-gas-project: マルチアカウントclasp運用
# ==================================================

# GAS用ヘルパー：アカウント切り替え
gas-use() {
  local account="${1}"
  if [[ -z "$account" ]]; then
    echo "使用方法: gas-use <personal|facil|church>"
    return 1
  fi
  local src="$HOME/.clasprc-${account}.json"
  if [[ ! -f "$src" ]]; then
    echo "❌ $src が存在しません"
    echo "先に 'clasp login' → 'cp ~/.clasprc.json $src' を実行してください"
    return 1
  fi
  cp "$src" "$HOME/.clasprc.json"
  echo "✅ GASアカウント切替: $account"
}

# GAS用ヘルパー：現在ログイン中のアカウント確認
gas-whoami() {
  # .clasprc.json とサイズが一致するファイルを探す
  local current_size=$(stat -f%z "$HOME/.clasprc.json" 2>/dev/null)
  local current_hash=$(md5 -q "$HOME/.clasprc.json" 2>/dev/null)
  for acct in personal facil church; do
    local f="$HOME/.clasprc-${acct}.json"
    [[ -f "$f" ]] || continue
    if [[ "$(md5 -q "$f")" == "$current_hash" ]]; then
      echo "🔑 現在のGASアカウント: $acct"
      return 0
    fi
  done
  echo "❓ 不明なアカウント（.clasprc.json と一致するプロファイルなし）"
}

# =================================================
# Googleフォーム自動生成ツール（98_tomo-gas-project）
# -------------------------------------------------
#   g-form-master <アカウント> "<名前>"  … フォームマスターを作る（アカウントごとに1回）
#   g-form-push   [アカウント]           … コードを配布する
# アカウント切替は gas-use / 確認は gas-whoami
# =================================================

# フォームマスターを新規作成する（アカウントごとに1回だけ実行）
# 使用例:
#   g-form-master personal "個人 フォームマスター"
#   g-form-master church   "仁川教会 フォームマスター"
#
# イベントごとの作業は、作られたスプレッドシートのメニュー
# 「📋 フォーム作成ツール」→「➕ 新しい原本を作る」で行う。
g-form-master() {
  local account="${1}"
  local name="${2}"
  if [[ -z "$account" || -z "$name" ]]; then
    echo "使用方法: g-form-master <personal|facil|church|...> <フォームマスター名>"
    echo "例: g-form-master church \"仁川教会 フォームマスター\""
    return 1
  fi

  local base="/Users/aokitomohiro/Documents/20_Websites/98_tomo-gas-project"
  local slug="$(date +%Y%m%d)_$(echo "$name" | tr ' /' '_-')"
  local dir="$base/instances/${account}_${slug}"

  if [[ -d "$dir" ]]; then
    echo "❌ すでに存在します: $dir"
    return 1
  fi

  gas-use "$account" || return 1

  mkdir -p "$dir"
  cp "$base/event-form-generator/"*.js \
     "$base/event-form-generator/"*.html \
     "$base/event-form-generator/appsscript.json" "$dir/" || return 1
  cd "$dir" || return 1

  echo "📁 作業ディレクトリ: $dir"
  echo "🚀 フォームマスターを作成中..."

  clasp create --type sheets --title "$name" && clasp push --force || return 1

  # .clasp.json からスプレッドシートIDを取り出してブラウザで開く
  # （clasp open はスクリプトエディタを開くので使わない）
  local sheet_id=$(python3 -c "import json; print(json.load(open('.clasp.json')).get('parentId',[''])[0])" 2>/dev/null)
  if [[ -n "$sheet_id" ]]; then
    local url="https://docs.google.com/spreadsheets/d/$sheet_id/edit"
    echo "✅ 完成！ブラウザを開きます..."
    echo "   $url"
    echo ""
    echo "   メニュー「📋 フォーム作成ツール」→「➕ 新しい原本を作る」から始めてください。"
    open "$url"
  else
    echo "⚠️ スプレッドシートIDが取得できませんでした。手動で開いてください。"
    echo "   ディレクトリ: $dir"
  fi
}

# テンプレのコードを各フォームマスターへ配布する
#   g-form-push            … 全アカウント（本番を含むので注意）
#   g-form-push personal   … 指定アカウントのみ
g-form-push() {
  local base="/Users/aokitomohiro/Documents/20_Websites/98_tomo-gas-project"
  "$base/scripts/push-all.sh" "$@"
}
