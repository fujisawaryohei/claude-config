# 詰まった点（実運用で足していく）

## 初期設定が黙って失敗する（2026-10-09）

- 症状: worktree の初期設定スクリプトが ✅ の一覧を出した直後に `s�: unbound variable` で落ちる。一覧から必須のステップ（`uv sync`）が抜けていたが、失敗の行は出ていなかった
- 原因は 2 つ重なっていた
  - ホストの uv が asdf の python の shim で、python の版が無いディレクトリでは `No version is set for command uv` で動かない（メイン checkout でも同じ）
  - スクリプトの結果の表示の行が、bash 3.2 ＋ `set -u` ＋ `$s（…` のように変数の直後に全角文字がある書き方で落ち、失敗の一覧を出す前に終わる
- 対処: 表示を信じず、`must_exist` の成果物を自分で確かめる。uv は `ASDF_PYTHON_VERSION=<版>` を付けて回す
- 同じ理由で、**`python3` も版の無いディレクトリでは動かない。** skill のスクリプトでは python に頼らず、awk・sed で済ませる

## 共有のコンテナを取り合う

- docker compose のプロジェクト名が固定だと、どの worktree から叩いても 1 組のコンテナを使う。並行に検証すると、別の worktree のコードを検証してしまう
- 対処: `with-lock.sh` で 1 本ずつ・作り直し・マウント元の確認
- `--force-recreate` は依存のコンテナ（postgres）まで作り直して遅い。依存は `up -d` だけ、対象は `--no-deps --force-recreate`
- ユーザーの起動中の開発サーバ（例: `make dev-fast`）のコンテナも付け替わる。始める前に伝え、戻し方を最後に伝える

## cmux

- `cmux new-split` の出力は `OK surface:18 workspace:1`。surface の ref は 2 つ目の語だけを取り出す（丸ごと渡すと `Invalid surface handle`）
- `cmux send` は改行を送らない。続けて `cmux send-key --surface <s> Enter`
- ワーカーは起動直後に権限の設定の警告を大量に出すことがある。`read-screen --lines 60` に `grep -v '^Permission'` をかけて本文を見る
- ワーカーは manual モードで起動するので、許可の確認はユーザーが各ペインで応える

## Orca（2026-10-09・Orca 1.4.222）

- `orca terminal rename` はペインではなくタブの名前を変える。分割したペインはタブを共有するので、付けた名前が別のペインの欄に出る。ペインは `launch-panes.sh` の出力の対応表で見分ける（`mux.sh rename` は Orca では何もしない）
- 通知のコマンドが無い。`notify.sh` は、オーケストレーターの worktree のカードにコメントを書いて未読の印を付ける。分割したペインは分割元の `ORCA_WORKTREE_ID` を引き継ぐので、ワーカーが別の worktree に `cd` していても、印はオーケストレーターのカードに付く
- `terminal send` をシェルに送ると「届いたかを報告できない」の警告が出るが、届いている。再送しない
- コマンドの詳細と cmux との対応は [orca-cli.md](orca-cli.md)

## cmux の Feed にカードが届かない（2026-10-09）

- cmux の Claude の wrapper は、Claude Code の `PermissionRequest` の hook に `cmux hooks feed --source claude` を入れる（ワーカーの `claude` のプロセスの引数で確かめられる）。届けば `cmux feed tui` に許可のカードが出て、120 秒待つ。届かなければ、すぐワーカーのペインのいつもの確認に戻る
- 実際には、hook が入っていてもカードが 0 件のままで、ペインの確認がすぐ出た（届いていない）
- 手当ての候補は `cmux hooks setup --agent claude-code`（cmux の設定を書き換えるので、ユーザーが回す）。起動済みのワーカーには効かない見込み（hook は起動時に渡る）
- 代わり: `scripts/watch-permissions.sh` でペインの確認を見つけ、オーケストレーターが推奨を出す。**キーは送らない**（Feed の答えのうち Bypass は、そのセッションの確認を全部飛ばすので選ばない）

## シェル

- 監視のスクリプトを zsh で回すと、一致の無い glob（`status/*.md` がまだ無い）でエラーになって落ちる。`bash -c` ＋ `shopt -s nullglob` で回す
- zsh では `echo ===` が `=` の展開（`=cmd`）でエラーになる。区切りの線は `-----` や `#####` にする

## 外部の素材

- Storage Account のネットワークの規則で、手元から Blob を取れないことがある。規則は変えず、手元に同じ版がないか探す（`mdfind -name`）。版の同一性は大きさ・ハッシュ・中身の数（枚数など）で確かめる

## レビューをワーカーに任せた

- 最初は「各セッションで自分の差分をレビューしてから完了にする」形にしたが、オーケストレーターが外から見た方が拾えるものが多かった（ある回では、ワーカーの「この作業は不要」・設計書の「対処済み」の言い切り・「失敗したときに止まった段の時間が記録から抜ける」の 3 つが、どれも外から見て見つかった）
- 対処: レビューはオーケストレーターが行い、ワーカーは「レビュー待ち」で止まる形に変えた（Phase 6）

## 計画の見落とし

- 2 本が同じ設計書の節を書き換える重なりを、起動の後に気づいた（ある回で、2 本が同じ「既知のリスク」の節を書き換えようとしていた）。overlap-checklist の「同じ設計書の節」を、起動の前に必ず見る
