#!/usr/bin/env zsh
# gpush の受け入れテスト
#
#   zsh ~/.dotfiles/zsh/tests/gpush-test.zsh
#
# 使い捨ての一時ディレクトリだけを触る。実リポジトリには一切影響しない。

set -u

# スクリプト自身の位置から解決する（絶対パスを埋め込まない）
SCRIPT_DIR="${0:A:h}"
FUNCTIONS_FILE="${SCRIPT_DIR:h}/functions.zsh"

[[ -f "$FUNCTIONS_FILE" ]] || { print -r -- "❌ 対象が見つかりません: $FUNCTIONS_FILE"; exit 1 }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gpush-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT INT TERM

PASS=0
FAIL=0

# 注意: ((VAR++)) は VAR が 0 のとき終了コード1を返す。
# 末尾に return 0 を置かないと呼び出し側の `&& ok ... || ng ...` が両方走る。
ok() { print -r -- "  ✅ $1"; ((PASS++)); return 0 }
ng() { print -r -- "  ❌ $1"; ((FAIL++)); return 0 }

REPO="$WORK/repo"
REMOTE="$WORK/remote/origin.git"

setup_repo() {
  rm -rf "$WORK/repo" "$WORK/remote"
  mkdir -p "$WORK/remote"
  git init --bare -q "$REMOTE"
  git init -q -b main "$REPO"
  git -C "$REPO" config user.email "test@example.com"
  git -C "$REPO" config user.name  "test"
  git -C "$REPO" remote add origin "$REMOTE"
  echo "init" > "$REPO/README.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -q -m "init"
  git -C "$REPO" push -q -u origin main
}

commit_count() { git -C "$REPO" rev-list --count HEAD }
last_msg()     { git -C "$REPO" log -1 --format=%s }

source "$FUNCTIONS_FILE"

print -r -- "=== gpush 受け入れテスト ==="
print -r -- "対象: $FUNCTIONS_FILE"
print -r -- ""

# ---------------------------------------------------------------
print -r -- "[1] 変更なし → コミットされず、正常終了する"
setup_repo; cd "$REPO"
before=$(commit_count)
out=$(gpush "なにか" 2>&1 </dev/null); rc=$?
[[ "$before" == "$(commit_count)" ]] && ok "コミットが増えていない" || ng "コミットが増えた"
[[ "$rc" == "0" ]] && ok "終了コード 0" || ng "終了コード $rc"
[[ "$out" == *"変更はありません"* ]] && ok "「変更はありません」を表示" || ng "表示が違う: $out"
print -r -- ""

# ---------------------------------------------------------------
print -r -- "[2] N で中止 → コミットされない"
setup_repo; cd "$REPO"
echo "change" >> "$REPO/README.md"
before=$(commit_count)
out=$(print -r -- "N" | gpush "中止テスト" 2>&1); rc=$?
[[ "$before" == "$(commit_count)" ]] && ok "コミットが増えていない" || ng "中止したのにコミットされた"
[[ "$rc" != "0" ]] && ok "終了コードが 0 以外 ($rc)" || ng "中止なのに 0 を返した"
[[ "$out" == *"中止しました"* ]] && ok "中止メッセージあり" || ng "中止メッセージなし: $out"
print -r -- ""

# ---------------------------------------------------------------
print -r -- "[3] y + メッセージ指定 → そのメッセージでコミットされ push される"
setup_repo; cd "$REPO"
echo "change" >> "$REPO/README.md"
before=$(commit_count)
out=$(print -r -- "y" | gpush "指定したメッセージ" 2>&1); rc=$?
after=$(commit_count)
(( after == before + 1 )) && ok "コミットが1つ増えた" || ng "コミット数 $before → $after"
[[ "$(last_msg)" == "指定したメッセージ" ]] && ok "メッセージが引数どおり" || ng "メッセージ: $(last_msg)"
[[ "$rc" == "0" ]] && ok "終了コード 0" || ng "終了コード $rc"
[[ "$(git -C "$REMOTE" log -1 --format=%s main 2>/dev/null)" == "指定したメッセージ" ]] \
  && ok "remote に push されている" || ng "remote に届いていない"
print -r -- ""

# ---------------------------------------------------------------
print -r -- "[4] 引数なし → メッセージが update になる"
setup_repo; cd "$REPO"
echo "change" >> "$REPO/README.md"
out=$(print -r -- "y" | gpush 2>&1)
[[ "$(last_msg)" == "update" ]] && ok "デフォルト update" || ng "メッセージ: $(last_msg)"
print -r -- ""

# ---------------------------------------------------------------
print -r -- "[5] gitリポジトリ外 → エラーで止まる"
mkdir -p "$WORK/notrepo"; cd "$WORK/notrepo"
out=$(print -r -- "y" | gpush "だめ" 2>&1); rc=$?
[[ "$rc" != "0" ]] && ok "終了コードが 0 以外 ($rc)" || ng "リポジトリ外なのに 0 を返した"
[[ "$out" == *"gitリポジトリではありません"* ]] && ok "エラーメッセージあり" || ng "出力: $out"
print -r -- ""

# ---------------------------------------------------------------
print -r -- "[6] upstream 未設定の新規ブランチ → -u を付けて push される"
setup_repo; cd "$REPO"
git -C "$REPO" checkout -q -b feature/new
echo "change" >> "$REPO/README.md"
out=$(print -r -- "y" | gpush "新規ブランチ" 2>&1); rc=$?
[[ "$rc" == "0" ]] && ok "終了コード 0" || ng "終了コード $rc / 出力: $out"
up=$(git -C "$REPO" rev-parse --abbrev-ref 'feature/new@{u}' 2>/dev/null)
[[ "$up" == "origin/feature/new" ]] && ok "upstream が設定された" || ng "upstream: ${up:-なし}"
[[ "$(git -C "$REMOTE" log -1 --format=%s feature/new 2>/dev/null)" == "新規ブランチ" ]] \
  && ok "remote にブランチが作られた" || ng "remote にブランチがない"
print -r -- ""

# ---------------------------------------------------------------
print -r -- "[7] 未追跡ファイルも変更として検出される"
setup_repo; cd "$REPO"
echo "new" > "$REPO/newfile.txt"
before=$(commit_count)
out=$(print -r -- "y" | gpush "未追跡を含む" 2>&1)
(( $(commit_count) == before + 1 )) && ok "未追跡ファイルでコミットされた" || ng "コミットされなかった"
git -C "$REPO" ls-files --error-unmatch newfile.txt >/dev/null 2>&1 \
  && ok "newfile.txt が追跡下に入った" || ng "newfile.txt が入っていない"
print -r -- ""

# ---------------------------------------------------------------
print -r -- "[8] detached HEAD → エラーで止まる"
setup_repo; cd "$REPO"
git -C "$REPO" checkout -q --detach HEAD
echo "change" >> "$REPO/README.md"
before=$(commit_count)
out=$(print -r -- "y" | gpush "detached" 2>&1); rc=$?
[[ "$rc" != "0" ]] && ok "終了コードが 0 以外 ($rc)" || ng "detached なのに 0 を返した"
[[ "$out" == *"detached HEAD"* ]] && ok "エラーメッセージあり" || ng "出力: $out"
[[ "$before" == "$(commit_count)" ]] && ok "コミットされていない" || ng "コミットされてしまった"
print -r -- ""

cd /
print -r -- "=== 結果: PASS $PASS / FAIL $FAIL ==="
(( FAIL == 0 )) || exit 1
