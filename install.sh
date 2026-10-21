#!/usr/bin/env bash
# Installs the interview kit into a target git repo without polluting its history:
# - copies skills/agents/hooks into <repo>/.claude (never overwrites existing items)
# - merges hooks/permissions into .claude/settings.local.json (personal, not shared)
# - adds the CLAUDE.local.md rules
# - hides everything via .git/info/exclude (local-only ignore, nothing to commit)
# Usage: ./install.sh [path/to/repo]   (default: current directory)
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kit"
TARGET="$(cd "${1:-$PWD}" && git rev-parse --show-toplevel)" || { echo "✗ not inside a git repo"; exit 1; }
STATE="$TARGET/.claude/.kit-state"
MANIFEST="$STATE/manifest"

command -v jq >/dev/null || { echo "✗ jq is required"; exit 1; }
if [ -f "$MANIFEST" ]; then echo "✓ kit already installed in $TARGET (run uninstall.sh first to reinstall)"; exit 0; fi

mkdir -p "$TARGET/.claude/skills" "$TARGET/.claude/agents" "$TARGET/.claude/hooks" "$STATE"
: >"$MANIFEST"

copy_items() { # <src dir> <dst dir>
  for item in "$1"/*; do
    local name dst
    name=$(basename "$item"); dst="$2/$name"
    if [ -e "$dst" ]; then
      echo "  • skipped (repo already has it): ${dst#"$TARGET"/}"
    else
      cp -R "$item" "$dst"
      echo "${dst#"$TARGET"/}" >>"$MANIFEST"
    fi
  done
}
echo "→ skills / agents / hooks"
copy_items "$KIT/.claude/skills" "$TARGET/.claude/skills"
copy_items "$KIT/.claude/agents" "$TARGET/.claude/agents"
copy_items "$KIT/.claude/hooks" "$TARGET/.claude/hooks"
chmod +x "$TARGET"/.claude/hooks/*.sh "$TARGET"/.claude/skills/kit-recon/detect.sh 2>/dev/null || true

echo "→ settings.local.json"
SETTINGS="$TARGET/.claude/settings.local.json"
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$STATE/settings.local.json.backup"
  jq -s '
    .[0] as $a | .[1] as $k
    | ($a * $k)
    | .permissions.allow = ((($a.permissions.allow // []) + ($k.permissions.allow // [])) | unique)
    | .hooks = (reduce ((($a.hooks // {}) | to_entries[]), (($k.hooks // {}) | to_entries[])) as $e ({}; .[$e.key] += $e.value))
  ' "$STATE/settings.local.json.backup" "$KIT/.claude/settings.local.json" >"$SETTINGS"
  echo "  • merged into existing file (backup in .claude/.kit-state)"
else
  cp "$KIT/.claude/settings.local.json" "$SETTINGS"
  echo ".claude/settings.local.json" >>"$MANIFEST"
fi

echo "→ CLAUDE.local.md"
if [ -f "$TARGET/CLAUDE.local.md" ]; then
  { echo; cat "$KIT/CLAUDE.local.md"; } >>"$TARGET/CLAUDE.local.md"
  echo "  • appended to existing file"
else
  cp "$KIT/CLAUDE.local.md" "$TARGET/CLAUDE.local.md"
  echo "CLAUDE.local.md" >>"$MANIFEST"
fi

echo "→ .git/info/exclude"
EXCLUDE="$(git -C "$TARGET" rev-parse --git-path info/exclude)"
case "$EXCLUDE" in /*) ;; *) EXCLUDE="$TARGET/$EXCLUDE" ;; esac
mkdir -p "$(dirname "$EXCLUDE")"
{
  echo "# interview-kit:start"
  sed 's|^|/|' "$MANIFEST"
  echo "/.claude/settings.local.json"
  echo "/.claude/.kit-state/"
  echo "/.kit/"
  echo "/CLAUDE.local.md"
  echo "# interview-kit:end"
} >>"$EXCLUDE"

echo
echo "✓ Interview kit installed in $TARGET"
echo "  Next: open Claude Code in the repo (or /clear) and ask: \"run kit-recon\""
echo "  Check: git status should show nothing new from the kit."
