#!/usr/bin/env bash
# Removes everything install.sh added (uses the manifest), restores settings and CLAUDE.local.md.
# Usage: ./uninstall.sh [path/to/repo]
set -euo pipefail

TARGET="$(cd "${1:-$PWD}" && git rev-parse --show-toplevel)" || { echo "✗ not inside a git repo"; exit 1; }
STATE="$TARGET/.claude/.kit-state"
MANIFEST="$STATE/manifest"
[ -f "$MANIFEST" ] || { echo "✗ kit not installed here (no manifest)"; exit 1; }

while IFS= read -r rel; do
  [ -n "$rel" ] && rm -rf "${TARGET:?}/$rel"
done <"$MANIFEST"

if [ -f "$STATE/settings.local.json.backup" ]; then
  cp "$STATE/settings.local.json.backup" "$TARGET/.claude/settings.local.json"
fi

if [ -f "$TARGET/CLAUDE.local.md" ]; then
  sed -i '' '/<!-- interview-kit:start -->/,/<!-- interview-kit:end -->/d' "$TARGET/CLAUDE.local.md"
  [ -s "$TARGET/CLAUDE.local.md" ] || rm -f "$TARGET/CLAUDE.local.md"
fi

EXCLUDE="$(git -C "$TARGET" rev-parse --git-path info/exclude)"
case "$EXCLUDE" in /*) ;; *) EXCLUDE="$TARGET/$EXCLUDE" ;; esac
[ -f "$EXCLUDE" ] && sed -i '' '/# interview-kit:start/,/# interview-kit:end/d' "$EXCLUDE"

rm -rf "$STATE" "$TARGET/.claude/STACK.md"
rmdir "$TARGET/.claude/skills" "$TARGET/.claude/agents" "$TARGET/.claude/hooks" "$TARGET/.claude" 2>/dev/null || true
echo "✓ Interview kit removed from $TARGET"
