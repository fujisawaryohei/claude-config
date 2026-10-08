# Orca の CLI の知見

Orca（stablyai の、worktree とエージェントを束ねるデスクトップアプリ）を `orca` コマンドで操るときの要点。
2026-10-09 に Orca 1.4.222 で調べた。**「確かめた」と書いたものは実際に回した結果、それ以外は help・同梱の skill の記述。**

## 正本（ここが古くなったら、こちらを見る）

| 見るもの | コマンド |
|---|---|
| コマンドの一覧と使い方 | `orca --help` ／ `orca <group> <cmd> --help` |
| 全コマンドの機械可読な仕様（242 件・schema v1） | `orca agent-context --json` |
| Orca に同梱のエージェント向けの手引き | `orca skills list` → `orca skills get orca-cli` ／ `orca skills get orchestration` |

CLI の実体は `/Applications/Orca.app/Contents/Resources/bin/orca`。Orca のターミナルでは PATH に入っている。
ほとんどのコマンドは Orca が起動している必要がある（`orca status --json` の `runtime.state` が `ready`。起動していなければ `orca open`）。

## Orca の中にいるかの見分け方（確かめた）

Orca のターミナルには次の環境変数が入る。`scripts/mux.sh backend` はこれで見分ける。

| 変数 | 中身 |
|---|---|
| `TERM_PROGRAM` | `Orca` |
| `ORCA_TERMINAL_HANDLE` | 自分のペインのハンドル（`term_…`）。cmux の `identify` の代わり |
| `ORCA_WORKTREE_ID` | `<repoId>::<worktree のパス>`。セレクタは `id:` を前に付ける |
| `ORCA_TAB_ID` | ペインが乗っているタブ |

**分割で作ったペインは、`ORCA_WORKTREE_ID` を分割元（オーケストレーター）から引き継ぐ。** そのペインで別の worktree に `cd` しても変わらない。`ORCA_TERMINAL_HANDLE` は新しいペイン自身のもの。

## コマンドの群（agent-context の件数）

| 群 | 件数 | 何をするか |
|---|---|---|
| `terminal` | 10 | ペインの作成・分割・送信・読み取り・待ち・閉じる（下に詳しく） |
| `worktree` | 7 | Orca が管理する worktree の作成・一覧・メタデータ（コメント・状態・未読の印・Issue/PR の紐付け）・削除・`ps`（全 worktree の要約） |
| `repo` | 6 | Orca へのリポジトリの登録・既定の base ref・外部の worktree を見せるか |
| `orchestration` | 30 | Orca 自身の監督付きオーケストレーション（Run・Task・Dispatch・メールボックス・判断ゲート・worker の開始/停止/解放） |
| `file` | 3 | ファイル・差分・変更したファイルを Orca のタブで開く |
| ブラウザ（`tab`・`snapshot`・`click`・`fill`・`goto`・`eval`・`screenshot` など） | 約 60 | Orca に内蔵のブラウザの自動操作（アクセシビリティのツリーの ref で指す） |
| `computer` | 14 | ほかのアプリの GUI の操作（Computer Use） |
| `emulator` | 16 | iOS Simulator・Android の操作 |
| `linear` | 27 | Linear のチケットの読み書き |
| `automations` | 7 | 定期実行（cron 的）の作成・実行・履歴 |
| `skills` | 6 | Orca に同梱の skill の一覧・取得・インストール・共有 |
| `artifacts` | 5 | HTML/Markdown の公開リンク（公開はアプリの設定で人が許可したときだけ） |
| `project`・`host`・`environment`・`serve`・`vm` | — | リモートの Orca ランタイム・ホストへの配置 |
| `account`・`agent hooks`・`search`・`diagnostics`・`claude-teams` | — | エージェントのアカウント・hook・会話の全文検索・診断・Claude Code の Agent Teams の起動 |

## ターミナル（ペイン）の操作

```bash
orca terminal list   [--worktree <selector>] [--include-visual-layouts] --json
orca terminal show   --terminal <handle> --json              # メタデータと末尾 1 行の preview
orca terminal read   --terminal <handle> [--limit <行数>] [--cursor <n>] [--json]
orca terminal send   --terminal <handle> --text "<文字>" --enter [--wait-submit <秒>] --json
orca terminal wait   --terminal <handle> --for exit|tui-idle --timeout-ms <ms> --json
orca terminal create [--worktree <selector>] [--title <名前>] [--command "<cmd>"] --json   # 新しいタブ
orca terminal split  --terminal <handle> --direction horizontal|vertical [--command "<cmd>"] --json
orca terminal rename --terminal <handle> --title "<名前>" --json
orca terminal close  --terminal <handle> [--tab] --json
```

確かめたこと:

- **`split` の向き:** `horizontal` は左右、`vertical` は上下に分ける（help の記述。新しいペインがどちら側に出るかは画面で見ていない）。cmux の `right` / `down` に当たる
- **`split --json` の出力:** `result.split.handle` に新しいペインの `term_…`。ほかに `tabId`・`leafId`
- **`split --command`:** シェルの起動の後に、そのコマンドを打ち込む形で回る。コマンドが終わってもペインはシェルとして残る（cmux の `send` ＋ `Enter` と同じ結果を 1 回で出せる）
- **`send --enter`:** 改行まで送る（cmux のように `send-key Enter` を別に送らなくてよい）。シェルに送ると `warnings` に「この provider は届いたかを報告できない」と出るが、届いている。Claude Code のような TUI には `--wait-submit <秒>` で、入力がターンとして始まったかまで確かめられる（help の記述）
- **`read`（--json なし）:** 先頭に `handle:`・`status:`・`cursor:` などの見出しと（切り詰めたときは）`warning:` の行、空行の後に本文が出る。`--json` では `result.terminal.tail` が行の配列
- **`read` は画面そのものではなく、出力の流れの末尾を返す。** `clear` の前の行も混ざって返った。`watch-permissions.sh` は偽の確認の画面（`Do you want to proceed?` ＋ `❯ 1. Yes` を printf で出した）を見つけ、消した後に「解消」も出した。ただし本物の Claude Code の TUI の確認の画面では、まだ回していない
- **`rename` はタブの名前を変える。** 分割したペインはタブを共有するので、ペインごとの名前にならない（付けた名前が別のペインの欄に出た）。ペインは `launch-panes.sh` の出力の対応表（呼び名 → ハンドル）で見分ける
- **`close`:** 分割したペインを 1 つずつ閉じられる。`--tab` を付けるとタブごと

help・手引きにある注意:

- `--terminal` を省くと、今の worktree の「アクティブな」ターミナルが対象になる。並行の作業では必ずハンドルを渡す
- ハンドルはランタイムごと。Orca を再起動した後や `terminal_handle_stale` のエラーの後は `terminal list` で取り直し、古いハンドルには送らない
- Claude Code などの TUI の起動直後に送ると入力が消える。起動を待つなら `terminal wait --for tui-idle --timeout-ms <ms>` の `wait.satisfied` が `true` になってから送る（時間切れでも普通の結果が返るので、`satisfied` を見る）
- 長い出力は `--cursor` で頁をめくる（`limited` が true の間、`nextCursor` を渡す）

## cmux との対応

| やりたいこと | cmux | Orca |
|---|---|---|
| 自分のペイン | `cmux identify` の `caller.surface_ref` | `$ORCA_TERMINAL_HANDLE` |
| 右に分割 | `cmux new-split right --surface <s> --focus false` | `orca terminal split --terminal <h> --direction horizontal --json` |
| 下に分割 | `cmux new-split down --surface <s>` | `orca terminal split --terminal <h> --direction vertical --json` |
| ペインの名前 | `cmux rename-tab --surface <s> <名前>` | 無い（`terminal rename` はタブの名前） |
| 文字を送る | `cmux send --surface <s> <文字>` ＋ `cmux send-key --surface <s> Enter` | `orca terminal send --terminal <h> --text <文字> --enter` |
| 画面を読む | `cmux read-screen --surface <s> --lines <n>` | `orca terminal read --terminal <h> --limit <n>` |
| ユーザーへの通知 | `cmux notify --title … --body …` | 通知のコマンドは無い。`orca worktree set --worktree id:<ORCA_WORKTREE_ID> --comment "<文>" --unread`（サイドバーのカードにコメントと未読の印） |
| 閉じる | `cmux close-surface --surface <s>` | `orca terminal close --terminal <h>` |
| TUI が落ち着くまで待つ | 無い（画面を読んで見る） | `orca terminal wait --for tui-idle` |

この skill のスクリプトは、この対応を `scripts/mux.sh` に閉じ込めている。

## worktree とカードの状態

```bash
orca worktree create --name <名前> [--repo path:<root>] [--base-branch origin/main] [--no-parent] \
  [--agent claude --prompt "<指示>"] [--setup run|skip|inherit] --json
orca worktree set --worktree <selector> [--comment "<文>"] [--workspace-status todo|in-progress|in-review|completed] [--unread|--read] [--issue <番号>] [--pr <番号>]
orca worktree ps --json          # 全 worktree の要約（ターミナルの数・未読・preview）
```

- `worktree create` は Orca が管理する worktree を作る。置き場と名前は Orca が決めるので、この skill の `config.yml` の `worktree.dir` の命名には合わない。この skill は `git worktree add` で作る（Orca の外の worktree は `orca repo set --repo <sel> --external-worktree-visibility show` でサイドバーに出せる）
- `--agent` を付けると、新しい worktree の最初のタブでエージェントが起動する（ペインの分割ではなく、別の worktree のカードになる）
- `--comment` と `--workspace-status` はサイドバーのカードに出る。進み具合の 1 行・人の注意を引く `--unread` に使える

## Orca 自身のオーケストレーション（`orca orchestration`）

Orca には、監督付きで worker を回す仕組みが別にある（同梱の skill `orchestration`）。

```bash
orca orchestration run-create --objective "<目的>" --json
orca orchestration worker-start --spec "<自己完結した指示>" --worktree current|new-child|new-top-level \
  --agent claude [--model <id>] [--effort <level>] [--base-branch <ref>] --json
orca orchestration check --wait --types "worker_done,escalation,question" --timeout-ms 900000 --json
orca orchestration reply --id <message_id> --body "<答え>" --json
orca orchestration worker-release --dispatch <dispatch_id> --json
```

- worker は起動時に Task・Dispatch の ID の入った前置きを受け取り、`orchestration ask` で質問し、`worker_done` を 1 回送って止まる。完了の判定は前置きの ID に基づく
- この skill（orchestrate）との違い: こちらはステータスファイル・指示書・ロック・オーケストレーターのレビュー・動作確認・explainer・マージの順の待ち合わせまでを持つ。Orca の仕組みは、メールボックスと完了の判定が堅い代わりに、その流れは持たない
- 組み合わせる案（未検証）: worker の起動と完了の通知を `worker-start` / `check --wait` に任せ、計画・レビュー・収束はこの skill の手順で行う。試すなら一度小さく回してから

## 確かめていないこと

- `orca worktree set --unread` の通知が、ユーザーにどう見えるか（サイドバーの印だけか、OS の通知も出るか）
- ワーカーの Claude Code が許可の確認で止まったときに、`terminal show` の `agentWait` が何を返すか（今は画面の文字で見つけている）
- `split` で新しいペインにフォーカスが移るか（cmux の `--focus false` に当たる指定は無い）
