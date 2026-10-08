#!/usr/bin/env bash
# オーケストレーターのペインの右に、セッションの数だけペインを縦に並べ、各ペインで Claude を起動する。
#
# 使い方:
#   bash launch-panes.sh <orchestration_dir> "<タブ名>|<worktree の絶対パス>|<指示書のファイル名>[|<モデル>]" ...
#   <モデル> は任意（claude --model に渡す）。空なら --config の workers.model、それも無ければ claude の既定
#   --config <config.yml> を最初に渡すと、workers.model を読む（プロンプトで聞かずに決まる）
# 例:
#   bash launch-panes.sh ~/dev/myfeature-orchestration \
#     "S1 1234 ログインの制限|$HOME/dev/feature/1234-login-limit|s1-1234.md" \
#     "S2 t2 一覧の並び替え|$HOME/dev/feature/t2-list-sort|s2-t2.md"
#
# 出力: 1 行に 1 つ「<タブ名>\t<surface ref>」（監視と指示の追加に使う）
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "使い方: launch-panes.sh <orchestration_dir> \"<タブ名>|<worktree>|<指示書>\" ..." >&2
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
# python3 は asdf などの shim で、版の無いディレクトリでは動かないことがあるため、JSON はシェルで読む
# （"caller" の塊の中の最初の surface_ref が、このスクリプトを呼んだペイン）
SELF="$(cmux identify | awk '/"caller"/{c=1} c && /"surface_ref"/{gsub(/[",]/,"",$3); print $3; exit}')"
[[ "${SELF}" == surface:* ]] || { echo "自分の surface を取れませんでした: ${SELF}" >&2; exit 1; }

# "OK surface:18 workspace:1" から "surface:18" を取り出す
split() { cmux new-split "$1" --surface "$2" --focus false | awk '{print $2}'; }

prev=""
for spec in "$@"; do
  IFS='|' read -r title worktree brief model <<< "${spec}"
  if [[ -z "${prev}" ]]; then
    surface="$(split right "${SELF}")"
  else
    surface="$(split down "${prev}")"
  fi
  cmux rename-tab --surface "${surface}" "${title}" >/dev/null
  prompt="${ORCH}/common.md と ${ORCH}/${brief} を読み、その指示に従って作業してください。ステータスは ${ORCH}/status/ に書いてください。"
  model_opt=""
  model="${model:-${DEFAULT_MODEL}}"
  [[ -n "${model}" ]] && model_opt="--model '${model}' "
  cmux send --surface "${surface}" "cd '${worktree}' && claude ${model_opt}'${prompt}'" >/dev/null
  cmux send-key --surface "${surface}" Enter >/dev/null
  printf '%s\t%s\n' "${title}" "${surface}"
  prev="${surface}"
done
