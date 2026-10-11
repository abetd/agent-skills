# agent-skills

Claude Code 用の自作スキル集です。スキル本体（SKILL.md）は日本語で書かれています。

## スキル一覧

| スキル | 概要 |
|---|---|
| [sounding-board](skills/sounding-board/SKILL.md) | 壁打ちの相手になり、問いを出してラウンドを回しながら、決定事項と未解決の問いを HTML のボードに残す |
| [review-triage](skills/review-triage/SKILL.md) | 外部のレビューと、sounding-board のボード・プランファイルを仕様にした自前の仕様チェックを束ねて実行し、指摘を must / want / nits に仕分けた HTML ボードで対応方針を管理する。各指摘をコードに当たって検証して推奨を付け、明示的な修正指示があれば対応する指摘をまとめて修正する |
| [explainer](skills/explainer/SKILL.md) | トピックを、大きな絵と少ない言葉の HTML 説明資料にしてローカル（`.scratch/`）に保存する。「図解して」「わかりやすく説明して」などで起動し、作る前に確認する |
| [scratch-cleanup](skills/scratch-cleanup/SKILL.md) | `.scratch/` の古いファイル（n 日更新が無いもの・マージ済みブランチのレビューボード・新しい版がある説明資料）を一覧にし、外したもの以外を `.scratch/archive/` に移すか削除する |

## 入れ方

### clone して symlink を張る

編集がそのまま反映されます。

```sh
git clone https://github.com/abetd/agent-skills.git
cd agent-skills
./install.sh            # SKILL.md のある skills/<名前>/ を ~/.claude/skills/ に個別にリンク
./install.sh --dry-run  # 実行内容の確認のみ
```

- 同じ名前のものが既にあれば、張る前にスキルごとに置き換えるかを聞きます（`y/N`）。`N` なら置き換えずに飛ばします
  - 実体（ディレクトリ・ファイル）は `~/.claude/skills-backup/<名前>.<日時>` に退避してから張ります（`~/.claude/skills/` の中に残すと、退避したスキルも読み込まれるため）
  - 別の場所を指すリンクは、このリポジトリを指すように張り替えます。リンク先には触りません
  - リンク切れのリンクは、聞かずに張り替えます
  - 端末から実行していない（パイプなど）ときは聞けないので、何も変えずに止まります。`--dry-run` は聞かずに、同じ名前のものを一覧にします
- `~/.claude/skills` ごとこのリポジトリの `skills/` にリンクしているときは、止まります。そのリンクを外してから実行してください
- このリポジトリの中を指すリンクのうち、リンク切れになったもの（消した・改名したスキル）を掃除します。ほかのリンクには触りません

### npx skills add で入れる

[skills](https://github.com/vercel-labs/skills) CLI でコピーして入れることもできます。

```sh
npx skills add abetd/agent-skills
```

## 保存先（`.scratch/`）

sounding-board・review-triage・explainer は、作った HTML をリポジトリルートの `.scratch/` に置きます。ここに置くと別のセッションから続きを書けます（sounding-board の再開、review-triage の再レビュー）。

- `.scratch/` が無ければ、スキルが作るかを聞きます（scratch-cleanup は作らず、片付けるものが無いと告げて終わります）。作らなければ、そのセッションだけの一時ディレクトリ（scratchpad）に置きます。断っても記録しないので、次に起動したときにまた聞きます
- スキルが作るのは実ディレクトリです。ほかの場所への symlink にしてもかまいません
- git リポジトリの外では聞かずに scratchpad に置きます

git で管理するかは自由です。スキルは git の設定に触れません。たとえば:

- **自分だけの作業場にする**: `.scratch` を git に無視させます（`.gitignore` などに足す）
- **チームで共有する**: `.scratch/` をコミットします。設計ボードを残しておけば、ほかの人も review-triage の仕様に使えます

どちらの場合も、review-triage は `.scratch/` の中をレビューの対象にしません。

たまったファイルは scratch-cleanup で片付けられます。アーカイブしたものは `.scratch/archive/` に移り、ほかのスキルからは見えなくなります（直下に戻せば、また見えます。移すときに同じ名前があって連番が付いたものは、元の名前に直して戻します）。削除したものは戻せません。

## 前提とする外部スキル

review-triage は、次のレビュー資産を呼び出します。

| レビュー源 | 入手元 |
|---|---|
| `pr-review-toolkit` プラグイン | Claude Code の公式プラグイン（`/plugin install pr-review-toolkit@claude-plugins-official`） |
| `security-review` | Claude Code 組み込み |

`pr-review-toolkit` が無いときは、review-triage が入れ方を示し、仕様チェックと `security-review` だけで続けるかを聞きます。

explainer は、Artifact 機能が有効な環境では Claude Code 組み込みの `artifact-design` をデザインの指針に使います（公開はしません）。無い環境では同梱のテンプレートで動きます。

sounding-board と scratch-cleanup に外部の前提はありません。
