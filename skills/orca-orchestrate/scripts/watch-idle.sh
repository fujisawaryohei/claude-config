#!/usr/bin/env bash
# Orca のワーカーのペインが止まった（処理中の表示が消えた）／動き出したときに 1 行出す（Monitor の command に渡す）。
#
#   bash watch-idle.sh term_… term_…
#
# Orca の terminal read は、Claude Code の TUI に対して最後に描き直した 1 行しか返さない。
# そのため許可の確認の文字（watch-permissions.sh の方法）を拾えないので、terminal show の preview から
# 「処理中（… ・ tokens ・ thinking）か」だけを見る。止まった理由（許可の確認・入力待ち・完了）は分からないので、
# 止まったらステータスファイルを読み、それでも分からなければユーザーにそのペインを見てもらう。
#
# preview は描き直しの途中の 1 行を拾うことがあり、1 回だけの「止まった」は誤検知になりやすい。
# IDLE_CONFIRM 回（既定 3 回 ＝ 約 15 秒）続けて止まっていたときだけ「idle」を出す。
# bash 3.2（macOS の /bin/bash）でも動くよう、連想配列を使わない。
set -uo pipefail

if [[ $# -eq 0 ]]; then
  echo "使い方: watch-idle.sh <term_…> ..." >&2
  exit 1
fi

INTERVAL="${INTERVAL:-5}"
IDLE_CONFIRM="${IDLE_CONFIRM:-3}"

for a in "$@"; do [[ -n "$a" ]] || { echo "ペインの ref が空です" >&2; exit 1; }; done
declare -a handles=("$@")
declare -a reported=()   # 最後に出した状態（busy / idle / gone）
declare -a idle_count=()
for i in "${!handles[@]}"; do reported[$i]="busy"; idle_count[$i]=0; done

while true; do
  for i in "${!handles[@]}"; do
    h="${handles[$i]}"
    json="$(orca terminal show --terminal "$h" --json 2>/dev/null || true)"
    preview="$(sed -n 's/.*"preview": *"\(.*\)",*$/\1/p' <<< "${json}" | head -1)"
    title="$(sed -n 's/.*"title": *"\(.*\)",*$/\1/p' <<< "${json}" | head -1)"
    if [[ -z "${json}" ]]; then
      state="gone"
    elif grep -q -E '…|tokens|thinking' <<< "${preview}"; then
      state="busy"; idle_count[$i]=0
    else
      idle_count[$i]=$(( idle_count[$i] + 1 ))
      # 続けて止まっていた回数が足りないうちは、前の状態のままにする
      if (( idle_count[$i] >= IDLE_CONFIRM )); then state="idle"; else state="${reported[$i]}"; fi
    fi
    if [[ "${state}" != "${reported[$i]}" ]]; then
      echo "${h:0:13} [${title}] ${state}: ${preview}" | cut -c1-300
      reported[$i]="${state}"
    fi
  done
  sleep "${INTERVAL}"
done
