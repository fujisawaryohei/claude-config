# fitbit-agent のプロファイル
- 作った日: 2026-10-09 ／ 走査したファイル: 20 件（digest.txt）
- 正本: この PJ の CLAUDE.md・.claude/skills・.claude/agents・.faceted/facets・.takt/facets。食い違ったら正本に従い、このファイルを直す

## 1. 開発の流れ
- ルートの CLAUDE.md は AI-DLC を「ほかのワークフローより優先」と宣言している ／ CLAUDE.md:1-2
- ただし運用は形骸化している（aidlc-state.md が 2026-06 の Requirements Analysis のまま）。並行実装のワーカーには回させない（2026-10-09 にユーザーが決めた） ／ aidlc-docs/aidlc-state.md:7,12
- 機能実装の流れ: Research → Plan → TDD → Code Review → Commit（許可制） ／ .claude/skills/coding-backend/SKILL.md:129-145
- Issue 起点の全自動実行は TAKT の issue-driven-dev ／ .takt/workflows/issue-driven-dev.yaml

## 2. 検証
- バックエンドとエージェントのテスト: `uv run pytest backend/tests/ agent/tests/ -q`。ホストで回す。README（:161）は `test_planning_tools_llm.py` を `--ignore` するが、このファイルは LLM をモックにしていて DB・AWS 無しで 4 件とも通る（2026-10-09 に確認）ので外さない ／ README.md:161
- テストはほぼモックで完結する（conftest の container fixture）。ただし `backend/tests/controllers/test_chat.py` の `test_no_cookie_returns_401` 3 件は DB（5432）に接続し、DB が起動していないと落ちる（2026-10-09 に main で確認。DB 無しで 109 passed / 3 failed） ／ backend/tests/conftest.py
- カバレッジの目標は 80% ／ README.md:164
- mypy・ruff は設定だけあり、skill から実行されていない ／ pyproject.toml:36-64
- `python3` を直接呼ばない。`uv run python` を使う ／ .claude/agents/fitbit-backend-dev.md:80
- フロントエンド: `cd frontend && npx tsc --noEmit`。テストのランナーは無い ／ .claude/agents/fitbit-frontend-dev.md:73

## 3. レビュー（オーケストレーターが使う agent・skill）
- skill `code-review`（CRITICAL・HIGH・MEDIUM・LOW。CRITICAL・HIGH は必ず直す） ／ .claude/skills/code-review/SKILL.md
- 認証・入力・API を触るときは skill `security-review`
- レビュー専用の agent はリポジトリに無い

## 4. 設計書・ドキュメントの同期
- ドキュメントは aidlc-docs/、調査・QA は qa-docs/ ／ CLAUDE.md:536-539
- 実装に合わせて設計書を直す明文化されたルールは無い（過去は手で直していた: 1d384ba）
- Claude の設定を直すときは .faceted/facets も直す（.claude/skills/*/SKILL.md は生成物） ／ .claude/skills/*/SKILL.md:6

## 5. コミット・PR・ブランチ
- `<type>: <description>`（feat/fix/refactor/docs/test/chore/perf/ci）、日本語 ／ .faceted/facets/policies/git-workflow.md:3-9
- Co-Authored-By・AI の署名は付けない ／ .faceted/facets/policies/git-workflow.md:11
- PR の本文は Summary／Changes／Test Plan。`Closes #<番号>`。`--body-file` で渡す ／ .claude/skills/coding-backend/SKILL.md:152-167・.takt/facets/instructions/create-pr.md
- base は main。ブランチ名の規約は無い。squash かは未確認（PR の実績が 0 件）

## 6. チケット
- GitHub Issue。`gh issue view {番号} --repo fujisawaryohei/fitbit-agent --json number,title,body,comments` ／ .takt/facets/knowledge/github-workflow.md
- 起票は skill `issue-create`

## 7. 共有リソースと環境
- docker compose はプロジェクト名が固定でない（worktree ごとに別）が、ホストの 5432 が固定で取り合う ／ docker-compose.yml:1-13
- 開発サーバ: `make server`（8000 固定）・`make frontend`（3000）・`make ngrok` ／ Makefile:3-4
- Fitbit の OAuth の Callback URL と ngrok は 1 組だけ
- `.env`（ルート・frontend）は git 管理外。新しい worktree には無い
- 新しい worktree の DB は空。`uv run alembic upgrade head` が要る

## 8. してはいけないこと
- 明示の指示なしに commit・push・PR をしない ／ .faceted/facets/policies/no-commit-without-permission.md
- テストの無い実装を完了にしない ／ .claude/agents/fitbit-backend-dev.md:81
- フォールバック・既定値で握りつぶさない。計画外のついでのリファクタをしない ／ .takt/facets/policies/coding.md
- 生成物の .claude/skills/*/SKILL.md を直接編集しない

## 9. 作業の種類ごとに使う skill・agent
- バックエンド: skill `coding-backend`・agent `fitbit-backend-dev`／フロントエンド: skill `coding-frontend`・agent `fitbit-frontend-dev`／TDD: skill `tdd`
- agent と start-feature-team に古いパス `/home/ubuntu/Project/fitbit-agent` が残っている

## 10. 言語・書き方
- 日本語（skill・Issue・コミット・UI のエラー）。関数は 50 行未満・ファイルは 800 行まで・イミュータブル

## 11. CI が強制するもの／ローカルでしか守られないもの
- CI・hooks・commitlint・pre-commit は無い（CI は Issue #4 で未着手）。上の決まりはすべてローカルの指示だけで守られる

## 12. 未確認（リポジトリの外にある決まり）
- GitHub の branch protection・merge の方式・Project の番号
- Fitbit Developer の Callback URL の登録・AWS（Bedrock）の認証情報

## common.md に書き写すもの（オーケストレーションに関わる分だけ）
- AI-DLC のワークフローは回さない（指示書が計画と承認を兼ねる。aidlc-docs・audit.md は書かない）
- 検証のコマンド（上の 2）。`python3` を直接呼ばない
- commit・push・PR をしない
- 設計書（aidlc-docs）は直さず、直す案をステータスに書く
