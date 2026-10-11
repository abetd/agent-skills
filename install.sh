#!/usr/bin/env bash
set -euo pipefail

# skills/ 配下のうち SKILL.md を持つディレクトリを、~/.claude/skills/ に個別 symlink する

# -P: パスの途中にあるディレクトリの symlink を解決して実パスに揃える（リンク先の比較・掃除の前方一致がずれないように）。
# スクリプト自体への symlink は解決しないので、リポジトリ内の install.sh を直接実行する
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SKILLS_TARGET="${HOME}/.claude/skills"
# 退避先は読み込み対象（~/.claude/skills）の外に置く。中に置くと退避したスキルも読み込まれてしまう
BACKUP_DIR="${HOME}/.claude/skills-backup"
BACKUP_SUFFIX=".$(date +%Y%m%d%H%M%S)"
DRY_RUN=false

usage() {
    echo "Usage: $0 [-n|--dry-run] [-h|--help]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

LOG_PREFIX=""
if [[ "$DRY_RUN" == true ]]; then LOG_PREFIX="(dry-run) "; fi

log_info() { echo "[INFO]  ${LOG_PREFIX}$*"; }
log_warn() { echo "[WARN]  ${LOG_PREFIX}$*"; }

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_info "Creating directory: $dir"
        if [[ "$DRY_RUN" == false ]]; then mkdir -p "$dir"; fi
    fi
}

# 置き換えると何かを失うもの（実体と、生きているほかの場所へのリンク）なら、その説明を出して 0 を返す。
# リンク切れと、このリポジトリのスキルを指すリンクは失うものが無いので、衝突にしない
describe_conflict() {
    local src="$1"
    local target="$2"

    if [[ -L "$target" ]]; then
        if [[ ! -e "$target" || "$(readlink "$target")" == "$src" ]]; then return 1; fi
        if [[ -d "$target" && "$(cd "$target" && pwd -P)" == "$src" ]]; then return 1; fi
        echo "a link to $(readlink "$target")"
        return 0
    fi
    if [[ -e "$target" ]]; then
        echo "a real directory or file (it will be moved to ${BACKUP_DIR})"
        return 0
    fi
    return 1
}

make_link() {
    local src="$1"
    local target="$2"

    if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
        log_info "Already linked: $target (skip)"
        return 0
    fi

    # 実体（symlink でないファイル・ディレクトリ）は退避してから張る
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${BACKUP_DIR}/$(basename "$target")${BACKUP_SUFFIX}"
        ensure_dir "$BACKUP_DIR"
        log_warn "Backing up: $target -> $backup"
        if [[ "$DRY_RUN" == false ]]; then mv "$target" "$backup"; fi
    elif [[ -L "$target" ]]; then
        log_warn "Replacing link: $target ($(readlink "$target") -> $src)"
    fi

    log_info "Linking: $target -> $src"
    # -n: ディレクトリを指す既存 symlink を辿らず、symlink 自体を置き換える
    if [[ "$DRY_RUN" == false ]]; then ln -sfn "$src" "$target"; fi
}

if [[ "$DRY_RUN" == true ]]; then log_info "No changes will be made"; fi

# skills/ が無い（symlink 経由で実行して REPO_DIR がずれた等）ときは、何も張らずに下の掃除へ進まないよう止める
if [[ ! -d "${REPO_DIR}/skills" ]]; then
    echo "[ERROR] skills/ not found in ${REPO_DIR}. Run install.sh inside the repository directly." >&2
    exit 1
fi

# 入れる先がこのリポジトリの中（~/.claude/skills ごと skills/ にリンクしている等）なら止める。
# 個別リンクを張ると、実体を退避して自分を指すリンクを作り、掃除でそれを消してしまう
if [[ -d "$SKILLS_TARGET" ]]; then
    target_real="$(cd "$SKILLS_TARGET" && pwd -P)"
    if [[ "$target_real" == "$REPO_DIR" || "$target_real" == "${REPO_DIR}/"* ]]; then
        echo "[ERROR] ${SKILLS_TARGET} resolves into this repository (${target_real}). Remove that link first." >&2
        exit 1
    fi
fi

names=()
for skill_dir in "${REPO_DIR}"/skills/*/; do
    [[ -f "${skill_dir}SKILL.md" ]] || continue
    names+=("$(basename "$skill_dir")")
done

if [[ "${#names[@]}" -eq 0 ]]; then
    echo "[ERROR] No skills found (skills/*/SKILL.md) in ${REPO_DIR}." >&2
    exit 1
fi

# 同じ名前のものを、張る前にまとめて調べる（途中まで置き換えた状態を残さない）
conflict_names=()
conflict_descs=()
for name in "${names[@]}"; do
    if desc="$(describe_conflict "${REPO_DIR}/skills/${name}" "${SKILLS_TARGET}/${name}")"; then
        conflict_names+=("$name")
        conflict_descs+=("$desc")
    fi
done

# 置き換えないと答えたスキル（空白区切り。名前は skills/ のディレクトリ名なので空白を含まない）
skipped=" "
if [[ "${#conflict_names[@]}" -gt 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        for i in "${!conflict_names[@]}"; do
            log_warn "Conflict: ${SKILLS_TARGET}/${conflict_names[$i]} is ${conflict_descs[$i]}. Will ask before replacing."
        done
    elif [[ ! -t 0 ]]; then
        echo "[ERROR] These skills already exist and cannot be confirmed without a terminal. Nothing was changed:" >&2
        for i in "${!conflict_names[@]}"; do
            echo "  ${SKILLS_TARGET}/${conflict_names[$i]} is ${conflict_descs[$i]}" >&2
        done
        exit 1
    else
        for i in "${!conflict_names[@]}"; do
            # 入力の終わり（Ctrl-D）は N として扱う
            read -r -p "${SKILLS_TARGET}/${conflict_names[$i]} is ${conflict_descs[$i]}. Replace it? [y/N] " answer || answer=""
            if [[ ! "$answer" =~ ^[yY]([eE][sS])?$ ]]; then skipped+="${conflict_names[$i]} "; fi
        done
    fi
fi

ensure_dir "$SKILLS_TARGET"

for name in "${names[@]}"; do
    if [[ "$skipped" == *" ${name} "* ]]; then continue; fi
    make_link "${REPO_DIR}/skills/${name}" "${SKILLS_TARGET}/${name}"
done

# リンク切れの掃除（このリポジトリ（REPO_DIR）の中を指す symlink のみ。ほかのリンクには触らない）
for entry in "${SKILLS_TARGET}"/*; do
    if [[ -L "$entry" && ! -e "$entry" && "$(readlink "$entry")" == "${REPO_DIR}/"* ]]; then
        log_warn "Removing dangling symlink: $entry"
        if [[ "$DRY_RUN" == false ]]; then rm "$entry"; fi
    fi
done

if [[ "$skipped" != " " ]]; then log_info "Skipped (left as is):${skipped% }"; fi
log_info "Done."
