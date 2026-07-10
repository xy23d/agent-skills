#!/bin/bash
# Usage: pr-create.sh <worktree_path> <title> <body_file> [base]
set -e

WORKTREE_PATH="$1"
TITLE="$2"
BODY_FILE="$3"
BASE="$4"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
OWNER_ACCOUNT_MAP="$SKILL_DIR/owner-account-map"

if [ -z "$WORKTREE_PATH" ] || [ -z "$TITLE" ] || [ -z "$BODY_FILE" ]; then
  echo "Usage: pr-create.sh <worktree_path> <title> <body_file> [base]" >&2
  exit 1
fi

if [ ! -d "$WORKTREE_PATH" ]; then
  echo "worktree_path が存在しません: $WORKTREE_PATH" >&2
  exit 1
fi

if [ ! -f "$BODY_FILE" ]; then
  echo "body_file が存在しません: $BODY_FILE" >&2
  exit 1
fi

BRANCH=$(git -C "$WORKTREE_PATH" symbolic-ref --short -q HEAD)
if [ -z "$BRANCH" ]; then
  echo "detached HEAD では PR を作成できません" >&2
  exit 1
fi

REMOTE_URL=$(git -C "$WORKTREE_PATH" remote get-url origin)
OWNER_REPO=""

if [[ "$REMOTE_URL" =~ ^git@[^:]+:([^/]+)/(.+)(\.git)?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  REPO="${REPO%.git}"
  OWNER_REPO="$OWNER/$REPO"
elif [[ "$REMOTE_URL" =~ ^https?://[^/]+/([^/]+)/(.+)(\.git)?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  REPO="${REPO%.git}"
  OWNER_REPO="$OWNER/$REPO"
fi

if [ -z "$OWNER_REPO" ]; then
  echo "origin の owner/repo を解決できませんでした: $REMOTE_URL" >&2
  exit 1
fi

TARGET_ACCOUNT=""
if [ -f "$OWNER_ACCOUNT_MAP" ]; then
  TARGET_ACCOUNT=$(awk -v owner="$OWNER" '
    NF && $1 !~ /^#/ && $1 == owner { print $2; exit }
  ' "$OWNER_ACCOUNT_MAP")
fi

if [ -n "$TARGET_ACCOUNT" ]; then
  PREV_ACCOUNT=$(gh api user --jq .login 2>/dev/null || true)
  if [ -z "$PREV_ACCOUNT" ]; then
    echo "warning: owner '$OWNER' maps to gh account '$TARGET_ACCOUNT', but current gh account could not be detected; continuing with current gh auth" >&2
  elif [ "$TARGET_ACCOUNT" != "$PREV_ACCOUNT" ]; then
    if gh auth switch --user "$TARGET_ACCOUNT" >/dev/null 2>&1; then
      trap 'gh auth switch --user "$PREV_ACCOUNT" >/dev/null 2>&1 || true' EXIT
    else
      echo "warning: owner '$OWNER' maps to gh account '$TARGET_ACCOUNT', but switching failed; continuing with current gh auth" >&2
    fi
  fi
fi

MERGED_PR_NUMBERS=$(gh pr list --repo "$OWNER_REPO" --head "$BRANCH" --state merged --json number --jq '.[].number' 2>/dev/null || true)
if [ -n "$MERGED_PR_NUMBERS" ]; then
  MERGED_PR_LIST=$(printf '%s\n' "$MERGED_PR_NUMBERS" | awk '{ printf "%s#%s", sep, $1; sep=", " }')
  echo "warning: branch '$BRANCH' already has merged PR(s) $MERGED_PR_LIST in $OWNER_REPO. Confirm this is not adding commits to a merged branch; normally additional changes should be opened from a new branch." >&2
fi

git -C "$WORKTREE_PATH" push -u origin "$BRANCH"

ARGS=(
  pr create
  --draft
  --repo "$OWNER_REPO"
  --head "$BRANCH"
  --title "$TITLE"
  --body-file "$BODY_FILE"
)

if [ -n "$BASE" ]; then
  ARGS+=(--base "$BASE")
fi

gh "${ARGS[@]}"
