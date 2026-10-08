#!/usr/bin/env bash
# ペインの操作を、ターミナル（cmux / Orca）の違いを吸収して同じ形で呼ぶための層。
#
# コマンドとして:
#   bash mux.sh backend                       # cmux | orca（MUX_BACKEND で固定もできる）
#   bash mux.sh self                          # 自分のペインの ref（cmux: surface:N ／ orca: term_…）
#   bash mux.sh split <right|down> <ref> [<command>]  # 分割し、新しいペインの ref を出す
#   bash mux.sh rename <ref> <タイトル>
#   bash mux.sh send <ref> <テキスト>          # テキストを送って Enter を押す
#   bash mux.sh read <ref> [<行数>]            # 画面の末尾を出す（既定 45 行）
#   bash mux.sh notify <タイトル> <本文>       # ユーザーの注意を引く
#   bash mux.sh close <ref>
# ほかのスクリプトからは source して mux_* を呼ぶ。
#
# python3 は asdf などの shim で、版の無いディレクトリでは動かないことがあるため、JSON は sed・awk で読む。

mux_backend() {
  if [[ -n "${MUX_BACKEND:-}" ]]; then
    echo "${MUX_BACKEND}"
  elif [[ -n "${ORCA_TERMINAL_HANDLE:-}" ]] && command -v orca >/dev/null 2>&1; then
    echo orca
  elif command -v cmux >/dev/null 2>&1 && cmux identify >/dev/null 2>&1; then
    echo cmux
  else
    echo "cmux の中でも Orca の中でもありません（MUX_BACKEND=cmux|orca で固定できます）" >&2
    return 1
  fi
}

mux_self() {
  case "$(mux_backend)" in
    # "caller" の塊の中の最初の surface_ref が、このスクリプトを呼んだペイン
    cmux) cmux identify | awk '/"caller"/{c=1} c && /"surface_ref"/{gsub(/[",]/,"",$3); print $3; exit}' ;;
    orca) echo "${ORCA_TERMINAL_HANDLE}" ;;
    *) return 1 ;;
  esac
}

# Orca の --json の出力から、最初の term_… を取り出す
_orca_handle() { sed -n 's/.*"handle": *"\(term_[^"]*\)".*/\1/p' | head -1; }

mux_split() {
  local dir="$1" ref="$2" cmd="${3:-}" new
  case "$(mux_backend)" in
    cmux)
      # 出力は "OK surface:18 workspace:1"。2 つ目の語だけが ref
      new="$(cmux new-split "${dir}" --surface "${ref}" --focus false | awk '{print $2}')"
      [[ -n "${cmd}" ]] && mux_send "${new}" "${cmd}"
      ;;
    orca)
      # Orca の horizontal は左右、vertical は上下に分ける
      local odir=horizontal
      [[ "${dir}" == down || "${dir}" == up ]] && odir=vertical
      local args=(terminal split --terminal "${ref}" --direction "${odir}" --json)
      [[ -n "${cmd}" ]] && args+=(--command "${cmd}")
      new="$(orca "${args[@]}" | _orca_handle)"
      ;;
    *) return 1 ;;
  esac
  [[ -n "${new}" ]] || { echo "ペインを分割できませんでした（${ref}）" >&2; return 1; }
  echo "${new}"
}

mux_rename() {
  case "$(mux_backend)" in
    cmux) cmux rename-tab --surface "$1" "$2" >/dev/null ;;
    # Orca の rename はペインではなくタブ（分割したペインが共有する）の名前を変えるため、何もしない
    orca) : ;;
    *) return 1 ;;
  esac
}

mux_send() {
  case "$(mux_backend)" in
    # cmux send は改行を送らないので、続けて Enter を押す
    cmux) cmux send --surface "$1" "$2" >/dev/null && cmux send-key --surface "$1" Enter >/dev/null ;;
    orca) orca terminal send --terminal "$1" --text "$2" --enter --json >/dev/null ;;
    *) return 1 ;;
  esac
}

mux_read() {
  local lines="${2:-45}"
  case "$(mux_backend)" in
    cmux) cmux read-screen --surface "$1" --lines "${lines}" ;;
    # 先頭の「handle: …」「status: …」などの見出しと、その後の空行を捨てて本文だけを出す
    orca) orca terminal read --terminal "$1" --limit "${lines}" \
            | awk 'BEGIN{h=1} h && /^[a-z][a-z ]*:( |$)/ {next} h && /^$/ {h=0; next} {h=0; print}' ;;
    *) return 1 ;;
  esac
}

mux_notify() {
  local title="$1" body="${2:-}"
  case "$(mux_backend)" in
    cmux) cmux notify --title "${title}" --body "${body}" ;;
    # Orca に通知のコマンドは無い。オーケストレーターの worktree のカードにコメントを書き、未読の印を付ける
    # （分割したペインは、オーケストレーターの ORCA_WORKTREE_ID を引き継ぐ）
    orca) orca worktree set --worktree "id:${ORCA_WORKTREE_ID:?}" --comment "${title}: ${body}" --unread --json >/dev/null ;;
    *) return 1 ;;
  esac
}

mux_close() {
  case "$(mux_backend)" in
    cmux) cmux close-surface --surface "$1" ;;
    orca) orca terminal close --terminal "$1" --json >/dev/null ;;
    *) return 1 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  sub="${1:-}"; shift || true
  case "${sub}" in
    backend|self|split|rename|send|read|notify|close) "mux_${sub}" "$@" ;;
    *) echo "使い方: mux.sh backend|self|split|rename|send|read|notify|close ..." >&2; exit 1 ;;
  esac
fi
