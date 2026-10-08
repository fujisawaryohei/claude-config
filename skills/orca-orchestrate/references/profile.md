# PJ のプロファイル（初回に走査して作り、ハーネスが変わったら作り直す）

オーケストレーターが、どの PJ でもその PJ のしきたりで判断できるようにするための索引。

## 置き場

```
<置き場>/<PJ 名>/
├── profile.md   人が読む。しきたりの要約（決まり ＋ 出所）
├── config.yml   機械が読む。worktree・検証・共有リソースなどの値（項目は config.md）
└── digest.txt   走査したハーネスのファイルの指紋（scripts/harness-digest.sh digest の出力）
```

`<置き場>` は 2 つ。**既定は git 管理外**（社外秘の PJ の要約が、skill を管理している git に入って外へ出ないように）。

| 置き場 | git | 使うとき |
|---|---|---|
| `~/.claude/orca-orchestrate/profiles/`（既定） | **管理外** | 社外秘の PJ・迷ったとき。`~/.claude` 自体は git ではない（skills などだけが別の git へのリンク） |
| `<この skill>/profiles/` | skill と同じ git で管理 | 公開してよい PJ（OSS・個人の PJ）。ほかのマシンへ持っていける |

- 探す順: リポジトリの `.claude/orca-orchestrate.yml`（`config.yml` の代わり）→ `~/.claude/orca-orchestrate/profiles/<PJ 名>/` → `<この skill>/profiles/<PJ 名>/`
- **新しく作るときは、どちらに置くかをユーザーに聞く。** 答えが無ければ git 管理外に置く。git 管理の側に置くと決めたときも、社外の人が読んでよい中身か（社内の製品名・チケット番号・社内の URL・人の名前）を見せてから保存する
- skill の git に PJ の資料を入れたかもしれないときは、commit・push の前にユーザーに伝える（オーケストレーターから skill の git を commit・push しない）
- PJ 名は **メイン checkout のフォルダ名**（`scripts/harness-digest.sh name`）。worktree から起動しても同じプロファイルを引く

## 原則

- **本文を写さない。** 持つのは「決まり（1 行）＋ 出所（パス:行）」だけ。正本は PJ 側にある。写しは古くなり、どちらが正しいか分からなくなる
- **ワーカーに全部は渡さない。** ワーカーは worktree で起動した Claude Code なので、CLAUDE.md・rules・skills・agents・hooks は自分で読み込む。`common.md` に書くのは、オーケストレーションに関わる決まり（検証の入口・共有リソース・設計書の同期・コミットしない など）だけ
- **分からないものは「未確認」と書く。** リポジトリの外の決まり（ブランチの保護・口頭の運用）は走査で拾えない。計画のときに聞く
- 秘密値のファイル（`.env` など）は読まない

## 走査の手順（Phase 0）

1. `bash scripts/harness-digest.sh name` で PJ 名を出し、`profiles/<PJ 名>/` を見る
2. **プロファイルがある:** `bash scripts/harness-digest.sh diff profiles/<PJ 名>/digest.txt`
   - 差が無い → そのまま使う
   - 差がある → 変わったファイルだけを読み直し、該当の観点を直す（全部を作り直さない）
3. **プロファイルが無い:** Explore 系のサブエージェントに、下の「読むもの」と「観点」を渡して走査させる（オーケストレーターのコンテキストを汚さないため）
4. 結果を下の雛形の `profile.md` と、[config.md](config.md) の `config.yml` にまとめる。**保存の前にユーザーに見せて確かめる**（間違った決まりで並べると、被害がセッションの数だけ増える）
5. 保存したら `bash scripts/harness-digest.sh digest > profiles/<PJ 名>/digest.txt`

### 読むもの

- `CLAUDE.md`（ルート・各パッケージ）・`AGENTS.md`
- `.claude/rules/**`（frontmatter の `paths` / glob も。どの範囲で効くかを記録する）
- `.claude/skills/*/SKILL.md`・`.claude/agents/*.md`（名前と description だけ）
- `.claude/settings.json`（hooks・permissions の要点）
- Makefile・package.json の scripts・pyproject.toml
- CI の定義・commitlint・PR のテンプレート・CODEOWNERS
- worktree の設定（`.wtp.yml` など）・docker-compose（プロジェクト名の固定・マウント）
- ユーザーのその PJ のメモリ（`~/.claude/projects/<PJ のパス>/memory/`。feedback と reference を中心に）

## profile.md の雛形

```markdown
# <PJ 名> のプロファイル
- 作った日: <日付> ／ 走査したファイル: <数> 件（digest.txt）
- 正本: この PJ の CLAUDE.md・.claude/rules/。食い違ったら正本に従い、このファイルを直す

## 1. 開発の流れ
- <決まり> ／ <出所>

## 2. 検証
## 3. レビュー（オーケストレーターが使う agent・skill）
## 4. 設計書・ドキュメントの同期
## 5. コミット・PR・ブランチ
## 6. チケット
## 7. 共有リソースと環境
## 8. してはいけないこと
## 9. 作業の種類ごとに使う skill・agent
## 10. 言語・書き方
## 11. CI が強制するもの／ローカルでしか守られないもの
## 12. 未確認（リポジトリの外にある決まり）

## common.md に書き写すもの（オーケストレーションに関わる分だけ）
- <検証の入口・共有リソースのロック・設計書の同期・コミットしない など>
```
