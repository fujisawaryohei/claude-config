# 設定（リポジトリごとの値）

skill 本体からリポジトリ固有の値を外に出すための設定。**どれも無くても動く**（無ければ Phase 0 でリポジトリから推測し、ユーザーに確かめる）。

## 置き場（上から順に探す）

| 順 | 置き場 | 向いているとき |
|---|---|---|
| 1 | リポジトリの `.claude/cmux-orchestrate.yml` | チームで同じ設定を使う（コミットが要る） |
| 2 | `~/.claude/cmux-orchestrate/profiles/<PJ 名>/config.yml`（既定・git 管理外） | 自分の手元だけで使う（リポジトリも skill の git も変えない） |
| 3 | この skill の `profiles/<PJ 名>/config.yml`（git 管理） | 公開してよい PJ を、ほかのマシンへ持っていく |

## 項目

```yaml
worktree:
  base_branch: main                     # 切る元（origin/<base_branch> から切る）。無ければ origin の既定のブランチ
  dir: ../{id}-{slug}                   # リポジトリのルートからの相対。{id} はタスク ID（チケット番号 or t1…）
  branch: feature/{id}-{slug}
  bootstrap: ""                         # worktree を作った後に回すコマンド（無ければ回さない）
  must_exist: []                        # 初期設定の後に、在ることを確かめる成果物（例: node_modules・.venv）
  after_bootstrap: ""                   # must_exist が欠けたときに回す補いのコマンド（無ければユーザーに聞く）
assets: {}                              # ワーカーが使う、リポジトリの外の素材（名前: パス）。common.md の「素材・環境」に書き写す
workers:
  model: ""                             # ワーカーの claude に --model で渡す（空なら起動の前にユーザーに聞いて、ここに書く）
  per_task: {}                          # タスクごとに変えるとき（タスク ID: モデル）
env: {}                                 # ワーカーと with-lock.sh に渡す環境変数
shared_resources: {}                    # 1 組を取り合うもの（ローカルのコンテナ・DB など）。with-lock.sh で 1 本ずつ使わせる
  # <名前>:
  #   lock_file: /tmp/<repo>-<名前>.lock
  #   prepare: "<ロックの中で、コマンドの前に worktree のルートで回すもの>"
  #   check_mount: { container: <名前>, destinations: [<マウント先>], expect_prefix: "{worktree}/..." }
  #   restore_hint: "<作業の後に戻す手順>"
verify:
  default: ""                           # ワーカーが完了の前に回す検証（例: make test・pnpm test）
review:
  agents: []                            # オーケストレーターがレビューに使うサブエージェント（無ければ一般の code-reviewer）
tickets:                                # 任意。チケットを使わないなら丸ごと書かない
  show: ""                              # 例: gh issue view {ticket} ／ az boards work-item show --id {ticket}
  assign: ""
  create: ""                            # チケットが無いタスクに、了承の後でチケットを作るとき
rules:
  no_commit: true                       # ワーカーはコミットしない
  language: ja                          # 返答・ステータスの言語
  docs_sync: ""                         # 設計書を同じ PR で直す約束があれば、その場所（例: docs/specs/）
```

## 無いときの既定

| 項目 | 既定 |
|---|---|
| `worktree.base_branch` | `git symbolic-ref refs/remotes/origin/HEAD` の先 |
| `worktree.dir` / `branch` | `../{id}-{slug}` / `feature/{id}-{slug}` |
| `worktree.bootstrap` | なし（依存のインストールが要りそうなら、オーケストレーターが聞く） |
| `shared_resources` | なし（ロックを使わない）。ただし docker compose のプロジェクト名が固定のリポジトリでは、取り合いになるので必ず設定する（[pitfalls.md](pitfalls.md)） |
| `verify.default` | リポジトリの CLAUDE.md・Makefile・package.json から推測して、ユーザーに確かめる |
| `review.agents` | 一般の code-reviewer |
| `tickets` | なし（チケット無しで計画する） |
| `rules.no_commit` / `language` | `true` / 会話の言語 |

## 例

- 実例は git 管理外の `~/.claude/cmux-orchestrate/profiles/<PJ 名>/config.yml` に置く（社外秘の PJ の値を skill の git に入れないため。profile.md の「置き場」）
