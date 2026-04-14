#!/usr/bin/env bash
# uninstall.sh — Remove kb-genesis skills from Claude Code
#
# Usage:
#   ./uninstall.sh              # Remove from global (~/.claude/skills/)
#   ./uninstall.sh --project    # Remove from project (.claude/skills/)
#   ./uninstall.sh /custom/path # Remove from custom directory

set -euo pipefail

SKILLS=("kb-genesis" "kb-mine-history" "kb-create-hooks")

if [[ "${1:-}" == "--project" ]]; then
  TARGET_DIR="$(pwd)/.claude/skills"
elif [[ -n "${1:-}" ]]; then
  TARGET_DIR="$1"
else
  TARGET_DIR="$HOME/.claude/skills"
fi

echo "Removing kb-genesis skills from $TARGET_DIR"

for skill in "${SKILLS[@]}"; do
  if [[ -L "$TARGET_DIR/$skill" ]] || [[ -d "$TARGET_DIR/$skill" ]]; then
    rm -rf "$TARGET_DIR/$skill"
    echo "  Removed /$skill"
  fi
done

echo ""
echo "Done. You can also delete this repo clone if you no longer need it."
