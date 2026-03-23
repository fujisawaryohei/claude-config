# claude-config

Claude Code の Skills・設定・ルール・フックを管理するリポジトリ。

## 参考リポジトリ

- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (MIT License)
  Claude Code を最大限活用するためのプラグイン集。14のエージェント、28+のスキル、30のスラッシュコマンドを収録。TDD・セキュリティレビュー・継続的学習・マルチエージェントワークフロー等を網羅。本リポジトリのスキルの多くはここから取り込んでいます。

## 構成

```
claude-config/
├── skills/                        # Claude Code カスタムスキル群
│   ├── -- 設計・計画 --
│   ├── create-planning/           # プロジェクト企画書作成
│   ├── create-requirements/       # 要件定義書作成
│   ├── create-basic-design/       # 基本機能設計書作成
│   ├── create-architecture/       # アーキテクチャ設計書・リポジトリ定義書・開発ガイドライン作成
│   ├── create-tasklist/           # タスク一覧（.steering/tasklist.md）作成
│   ├── impl-plan/                 # 追加機能の実装プラン策定
│   ├── api-design/                # API設計
│   ├── -- 開発ワークフロー --
│   ├── task-assigner/             # タスク選定 + ペアプロ形式の作業指示
│   ├── parallel-dev/              # tmux + git worktree による並列開発
│   ├── tdd-workflow/              # テスト駆動開発ワークフロー
│   ├── backend-patterns/          # バックエンド実装パターン
│   ├── frontend-patterns/         # フロントエンド実装パターン
│   ├── coding-standards/          # コーディング規約チェック
│   ├── verification-loop/         # 実装の検証ループ
│   ├── iterative-retrieval/       # 反復的な情報収集
│   ├── -- テスト・品質 --
│   ├── e2e-testing/               # E2Eテスト
│   ├── ai-regression-testing/     # AIを使ったリグレッションテスト
│   ├── eval-harness/              # 評価ハーネス
│   ├── security-review/           # セキュリティレビュー
│   ├── -- ナレッジ・最適化 --
│   ├── continuous-learning-v2/    # 信頼度スコア付きの経験学習
│   ├── strategic-compact/         # コンテキスト戦略的圧縮
│   ├── skill-stocktake/           # スキル棚卸し・現状確認
│   ├── skill-creator/             # 新スキル作成・改善
├── rules/                         # Claude Code グローバルルール
│   ├── agents.md                  # エージェント利用ガイドライン
│   ├── coding-style.md            # コーディングスタイル
│   ├── development-workflow.md    # 開発ワークフロー
│   ├── git-workflow.md            # Gitワークフロー
│   ├── hooks.md                   # フック設定ガイド
│   ├── patterns.md                # 設計パターン
│   ├── performance.md             # パフォーマンスガイドライン
│   ├── security.md                # セキュリティガイドライン
│   └── testing.md                 # テストガイドライン
├── hooks/                         # イベント自動化フック
│   ├── notify.sh                  # 通知スクリプト（共通）
│   └── wsl-toast.ps1              # WSL Windowsトースト通知
├── settings.json                  # Claude Code グローバル設定（パーミッション等）
├── setup.sh                       # セットアップスクリプト
└── README.md
```

## セットアップ

```bash
git clone <this-repo> ~/claude-config
cd ~/claude-config
bash setup.sh
```

`setup.sh` は以下を実行します:
- `~/.claude/settings.json` を本リポジトリのものに置き換え（既存はバックアップ）
- `~/.claude/skills` → 本リポジトリの `skills/` へシンボリックリンクを作成

## 開発フロー

### 初期開発

```
/create-planning → /create-requirements → /create-basic-design
  → /create-architecture → /create-tasklist → /task-assigner / /parallel-dev
```

### 追加開発（機能追加）

```
/impl-plan → /create-tasklist → /task-assigner / /parallel-dev
```

### テスト・品質確認

```
/tdd-workflow → /verification-loop → /e2e-testing → /security-review
```

## スキルの更新

スキルを編集すると、シンボリックリンク経由で `~/.claude/skills` に即座に反映されます。
