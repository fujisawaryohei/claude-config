#!/usr/bin/env bash
# ワーカーが「判断待ち」「レビュー待ち」をユーザーに知らせる入口。cmux・Orca のどちらでも同じ形で呼べる。
# 置き場（<orchestration_dir>）に mux.sh と一緒にコピーして使う。
#
#   bash <orchestration_dir>/notify.sh "<タスク ID> 判断待ち" "<一行で>"
#
# cmux: cmux notify の通知。Orca: オーケストレーターの worktree のカードのコメント ＋ 未読の印。
# 知らせられなくても止まらない（オーケストレーターはステータスファイルを見ているため）。
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mux.sh"

if [[ $# -lt 1 ]]; then
  echo "使い方: notify.sh <タイトル> [<本文>]" >&2
  exit 1
fi

mux_notify "$1" "${2:-}" || echo "[notify] 知らせられませんでした（ステータスファイルは書いてあるので、そのまま止まってください）" >&2
exit 0
