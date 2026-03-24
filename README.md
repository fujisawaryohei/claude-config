# claude-config

Claude Code の Agents・Skills・Commands・Rules・Hooks・Scripts を管理するリポジトリ。
業務用・私用PC共通の `.claude/` 設定として運用。

## 参考リポジトリ

- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (MIT License)
  Claude Code を最大限活用するためのプラグイン集。本リポジトリのコンポーネントの多くはここから取り込んでいます。

---

## セットアップ

```bash
git clone <this-repo> ~/Development/claude/claude-config
cd ~/Development/claude/claude-config
bash setup.sh
```

`setup.sh` は以下を実行します:

- `~/.claude/settings.json` を本リポジトリのものに置き換え（既存はバックアップ）
- `~/.claude/skills` → `skills/` へシンボリックリンクを作成
- `~/.claude/hooks` → `hooks/` へシンボリックリンクを作成
- `~/.claude/commands` → `commands/` へシンボリックリンクを作成
- `~/.claude/agents` → `agents/` へシンボリックリンクを作成
- `~/.claude/rules` → `rules/` へシンボリックリンクを作成
- `~/.claude/scripts` → `scripts/` へシンボリックリンクを作成

---

## ディレクトリ構成

```
claude-config/
├── agents/          # 専門エージェント（12種）
├── commands/        # スラッシュコマンド（28種）
├── rules/           # 常時適用ルール（10種）
├── skills/          # on-demandスキル（25種）
├── hooks/           # 通知スクリプト
├── scripts/
│   ├── hooks/       # Hook実行スクリプト（19種）
│   ├── lib/         # 共有ライブラリ（7種）
│   └── orchestrate-worktrees.js  # Worktree並列実行CLI
├── settings.json    # グローバル設定・パーミッション・Hook定義
└── setup.sh         # セットアップスクリプト
```

---

## Agents（12種）

Claudeが状況を判断して自律的に呼び出す専門ワーカー。各々が独立したコンテキストウィンドウを持つ。

| Agent | モデル | 機能 |
|-------|--------|------|
| `planner` | opus | 実装前の計画立案。PRD・アーキテクチャ設計・タスク分解をドキュメントに落とし込む |
| `tdd-guide` | sonnet | テスト駆動開発の強制。「テスト先→RED→実装→GREEN→リファクタ」のサイクルを守らせる |
| `e2e-runner` | sonnet | Playwrightを使ったE2Eテストの生成と実行。クリティカルなユーザーフローを検証 |
| `code-reviewer` | sonnet | コード品質・セキュリティ・可読性のレビュー。CRITICAL/HIGH/MEDIUMで重大度を分類 |
| `security-reviewer` | sonnet | OWASP Top 10に基づくセキュリティ脆弱性の検出。SQLi・XSS・認証不備などを検査 |
| `architect` | opus | システム設計・依存関係・スケーラビリティの判断。大きな構造変更前に呼ぶ |
| `refactor-cleaner` | sonnet | デッドコード・未使用依存関係の除去。knip/depcheck/ts-pruneで機械的に検出 |
| `database-reviewer` | sonnet | PostgreSQL/Supabaseのスキーマ・クエリ・マイグレーション専門レビュー |
| `doc-updater` | haiku | READMEやコードマップの更新。軽量なタスクなのでhaiku担当 |
| `docs-lookup` | sonnet | Context7 MCPを使ったライブラリドキュメントの即時参照 |
| `loop-operator` | sonnet | 自律ループの監視・管理。停滞検出・コスト逸脱・マージ競合時に介入する |
| `build-error-resolver` | sonnet | ビルド失敗・型エラーを最小diffで修正。アーキテクチャ変更はしない |

---

## Commands（28種）

`/コマンド名` で人間が明示的に起動するワークフロー。

### 開発フロー（10種）

| Command | 機能 |
|---------|------|
| `/plan` | planner agentを起動。実装計画・PRD・タスクリストを生成 |
| `/tdd` | tdd-guide agentを起動。テスト先行の開発サイクルを強制 |
| `/e2e` | e2e-runner agentを起動。E2Eテストを生成・実行 |
| `/code-review` | code-reviewer agentを起動。コード品質・セキュリティを審査 |
| `/build-fix` | build-error-resolver agentを起動。ビルドエラーを即修正 |
| `/verify` | ビルド・lint・型チェック・テストをまとめて検証 |
| `/refactor-clean` | refactor-cleaner agentを起動。デッドコードを除去 |
| `/test-coverage` | カバレッジ計測と80%未満箇所の洗い出し |
| `/quality-gate` | コミット前の最終品質チェックゲート |
| `/model-route` | タスク複雑度に応じてHaiku/Sonnet/Opusを使い分けるルーティング |

### ドキュメント・セッション（8種）

| Command | 機能 |
|---------|------|
| `/docs` | doc-updater agentを起動。README・ドキュメントを更新 |
| `/update-docs` | 変更に合わせてドキュメント全体を同期 |
| `/update-codemaps` | コードマップ（ファイル構造の概要図）を再生成 |
| `/learn` | セッションから再利用可能なパターンを抽出してskillに昇格 |
| `/checkpoint` | 現在の作業状態をセッションファイルに保存 |
| `/save-session` | セッション内容をエイリアスつきで永続保存 |
| `/resume-session` | 保存済みセッションを名前で呼び出して文脈を復元 |
| `/aside` | メインの作業を中断せずサブタスクをこなす（例：調査・メモ） |

### Instinctシステム（7種）

会話から学習した知識（Instinct）を管理する永続学習システム。`~/.claude/homunculus/` にYAMLで蓄積される。

| Command | 機能 |
|---------|------|
| `/instinct-status` | 蓄積されたInstinctの一覧・健全性を表示 |
| `/instinct-export` | Instinctを外部ファイルにエクスポート（バックアップ・共有） |
| `/instinct-import` | 外部ファイルからInstinctをインポート |
| `/evolve` | 既存Instinctをより汎用的・洗練された形に進化させる |
| `/promote` | 仮のInstinctを本番Instinctとして確定させる |
| `/prune` | 陳腐化・重複したInstinctを削除して品質を保つ |
| `/projects` | プロジェクト横断でInstinctの分布と活用状況を確認 |

### ループ・オーケストレーション（3種）

| Command | 機能 |
|---------|------|
| `/loop-start` | 自律ループを開始。パターン（sequential/continuous-pr/rfc-dag/infinite）とモード（safe/fast）を指定 |
| `/loop-status` | 実行中ループの進捗・フェーズ・コスト逸脱を確認 |
| `/orchestrate` | 複数agentを直列・並列で連鎖実行。feature/bugfix/refactor/securityのワークフロー型を選択 |

---

## Rules（10種）

Claudeが**毎回起動時に読み込む**常時適用ルール。コンテキストを消費するため精選済み。

| Rule | 機能 |
|------|------|
| `coding-style` | イミュータブルパターン必須・関数50行以内・ネスト4段以内などのコーディング規約 |
| `testing` | 最低カバレッジ80%・TDD必須・Unit/Integration/E2E全種類要求 |
| `security` | コミット前セキュリティチェックリスト・秘密情報管理・OWASP準拠 |
| `git-workflow` | conventional commits形式・PRワークフロー手順 |
| `development-workflow` | 実装前のGitHub検索→ライブラリ調査→TDD→レビューの全フロー |
| `performance` | Haiku/Sonnet/Opusの使い分け基準・コンテキストウィンドウ管理 |
| `patterns` | Repositoryパターン・API応答形式・スケルトンプロジェクト活用 |
| `agents` | 利用可能Agentの一覧・並列実行の原則・いつどのAgentを使うかの判断基準 |
| `hooks` | PreToolUse/PostToolUse/Stopの使い分け・TodoWriteベストプラクティス |
| `global-claude-architecture` | skills/agents/commands/rules/hooksそれぞれの責務定義と判断フロー（設計憲法） |

---

## Skills（25種）

タスクの文脈からClaudeが**自動的に参照**する手順書。on-demandなのでコンテキストを常時消費しない。

### 開発プロセス

| Skill | 自動発火タイミング |
|-------|----------------|
| `tdd-workflow` | TDD・テスト先行の話題 |
| `coding-standards` | コーディング規約・スタイルの確認 |
| `verification-loop` | 実装後の検証・確認ループ |
| `e2e-testing` | E2Eテスト作成・Playwright |
| `ai-regression-testing` | AIを使った回帰テスト設計 |
| `security-review` | セキュリティ審査・脆弱性検出 |
| `eval-harness` | LLMの評価ハーネス構築 |

### 設計・計画

| Skill | 自動発火タイミング |
|-------|----------------|
| `impl-plan` | 実装計画の策定 |
| `create-planning` | プロジェクト計画ドキュメント作成 |
| `create-architecture` | アーキテクチャ設計 |
| `create-requirements` | 要件定義・PRD作成 |
| `create-tasklist` | タスク分解・リスト生成 |
| `create-basic-design` | 基本設計書作成 |
| `task-assigner` | タスクの担当割り当て |

### フロントエンド・バックエンド

| Skill | 自動発火タイミング |
|-------|----------------|
| `frontend-patterns` | Reactコンポーネント・UIパターン |
| `backend-patterns` | API設計・サーバーサイドパターン |
| `api-design` | REST/GraphQL API設計 |
| `parallel-dev` | フロント・バック同時並行開発 |

### 自律ループ・マルチエージェント

| Skill | 自動発火タイミング |
|-------|----------------|
| `autonomous-loops` | 自律ループ設計・パターン選択の相談 |
| `dmux-workflows` | tmux複数ペインで並列エージェント実行 |
| `continuous-learning-v2` | Instinctシステム・学習パターン |
| `strategic-compact` | コンテキストウィンドウの戦略的圧縮 |

### 調査・最適化

| Skill | 自動発火タイミング |
|-------|----------------|
| `search-first` | 実装前に既存ライブラリ・実装を探す |
| `iterative-retrieval` | 段階的な情報収集・調査 |
| `skill-stocktake` | 蓄積されたskillの棚卸し・整理 |

---

## Hooks（自動実行、19スクリプト）

Claude Code のライフサイクルイベントで**強制的に**実行される処理。

`ECC_HOOK_PROFILE=minimal|standard|strict` で動作を制御（デフォルト: `standard`）。

| タイミング | Hook | 機能 |
|-----------|------|------|
| **PreToolUse** | `pre-bash-tmux-reminder` | 長時間コマンド実行前にtmux使用を促す（strict） |
| | `pre-bash-git-push-reminder` | git push前にレビューを促す（strict） |
| | `doc-file-warning` | 非標準ドキュメントファイル作成を警告（standard+） |
| | `suggest-compact` | 50ツール呼び出しごとに `/compact` を提案（standard+） |
| | `config-protection` | linter/formatter設定ファイルの改変をブロック（standard+） |
| | `observe.sh` | ツール使用観測をInstinctシステムに記録（async、standard+） |
| **PreCompact** | `pre-compact` | コンテキスト圧縮前にセッション状態を保存（standard+） |
| **SessionStart** | `session-start` | 前回セッションの文脈復元・パッケージマネージャー検出（minimal+） |
| **PostToolUse** | `post-bash-pr-created` | PR作成後にURLとレビューコマンドを表示（standard+） |
| | `quality-gate` | ファイル編集後にBiome/Prettier/ruffで品質チェック（async、standard+） |
| | `post-edit-format` | JS/TSファイル編集後に自動フォーマット（strict） |
| | `post-edit-typecheck` | .ts/.tsx編集後にtsc型チェック（strict） |
| | `post-edit-console-warn` | console.log残存を編集後に警告（standard+） |
| | `observe.sh` | ツール実行結果をInstinctシステムに記録（async、standard+） |
| **Stop** | `check-console-log` | 応答完了後にgit変更ファイルのconsole.logを検査（standard+） |
| | `session-end` | トランスクリプトからセッション要約を抽出・保存（async、minimal+） |
| | `evaluate-session` | セッションから抽出可能なパターンを評価（async、minimal+） |
| | `cost-tracker` | トークン使用量とコストを `~/.claude/metrics/costs.jsonl` に記録（async、minimal+） |
| **SessionEnd** | `session-end-marker` | セッション終了のライフサイクルマーカー（async、minimal+） |

---

## Scripts（ライブラリ・ツール）

Hooksおよびオーケストレーションが依存する共有ライブラリ群。

| ファイル | 役割 |
|---------|------|
| `hooks/run-with-flags.js` | Hook本体。プロファイル判定→スクリプト実行のコアディスパッチャー |
| `hooks/run-with-flags-shell.sh` | bashスクリプト版Hook（observe.sh用） |
| `lib/hook-flags.js` | `ECC_HOOK_PROFILE` / `ECC_DISABLED_HOOKS` の判定ロジック |
| `lib/utils.js` | ファイルI/O・git操作・ANSI除去などのクロスプラットフォームユーティリティ |
| `lib/resolve-formatter.js` | Biome/Prettierの自動検出とバイナリ解決 |
| `lib/package-manager.js` | npm/pnpm/yarn/bunの自動検出（lockfileやpackage.json参照） |
| `lib/session-aliases.js` | セッションエイリアスのCRUD（`~/.claude/session-aliases.json`） |
| `lib/tmux-worktree-orchestrator.js` | git worktree + tmuxペインの作成・管理・ロールバック |
| `orchestrate-worktrees.js` | worktree並列オーケストレーションCLI（`plan.json`を受け取り実行） |

### Worktree並列実行

```bash
# plan.json を作成
cat > plan.json <<'EOF'
{
  "sessionName": "my-feature",
  "baseRef": "HEAD",
  "launcherCommand": "claude",
  "workers": [
    { "name": "frontend", "task": "src/components/ に型を追加" },
    { "name": "backend",  "task": "src/api/ にバリデーションを追加" }
  ]
}
EOF

# ドライラン（確認）
node ~/.claude/scripts/orchestrate-worktrees.js plan.json

# 実行
node ~/.claude/scripts/orchestrate-worktrees.js plan.json --execute
tmux attach -t my-feature
```

---

## 開発フロー早見表

### 初期開発

```
/plan → /tdd → /code-review → /verify → commit
```

### 機能追加

```
/plan → /tdd → /code-review → /build-fix（必要時）→ /verify → commit
```

### 品質・セキュリティ確認

```
/code-review → /quality-gate → /test-coverage → /e2e
```

### マルチエージェント並列開発

```
plan.json 作成 → orchestrate-worktrees.js --execute → tmux attach → 各ペインで作業 → merge
```

---

## コンポーネント数

| 種別 | 数 |
|------|----|
| Agents | 12 |
| Commands | 28 |
| Rules | 10 |
| Skills | 25 |
| Hook scripts | 19 |
| Library / Scripts | 9 |
| **合計** | **103** |

---

## 使い方集

### Loop管理システム

自律ループを使うと、複数の `claude -p` 呼び出しを組み合わせた無人開発パイプラインを構築できる。

#### パターン選択

| パターン | 向いているケース |
|----------|----------------|
| `sequential` | タスクリストを順番に処理 |
| `continuous-pr` | PRを自動作成→CI待ち→マージを繰り返す |
| `rfc-dag` | RFCを依存DAGに分解して並列実装（大規模機能向け） |
| `infinite` | 明示的に止めるまで繰り返す |

#### 基本的な使い方

```bash
# ループを開始（Claudeがrunbookを .claude/plans/ に生成する）
/loop-start sequential
/loop-start continuous-pr --mode fast
/loop-start rfc-dag

# 進捗・コスト逸脱を確認
/loop-status
/loop-status --watch   # 定期更新で監視
```

#### Sequential Pipeline を自前で書く

`/loop-start` を使わず、シェルスクリプトで直接書く最もシンプルな形。

```bash
#!/bin/bash
set -e

# Step 1: 実装（TDD）
claude -p "docs/spec.md を読んで src/feature/ に実装。テスト先行（TDD）。"

# Step 2: De-sloppify（不要なテスト・過剰な防御コードを除去する後片付けパス）
claude -p "直前のコミットで変更されたファイルを見直す。
型システムが保証済みの型チェックテスト、言語仕様のテスト、console.log、
コメントアウトされたコードを削除。ビジネスロジックのテストは残す。
削除後にテストスイートを実行。"

# Step 3: 検証
claude -p "ビルド・lint・型チェック・テストをすべて実行。失敗があれば修正。"

# Step 4: コミット
claude -p "conventional commit形式でコミット。"
```

> **De-sloppifyパターンの要点**: 「〜するな」という否定指示は品質劣化を招く。
> 実装フェーズは自由にやらせ、別パスで除去する。2つの集中したエージェントの方が1つの制約されたエージェントより強い。

#### モデルルーティングを組み合わせる

```bash
# 深い推論が必要な調査はOpus
claude -p --model opus "アーキテクチャを分析して caching の設計方針をdocs/に書く。"

# 実装はSonnet（速い・高性能）
claude -p "docs/caching-plan.md に従って実装。"

# レビューはOpus（徹底的に）
claude -p --model opus "全変更をセキュリティ・競合状態・エッジケース視点でレビュー。"
```

#### 自動停止条件（loop-operatorが監視）

以下のいずれかで `loop-operator` エージェントが介入・停止する：

- 2チェックポイント連続で進捗なし
- 同一スタックトレースのエラーが繰り返し発生
- コストが予算ウィンドウを逸脱
- マージ競合がキューをブロック

---

### Instinctシステム

セッションから行動パターンを自動学習して蓄積する永続学習システム。
`~/.claude/homunculus/` にYAMLとして保存され、プロジェクトスコープとグローバルスコープで管理される。

#### 仕組み

```
Claude Code セッション
      │
      │ PreToolUse/PostToolUse フックが100%確実にキャプチャ
      ▼
~/.claude/homunculus/projects/<project-hash>/observations.jsonl
      │
      │ バックグラウンドのObserverエージェント（Haiku）が分析
      ▼
Instinct（atomic YAML）として保存
  例: prefer-functional-style.yaml  confidence: 0.7  scope: project
      │
      │ /evolve でクラスタリング
      ▼
skills/ commands/ agents/ として昇格（進化）
```

#### Instinctのスコープ

| パターン種別 | スコープ | 例 |
|------------|---------|-----|
| 言語・フレームワーク規約 | **project** | React Hooks使用、Django REST規約 |
| ファイル構造の好み | **project** | テストは `__tests__/`、コンポーネントは `src/components/` |
| コードスタイル | **project** | 関数型スタイル優先、dataclass使用 |
| セキュリティプラクティス | **global** | ユーザー入力バリデーション、SQLサニタイズ |
| 汎用ベストプラクティス | **global** | テスト先行、エラー必ずハンドル |
| ツールワークフロー | **global** | Edit前にGrep、Write前にRead |

#### 日常的な使い方

```bash
# 学習状況を確認（プロジェクト + グローバル、信頼度スコア付き）
/instinct-status

# 蓄積されたInstinctをSkill/Command/Agentに昇格候補として提案
/evolve

# 高信頼度のプロジェクトInstinctをグローバルに昇格
/promote

# 陳腐化・重複したInstinctを削除して品質維持
/prune

# 全プロジェクトのInstinct分布を確認
/projects
```

#### バックアップ・共有

```bash
# エクスポート（生のobservationsではなくパターンのみ）
/instinct-export

# 別マシンや別ユーザーからインポート
/instinct-import path/to/instincts.yaml
```

#### 信頼度スコアの見方

| スコア | 意味 |
|--------|------|
| 0.3 | 仮説段階。提案するが強制しない |
| 0.5 | 適度な確信。関連する場面で適用 |
| 0.7 | 強い確信。自動承認で適用 |
| 0.9 | ほぼ確実。コア行動として定着 |

スコアは観測の繰り返し・ユーザーの修正・矛盾証拠によって上下する。

#### ファイル構成

```
~/.claude/homunculus/
├── projects.json           # プロジェクトID→名前のレジストリ
├── instincts/personal/     # グローバルinstinct
├── evolved/                # 昇格済みskill/command/agent
└── projects/
    └── <project-hash>/
        ├── observations.jsonl
        ├── instincts/personal/   # プロジェクト固有instinct
        └── evolved/
```

---

### tmux + git worktree 並列開発

独立したタスクを複数のClaude Codeセッションで同時進行させる方法。
ファイル競合を避けるために各ワーカーは専用のgit worktreeで作業する。

#### 基本構成

```
メインブランチ (main)
  ├── worktree: feature/frontend  ← Claudeセッション1
  ├── worktree: feature/backend   ← Claudeセッション2
  └── worktree: feature/tests     ← Claudeセッション3

各セッションが完了後 → git merge → 統合
```

#### orchestrate-worktrees.js を使う（推奨）

**Step 1: plan.jsonを作成**

```json
{
  "sessionName": "my-feature",
  "baseRef": "HEAD",
  "launcherCommand": "claude",
  "workers": [
    { "name": "frontend", "task": "src/components/ に型アノテーションを追加。既存の実装は変えない。" },
    { "name": "backend",  "task": "src/api/ のエンドポイントにバリデーションを追加。" },
    { "name": "tests",    "task": "src/utils/ のユーティリティ関数のユニットテストを書く。" }
  ]
}
```

**Step 2: ドライランで確認**

```bash
node ~/.claude/scripts/orchestrate-worktrees.js plan.json
# → worktreeのパス・ブランチ名・task.md の内容を表示（実行はしない）
```

**Step 3: 実行**

```bash
node ~/.claude/scripts/orchestrate-worktrees.js plan.json --execute
# → 各worktreeを作成し、tmuxセッションで起動
```

**Step 4: tmuxで監視**

```bash
tmux attach -t my-feature
# Ctrl+B → 数字キーでペイン切り替え
# Ctrl+B → d でデタッチ（セッションは継続）
```

**Step 5: 完了後にマージ**

```bash
# 各ブランチを順番にマージ
git merge feature/my-feature-frontend
git merge feature/my-feature-backend
git merge feature/my-feature-tests

# worktreeを削除
git worktree remove ../my-feature-frontend
git worktree remove ../my-feature-backend
git worktree remove ../my-feature-tests
```

#### seedPaths: 未コミットファイルをworktreeに渡す

ローカルの未コミットファイル（スクリプト・計画ドキュメント等）をワーカーに見せたい場合：

```json
{
  "sessionName": "my-feature",
  "seedPaths": [
    "docs/feature-spec.md",
    "scripts/helper.js"
  ],
  "workers": [
    { "name": "worker1", "task": "docs/feature-spec.md を読んで実装する。" }
  ]
}
```

#### 手動でworktreeを使う（シンプルな2並列）

```bash
# worktreeを作成
git worktree add -b feat/frontend ../work-frontend HEAD
git worktree add -b feat/backend  ../work-backend  HEAD

# 別ターミナルでそれぞれClaudeを起動
# ターミナル1:
cd ../work-frontend && claude

# ターミナル2:
cd ../work-backend && claude

# 完了後にマージ
cd <元のリポジトリ>
git merge feat/frontend
git merge feat/backend

# worktreeを削除
git worktree remove ../work-frontend
git worktree remove ../work-backend
git branch -d feat/frontend feat/backend
```

#### 並列化できるタスクの選び方

| 並列化できる | 並列化できない |
|------------|--------------|
| 独立したモジュール・ファイルへの変更 | 同じファイルを両方が編集するケース |
| テスト追加（実装は触らない） | A の実装が完了しないと B が書けない |
| 別々のAPIエンドポイント | 共通の型定義を同時に変更 |
| フロントエンドとバックエンド | リファクタリング（広範囲にわたる場合） |

#### dmux を使う場合

tmuxペインを手動でコントロールしたい場合は dmux を使う方法もある。
`n` で新ペイン作成、`m` で結果をメインセッションにマージ。

```bash
# dmuxセッション開始
dmux

# n を押してペインを作成し、プロンプトを入力:
# Pane 1: "src/auth/ のセキュリティ審査"
# Pane 2: "src/api/ のパフォーマンス審査"
# Pane 3: "src/api/ のテストカバレッジ確認"

# 各ペインの完了後に m でメインにマージ
```

インストール: [github.com/standardagents/dmux](https://github.com/standardagents/dmux) を確認してからインストール。
