#!/usr/bin/env bash
# PJ のハーネス（Claude Code の設定・ルール・skill・agent と、開発の決まりが書かれたファイル）の指紋を取る。
# プロファイル（profiles/<PJ 名>/）を作り直すべきかの判断に使う。
#
#   bash harness-digest.sh name            # PJ 名（メイン checkout のフォルダ名）を出す
#   bash harness-digest.sh list            # 対象のファイルの一覧
#   bash harness-digest.sh digest          # 「<sha1> <パス>」の一覧（digest.txt にそのまま保存できる）
#   bash harness-digest.sh diff <digest.txt>  # 保存した指紋との差（変わった・増えた・消えたファイル）。差が無ければ何も出さず 0 で終わる
#
# worktree の中から呼んでも、メイン checkout と同じ PJ 名・同じ対象を見る（ファイルの中身は worktree のもの）。
# 秘密値のファイル（.env など）は対象にしない。
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
common="$(cd "$(git rev-parse --git-common-dir)" && pwd)"
name="$(basename "$(dirname "${common}")")"

list_files() {
  cd "${root}"
  {
    git ls-files -- \
      'CLAUDE.md' '*/CLAUDE.md' 'AGENTS.md' \
      '.claude/rules/**' '.claude/agents/**' '.claude/settings.json' \
      'Makefile' 'package.json' '*/package.json' 'pyproject.toml' '*/pyproject.toml' \
      'commitlint.config.*' '.commitlintrc*' '.lintstagedrc*' \
      '.github/workflows/*' '.github/pull_request_template*' '.github/CODEOWNERS' \
      'azure-pipelines.yml' '.azure/pipelines/**' '.gitlab-ci.yml' \
      '.wtp.yml' 'docker-compose*.yml' 'docker/docker-compose*.yml' 'compose*.yml' \
      2>/dev/null
    # skill は本体（SKILL.md）だけ見る。添付の素材は量が多く、しきたりは SKILL.md に書かれるため
    git ls-files -- '.claude/skills/*/SKILL.md' 2>/dev/null
  } | grep -v -E '(^|/)\.env|node_modules/' | sort -u
}

digest() {
  cd "${root}"
  list_files | while IFS= read -r f; do
    [[ -f "$f" ]] && printf '%s %s\n' "$(shasum -a 1 "$f" | awk '{print $1}')" "$f"
  done
}

case "${1:-}" in
  name) echo "${name}" ;;
  list) list_files ;;
  digest) digest ;;
  diff)
    saved="${2:?保存した digest.txt のパスを渡してください}"
    [[ -f "${saved}" ]] || { echo "保存した指紋がありません: ${saved}"; exit 2; }
    diff <(sort -k2 "${saved}") <(digest | sort -k2) | awk '
      /^</ {old[$3]=$2} /^>/ {new[$3]=$2}
      END {
        for (f in new) if (f in old) print "変わった " f; else print "増えた   " f
        for (f in old) if (!(f in new)) print "消えた   " f
      }' | sort -k2
    ;;
  *) echo "使い方: harness-digest.sh name|list|digest|diff <digest.txt>" >&2; exit 1 ;;
esac
