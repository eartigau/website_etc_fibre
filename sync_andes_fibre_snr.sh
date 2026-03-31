#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="/Users/eartigau/GitHubProjects/website_etc_fibre"
PAGE_REPO="/Users/eartigau/GitHubProjects/page_perso"
TARGET_SUBDIR="tools/andes_fibre_snr"
TARGET_DIR="$PAGE_REPO/$TARGET_SUBDIR"
PUBLIC_PROMPTS_DIR="$TARGET_DIR/prompts"

PAGE_COMMIT_MESSAGE="Update Andes fibre SNR tool"
SOURCE_COMMIT_MESSAGE="Update Andes fibre SNR workspace"

COPY_ONLY=0
SKIP_PUSH=0

usage() {
  cat <<'EOF'
Usage: ./sync_andes_fibre_snr.sh [--copy-only] [--skip-push]

Actions:
  1. Copy/update the hosted tool into page_perso/tools/andes_fibre_snr
  2. Commit and push only that hosted tool path in the personal-page repo
  3. Commit and push the workspace repo

Options:
  --copy-only   Only refresh the hosted copy, do not commit or push either repo
  --skip-push   Commit locally but do not push either repo
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy-only)
      COPY_ONLY=1
      ;;
    --skip-push)
      SKIP_PUSH=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

require_repo() {
  local repo_path="$1"
  if [[ ! -d "$repo_path/.git" ]]; then
    echo "Expected git repository at $repo_path" >&2
    exit 1
  fi
}

copy_tool() {
  echo "[1/3] Copying tool into $TARGET_DIR"
  mkdir -p "$TARGET_DIR" "$PUBLIC_PROMPTS_DIR"

  rsync -a --delete \
    --exclude '.git/' \
    --exclude '.github/' \
    --exclude '.nojekyll' \
    --exclude '.DS_Store' \
    --exclude 'sync_andes_fibre_snr.sh' \
    "$SOURCE_DIR/" "$TARGET_DIR/"

  if [[ -d "$SOURCE_DIR/.github/prompts" ]]; then
    rsync -a --delete \
      --exclude '.DS_Store' \
      "$SOURCE_DIR/.github/prompts/" "$PUBLIC_PROMPTS_DIR/"
  fi
}

commit_if_needed() {
  local repo_path="$1"
  local commit_message="$2"
  shift 2

  git -C "$repo_path" add -- "$@"
  if git -C "$repo_path" diff --cached --quiet -- "$@"; then
    echo "No staged changes for $repo_path"
    return
  fi

  git -C "$repo_path" commit -m "$commit_message"
  if [[ "$SKIP_PUSH" -eq 0 ]]; then
    git -C "$repo_path" push
  fi
}

sync_page_repo() {
  echo "[2/3] Syncing personal-page repo path $TARGET_SUBDIR"
  commit_if_needed "$PAGE_REPO" "$PAGE_COMMIT_MESSAGE" "$TARGET_SUBDIR"
}

sync_source_repo() {
  echo "[3/3] Syncing workspace repo"
  git -C "$SOURCE_DIR" add -A
  if git -C "$SOURCE_DIR" diff --cached --quiet; then
    echo "No staged changes for $SOURCE_DIR"
    return
  fi

  git -C "$SOURCE_DIR" commit -m "$SOURCE_COMMIT_MESSAGE"
  if [[ "$SKIP_PUSH" -eq 0 ]]; then
    git -C "$SOURCE_DIR" push
  fi
}

require_repo "$SOURCE_DIR"
require_repo "$PAGE_REPO"
copy_tool

if [[ "$COPY_ONLY" -eq 1 ]]; then
  echo "Copy completed. Skipping repository sync steps."
  exit 0
fi

sync_page_repo
sync_source_repo