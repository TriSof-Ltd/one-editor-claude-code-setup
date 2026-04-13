#!/bin/bash
# Install One Editor Claude Code setup into a project directory
# Usage: ./install.sh /path/to/project

set -e

SETUP_VERSION="1.0.0"

# Resolve script directory so we can use it regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR does not exist"
  exit 1
fi

echo "[setup] Installing Claude Code config into $PROJECT_DIR"

# Copy .claude directory (skills, agents, rules, hooks)
# Note: b44-* skills/agents are excluded — they're only installed for Base44 imports
mkdir -p "$PROJECT_DIR/.claude"
for dir in rules hooks; do
  if [ -d "$SCRIPT_DIR/.claude/$dir" ]; then
    cp -r "$SCRIPT_DIR/.claude/$dir" "$PROJECT_DIR/.claude/"
  else
    echo "[setup] Warning: $SCRIPT_DIR/.claude/$dir not found, skipping"
  fi
done
# Copy skills excluding b44-* (Base44 import skills)
if [ -d "$SCRIPT_DIR/.claude/skills" ]; then
  mkdir -p "$PROJECT_DIR/.claude/skills"
  for skill_dir in "$SCRIPT_DIR/.claude/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    case "$skill_name" in
      b44-*) ;; # Skip Base44 import skills
      *) cp -r "$skill_dir" "$PROJECT_DIR/.claude/skills/" ;;
    esac
  done
fi
# Copy agents excluding b44-* (Base44 import agents)
if [ -d "$SCRIPT_DIR/.claude/agents" ]; then
  mkdir -p "$PROJECT_DIR/.claude/agents"
  for agent_file in "$SCRIPT_DIR/.claude/agents"/*.md; do
    agent_name="$(basename "$agent_file")"
    case "$agent_name" in
      b44-*) ;; # Skip Base44 import agents
      *) cp "$agent_file" "$PROJECT_DIR/.claude/agents/" ;;
    esac
  done
fi
chmod +x "$PROJECT_DIR/.claude/hooks/"*.sh 2>/dev/null || true

# Always deploy settings.local.json (source of truth)
if [ -f "$SCRIPT_DIR/.claude/settings.local.json" ]; then
  cp "$SCRIPT_DIR/.claude/settings.local.json" "$PROJECT_DIR/.claude/settings.local.json"
  echo "[setup] settings.local.json updated"
fi

# Copy .mcp.json (always update to latest)
if [ -f "$SCRIPT_DIR/.mcp.json" ]; then
  cp "$SCRIPT_DIR/.mcp.json" "$PROJECT_DIR/.mcp.json"
fi

# Portable sed -i (works on both GNU and BSD/macOS sed)
sedi() {
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

# Update CLAUDE.md additions
# Remove old additions section and re-append the latest version
if [ -f "$SCRIPT_DIR/CLAUDE.additions.md" ] && [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  # Check if we need to update — look for latest marker (@scope.md)
  if grep -q "@scope.md" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    echo "[setup] CLAUDE.md already up to date"
  elif grep -q "## User Interaction\|## Project Plan\|## Project Context\|## What This App Is" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    # Remove ALL old additions and re-append latest
    sedi '/^## User Interaction$/,$d' "$PROJECT_DIR/CLAUDE.md"
    sedi '/^## Project Plan$/,$d' "$PROJECT_DIR/CLAUDE.md"
    sedi '/^## Project Context$/,$d' "$PROJECT_DIR/CLAUDE.md"
    sedi '/^## What This App Is$/,$d' "$PROJECT_DIR/CLAUDE.md"
    cat "$SCRIPT_DIR/CLAUDE.additions.md" >> "$PROJECT_DIR/CLAUDE.md"
    echo "[setup] CLAUDE.md updated (replaced old additions)"
  else
    cat "$SCRIPT_DIR/CLAUDE.additions.md" >> "$PROJECT_DIR/CLAUDE.md"
    echo "[setup] Appended to CLAUDE.md"
  fi
fi

# Write version marker for tracking
echo "$SETUP_VERSION" > "$PROJECT_DIR/.claude/.setup-version"

echo "[setup] Done (v$SETUP_VERSION)"
