# CLAUDE.md

Claude Code 用の自作スキルを置くリポジトリ。

## 構成

- スキルは `skills/<名前>/SKILL.md` に置く。テンプレートなどの付属ファイルは同じディレクトリに入れる
- `<名前>` は SKILL.md の frontmatter の `name` と揃える
- `install.sh` は `skills/*/SKILL.md` を自動で拾うので、スキルを足すときに触る必要はない
- 保存先（`.scratch/`）の決め方は、スキルを 1 つずつ入れても読めるよう各 SKILL.md に重ねて書いてある。変えるときは全スキルと README の「保存先」をそろえる
- スキルどうしは、ほかのスキルが書いたファイルを次の目印で読み分ける。目印を変えるときは、読む側の SKILL.md もそろえる
  - レビューボードの見出し（`レビュー: <ブランチ> — <一言>`）とヘッダーの base・コミットのハッシュ: review-triage（2-1・3-3）と scratch-cleanup（3-2）
  - sounding-board のボードの完了バナー（`<header>` 内のコメントの外にある `<div class="done">`）: sounding-board（1-4）・review-triage（3-3）・scratch-cleanup（3-3）
  - 説明資料のファイル名（`*-explainer.html`・`*-explainer-<連番>.html`）と、完了バナーの CSS 定義（`.done{`。sounding-board のボードは持ち、説明資料は持たない）: scratch-cleanup（3-1）。explainer は `.done` というクラスを使わない

## スキルを足す・消す・改名するとき

- `README.md` のスキル一覧を更新する。外部のスキルやプラグインを前提にするなら「前提とする外部スキル」にも追記する
- 変更後に `./install.sh` を再実行する（新しいスキルのリンクを張り、消したスキルのリンク切れを掃除する）

## 依存してよいもの

mattpocock のスキル（mattpocock/skills）には依存しない。外部に頼るなら Claude Code の公式プラグイン・組み込み機能か、このリポジトリ内のスキルにする。

## 書かないこと

業務固有の記述（社内のチケット接頭辞・プロジェクト名・社内システム名など）や個人の絶対パスを入れない。例が必要なら `PROJ-123`・`42` のような一般的なものを使う。
