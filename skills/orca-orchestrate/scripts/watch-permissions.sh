#!/usr/bin/env bash
# ワーカーのペインに Claude Code の許可の確認が出たら 1 行出す（Monitor の command に渡す）。cmux・Orca のどちらでも動く。
# オーケストレーターはこれを受けて、そのペインの画面を読み、許可してよいかの推奨をユーザーに出す。
# **キーは送らない**（決めるのはユーザー）。
#
#   bash watch-permissions.sh surface:17 surface:18 surface:19      # cmux
#   bash watch-permissions.sh term_ab12… term_cd34…                 # Orca
#
# cmux の Feed（PermissionRequest の hook）にカードが届かない環境の代わり。zsh ではなく bash で回す。
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mux.sh"
# 4 秒ごとに見分け直さないよう、最初に 1 回だけ決める
MUX_BACKEND="${MUX_BACKEND:-$(mux_backend)}" || exit 1
export MUX_BACKEND

if [[ $# -eq 0 ]]; then
  echo "使い方: watch-permissions.sh <ペインの ref> ..." >&2
  exit 1
fi

for a in "$@"; do [[ -n "$a" ]] || { echo "ペインの ref が空です" >&2; exit 1; }; done
declare -a surfaces=("$@")
declare -a last_sig=()
for i in "${!surfaces[@]}"; do last_sig[$i]=""; done

while true; do
  for i in "${!surfaces[@]}"; do
    s="${surfaces[$i]}"
    screen="$(mux_read "$s" 45 2>/dev/null | grep -v -E '^Permission (allow|deny) rule')"
    if grep -q -E 'Do you want to (proceed|make this edit|create)|❯ 1\. Yes' <<< "${screen}"; then
      # 確認の画面の中身（コマンドの本文〜「Do you want to」）を 1 行に畳む。
      # Claude Code はコマンドの本文と質問の間に区切りの線（╌）を引くので、線は捨てるだけで中身は残す
      body="$(awk '/Do you want to/{print buf $0; exit} !/^[[:space:]]*(╌|─)+[[:space:]]*$/{buf=buf $0 "\n"}' <<< "${screen}" \
        | sed -E 's/^[[:space:]│⎿]+//' | grep -v -E '^$' | tail -14 | tr '\n' ' ' | cut -c1-700)"
      sig="$(printf '%s' "${body}" | cksum | awk '{print $1}')"
      if [[ "${sig}" != "${last_sig[$i]}" ]]; then
        echo "許可の確認 ${s}: ${body}"
        last_sig[$i]="${sig}"
      fi
    elif [[ -n "${last_sig[$i]}" ]]; then
      echo "確認の解消 ${s}"
      last_sig[$i]=""
    fi
  done
  sleep 4
done
