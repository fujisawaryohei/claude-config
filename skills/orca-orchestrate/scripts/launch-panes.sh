#!/usr/bin/env bash
# オーケストレーターのペインの右に、セッションの数だけペインを縦に並べ、各ペインで Claude を起動する。
# ターミナルは cmux と Orca のどちらでもよい（mux.sh が見分ける）。
#
# 使い方:
#   bash launch-panes.sh [--config <config.yml>] <orchestration_dir> "<タブ名>|<worktree の絶対パス>|<指示書のファイル名>[|<モデル>]" ...
#   <モデル> は任意（claude --model に渡す）。空なら --config の workers.model、それも無ければ claude の既定
#   --config <config.yml> を最初に渡すと、workers.model を読む（プロンプトで聞かずに決まる）
# 例:
#   bash launch-panes.sh ~/dev/myfeature-orchestration \
#     "S1 1234 ログインの制限|$HOME/dev/feature/1234-login-limit|s1-1234.md" \
#     "S2 t2 一覧の並び替え|$HOME/dev/feature/t2-list-sort|s2-t2.md"
#
# 出力: 1 行に 1 つ「<タブ名>\t<ペインの ref>」（監視と指示の追加に使う）。
# Orca ではペインごとに名前を付けられないため、この対応表がペインを見分ける手がかりになる。
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mux.sh"

if [[ $# -lt 2 ]]; then
  echo "使い方: launch-panes.sh [--config <config.yml>] <orchestration_dir> \"<タブ名>|<worktree>|<指示書>\" ..." >&2
  exit 1
fi

CONFIG=""
if [[ "${1:-}" == "--config" ]]; then CONFIG="$2"; shift 2; fi
ORCH="$1"; shift
# workers.model を読む（yq に頼らない。インデントの深さで workers: の直下の model: だけを拾う）
DEFAULT_MODEL=""
if [[ -n "${CONFIG}" && -f "${CONFIG}" ]]; then
  DEFAULT_MODEL="$(awk '/^workers:/{w=1; next} /^[^ #]/{w=0} w && /^  model:/{sub(/^  model:[ ]*/, ""); sub(/[ ]*#.*$/, ""); print; exit}' "${CONFIG}")"
fi

MUX_BACKEND="${MUX_BACKEND:-$(mux_backend)}"
export MUX_BACKEND
SELF="$(mux_self)"
[[ -n "${SELF}" ]] || { echo "自分のペインを取れませんでした（${MUX_BACKEND}）" >&2; exit 1; }

prev=""
for spec in "$@"; do
  IFS='|' read -r title worktree brief model <<< "${spec}"
  prompt="${ORCH}/common.md と ${ORCH}/${brief} を読み、その指示に従って作業してください。ステータスは ${ORCH}/status/ に書いてください。"
  model_opt=""
  model="${model:-${DEFAULT_MODEL}}"
  [[ -n "${model}" ]] && model_opt="--model '${model}' "
  cmd="cd '${worktree}' && claude ${model_opt}'${prompt}'"
  # 1 本目は自分の右に、2 本目からは 1 つ前のペインの下に分ける
  if [[ -z "${prev}" ]]; then
    pane="$(mux_split right "${SELF}" "${cmd}")"
  else
    pane="$(mux_split down "${prev}" "${cmd}")"
  fi
  mux_rename "${pane}" "${title}"
  printf '%s\t%s\n' "${title}" "${pane}"
  prev="${pane}"
done
