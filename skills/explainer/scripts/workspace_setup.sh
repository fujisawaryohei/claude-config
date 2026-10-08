#!/usr/bin/env bash
# explainer スキル（グローバル版）の作業場所を用意する。スキルの実行のたびに最初に呼ぶ。
#
# あるプロジェクトの .claude/scripts/explainer_workspace_setup.sh を元に、作業場所をリポジトリの外
# （既定 ~/.cache/explainer。EXPLAINER_WS で変えられる）にした。どのリポジトリでも .gitignore を足さずに済む。
#
# 何をするか:
#   - <ws>/package.json が無ければ作る
#   - 検証スクリプト（verify-doc.mjs / figure-check.mjs）の依存が無ければ <ws> に npm で入れる
#   - Playwright の Chromium が無ければ入れる（図の描画と vlmkit の検査に使う）
#   - すべて揃っていれば何もしない（2 回目以降は数秒で終わる）
#
# なぜ作業場所を分けるか:
#   verify-doc.mjs は資料のディレクトリから上へたどって最初の package.json の node_modules を使う。
#   資料を <ws>/<slug>/ に置けば、ここに入れた依存が使われ、リポジトリの package.json に資料用の道具を足さずに済む。
set -euo pipefail

WS="${EXPLAINER_WS:-$HOME/.cache/explainer}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKGS=(@mizchi/vlmkit @mizchi/vlmkit-anim marked playwright)

if [ -L "$WS/node_modules" ] && [ ! -e "$WS/node_modules" ]; then
  echo "❌ $WS/node_modules がリンク先の無いシンボリックリンクです。外してから再実行してください:" >&2
  echo "   unlink \"$WS/node_modules\"" >&2
  exit 1
fi

mkdir -p "$WS"
if [ ! -f "$WS/package.json" ]; then
  printf '{\n  "name": "explainer-docs-local",\n  "private": true,\n  "type": "module"\n}\n' > "$WS/package.json"
  echo "▶ $WS/package.json を作りました"
fi

missing=()
for p in "${PKGS[@]}"; do
  [ -f "$WS/node_modules/$p/package.json" ] || missing+=("$p")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "▶ 依存を入れます: ${missing[*]}"
  (cd "$WS" && npm i -D --no-audit --no-fund "${PKGS[@]}")
fi

if ! (cd "$WS" && node -e "const fs=require('fs');process.exit(fs.existsSync(require('playwright').chromium.executablePath())?0:1)") 2>/dev/null; then
  echo "▶ Playwright の Chromium を入れます"
  (cd "$WS" && npx --no-install playwright install chromium)
fi

echo "✅ explainer の作業場所: $WS（資料は $WS/<slug>/ に置く）"
echo "   検証: cd \"$WS\" && node \"$SKILL_DIR/scripts/verify-doc.mjs\" <slug>"
