# claude-config

Claude Code の Skills と設定ファイルを管理するリポジトリ。

## 構成

```
claude-config/
├── skills/                  # Claude Code カスタムスキル群
│   ├── task-assigner/       # タスク選定 + ペアプロ形式の作業指示
│   ├── parallel-dev/        # tmux + git worktree による並列開発
│   ├── impl-plan/           # 追加機能の実装プラン策定
│   ├── create-tasklist/     # タスク一覧（.steering/tasklist.md）作成
│   ├── create-planning/     # プロジェクト企画書作成
│   ├── create-requirements/ # 要件定義書作成
│   ├── create-basic-design/ # 基本機能設計書作成
│   └── create-architecture/ # アーキテクチャ設計書・リポジトリ定義書・開発ガイドライン作成
├── settings.json            # Claude Code グローバル設定（パーミッション等）
├── setup.sh                 # セットアップスクリプト
└── README.md
```

## セットアップ

```bash
git clone <this-repo> ~/Development/claude-config
cd ~/Development/claude-config
bash setup.sh
```

`setup.sh` は以下を実行します:
- `~/.claude/settings.json` を本リポジトリのものに置き換え（既存はバックアップ）
- `~/.claude/skills` → 本リポジトリの `skills/` へシンボリックリンクを作成

## 開発フロー

スキルは2つのフローで使います。

### 初期開発

```
/create-planning → /create-requirements → /create-basic-design
  → /create-architecture → /create-tasklist → /task-assigner / /parallel-dev
```

### 追加開発（機能追加）

```
/impl-plan → /create-tasklist → /task-assigner / /parallel-dev
```

## スキルの更新

スキルを編集すると、シンボリックリンク経由で `~/.claude/skills` に即座に反映されます。
