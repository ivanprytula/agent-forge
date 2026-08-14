#!/usr/bin/env bash
set -euo pipefail

ensure_dir() {
    mkdir -p "$1"
}

link_skill() {
    local skill_name="$1"
    local target_dir="$2"
    local agent_forge="$3"
    local target="$target_dir/$skill_name"

    # -e follows symlinks, so it's false for broken links — good
    if [ -e "$target" ]; then
        echo "  $skill_name already exists, skipping"
        return 0
    fi

    # Remove broken symlink if present (target doesn't exist but is a symlink)
    [ -L "$target" ] && rm "$target"

    ensure_dir "$target_dir"
    local rel
    rel="$(realpath --relative-to="$target_dir" "$agent_forge/skills")"
    ln -s "$rel/$skill_name" "$target"
    echo "  Linked $skill_name"
}

clean_stale_skills() {
    local agent_forge="$1"
    local target_dir="$2"

    for existing in "$target_dir"/*; do
        [ -e "$existing" ] || [ -L "$existing" ] || continue
        local name
        name="$(basename "$existing")"
        if [ ! -d "$agent_forge/skills/$name" ]; then
            rm -rf "$existing"
            echo "  Removed stale skill $name"
        fi
    done
}

refresh_skill() {
    local skill_name="$1"
    local target_dir="$2"
    local agent_forge="$3"
    local target="$target_dir/$skill_name"

    # -L && -e: valid symlink → skip.
    # -L but ! -e: broken symlink → fall through, link_skill will rm it.
    if [ -L "$target" ] && [ -e "$target" ]; then
        echo "  $skill_name already linked, skipping"
        return 0
    fi

    # Real directory (old copy) → remove before re-linking
    if [ -d "$target" ]; then
        rm -rf "$target"
        echo "  Converted $skill_name from copy to symlink"
    fi

    link_skill "$skill_name" "$target_dir" "$agent_forge"
}

refresh_all_skills() {
    local agent_forge="$1"
    local target_dir="$2"

    ensure_dir "$target_dir"
    for skill_dir in "$agent_forge"/skills/*/; do
        refresh_skill "$(basename "$skill_dir")" "$target_dir" "$agent_forge"
    done
    clean_stale_skills "$agent_forge" "$target_dir"
}
