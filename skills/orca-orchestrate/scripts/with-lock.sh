#!/usr/bin/env bash
# 共有リソース（ローカルのコンテナなど）を使うコマンドを、worktree 間で 1 本ずつ回す入口。
#
# 置き場（<orchestration_dir>）にコピーし、下の 3 つを設定してから使う（.claude/orca-orchestrate.yml の
# shared_resources の値）。ワーカーは worktree のルートで次のように呼ぶ:
#   bash <orchestration_dir>/with-lock.sh make verify-affected
#
#   LOCK_FILE    ロックのファイル
#   PREPARE      ロックの中で、コマンドの前に worktree のルートで回すもの（例: このworktree でコンテナを作り直す）
#   CHECK_MOUNT  任意。"<コンテナ名> <マウント先>[,<マウント先>…]"。マウント元が worktree の中でなければ止める
set -euo pipefail

LOCK_FILE="${LOCK_FILE:-/tmp/orca-orchestrate.lock}"
PREPARE="${PREPARE:-}"
CHECK_MOUNT="${CHECK_MOUNT:-}"

if [[ $# -eq 0 ]]; then
  echo "使い方: with-lock.sh <コマンド...>（worktree のルートで実行する）" >&2
  exit 1
fi

WORKTREE="$(git rev-parse --show-toplevel)"
echo "[with-lock] ロックを待っています: ${LOCK_FILE}（worktree: ${WORKTREE}）"

# macOS は lockf、Linux は flock
if command -v lockf >/dev/null 2>&1; then
  LOCKER=(lockf -k "${LOCK_FILE}")
else
  LOCKER=(flock "${LOCK_FILE}")
fi

exec "${LOCKER[@]}" bash -c '
  set -euo pipefail
  worktree="$1"; prepare="$2"; check_mount="$3"; shift 3
  cd "${worktree}"
  echo "[with-lock] ロックを取りました"
  if [[ -n "${prepare}" ]]; then
    bash -c "${prepare}" >/dev/null 2>&1
  fi
  if [[ -n "${check_mount}" ]]; then
    container="${check_mount%% *}"; dests="${check_mount#* }"
    for i in $(seq 1 60); do
      health="$(docker inspect "${container}" --format "{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}" 2>/dev/null || echo missing)"
      [[ "${health}" == "healthy" || "${health}" == "none" ]] && break
      sleep 2
    done
    IFS=, read -r -a dest_list <<< "${dests}"
    for dest in "${dest_list[@]}"; do
      src="$(docker inspect "${container}" --format "{{range .Mounts}}{{if eq .Destination \"${dest}\"}}{{.Source}}{{end}}{{end}}")"
      if [[ "${src}" != "${worktree}"/* ]]; then
        echo "[with-lock] ${dest} のマウント元が worktree の外です: ${src}" >&2
        exit 2
      fi
    done
    echo "[with-lock] マウント元を確認しました"
  fi
  "$@"
' _ "${WORKTREE}" "${PREPARE}" "${CHECK_MOUNT}" "$@"
