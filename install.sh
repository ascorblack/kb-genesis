#!/usr/bin/env bash
# install.sh — Install kb-genesis skills into Claude Code
#
# Usage:
#   ./install.sh              # Global install (~/.claude/skills/)
#   ./install.sh --project    # Project-local install (.claude/skills/)
#   ./install.sh /custom/path # Custom skills directory

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS=("kb-genesis" "kb-mine-history" "kb-create-hooks")

# Determine target directory
if [[ "${1:-}" == "--project" ]]; then
  TARGET_DIR="$(pwd)/.claude/skills"
elif [[ -n "${1:-}" ]]; then
  TARGET_DIR="$1"
else
  TARGET_DIR="$HOME/.claude/skills"
fi

mkdir -p "$TARGET_DIR"

echo "Installing kb-genesis skills into $TARGET_DIR"
echo ""

for skill in "${SKILLS[@]}"; do
  if [[ -d "$REPO_DIR/$skill" ]]; then
    ln -sfn "$REPO_DIR/$skill" "$TARGET_DIR/$skill"
    echo "  /$skill -> $REPO_DIR/$skill"
  fi
done

echo ""
echo "Done. Available skills:"
echo "  /kb-genesis       — Create a knowledge base for a project"
echo "  /kb-mine-history  — Mine agent conversation histories"
echo "  /kb-create-hooks  — Set up enforcement hooks"
echo ""
echo "Update:    git -C $REPO_DIR pull"
echo "Uninstall: $REPO_DIR/uninstall.sh"
