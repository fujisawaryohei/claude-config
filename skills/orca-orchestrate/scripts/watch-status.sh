#!/usr/bin/env bash
# ステータスファイルの「段」が変わるたびに 1 行出す（Monitor の command に渡す）。
#   bash watch-status.sh <orchestration_dir>/status
# zsh で回すと、一致の無い glob で落ちるため、必ず bash で回す。
set -uo pipefail
shopt -s nullglob

DIR="${1:?ステータスの置き場を渡してください}"
last=""
while true; do
  cur=""
  for f in "${DIR}"/*.md; do
    stage="$(grep -m1 -E '^- 段:' "$f" 2>/dev/null | sed 's/^- 段: *//')"
    cur="${cur}$(basename "$f" .md)=${stage:-不明}; "
  done
  if [[ "${cur}" != "${last}" ]]; then
    echo "ステータス変化: ${cur:-（まだファイルなし）}"
    last="${cur}"
  fi
  sleep 5
done
