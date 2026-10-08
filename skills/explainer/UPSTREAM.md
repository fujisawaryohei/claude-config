# 取り込み元（グローバル版）

このディレクトリは、あるプロジェクトが外部リポジトリ https://github.com/mizchi/explainer（commit 9a2f8af6a2296ad9ad59f1606d8f54e7c7107f59・
2026-10-01）をプロジェクト向けに書き換えて取り込んだ版を、2026-10-09 にグローバル用に写したもの。

## グローバル版で直したところ

| 箇所 | 元のプロジェクト版 | グローバル版 |
|---|---|---|
| 作業場所 | `<repo>/.dev/explainer/`（`.gitignore` 済み） | `${EXPLAINER_WS:-~/.cache/explainer}`（リポジトリの外） |
| 準備のスクリプト | リポジトリの `.claude/scripts/` の中 | `scripts/workspace_setup.sh`（このディレクトリの中） |
| 着せ替え | 必ずプロジェクトのデザインに着せ替える | リポジトリに `.claude/scripts/explainer_doc_style.py` があるときだけ |
| 既定のペルソナ | 必ずプロジェクトのチーム共通のペルソナ | リポジトリ → `~/.claude/explainer/personas/`（git 管理外）→ このディレクトリ → 依頼した本人の順 |
| first-reader | 必ず使う | あれば使う |

社外秘のプロジェクトのペルソナ・資料は、このディレクトリ（skill の git）に置かない。`~/.claude/explainer/personas/` に置く。
上流を取り込み直すときは、上流から取り込み直してから、この表の差分を当て直す。
