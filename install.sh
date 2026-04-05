#!/bin/bash
# Install One Editor Claude Code setup into a project directory
# Usage: ./install.sh /path/to/project

set -e

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR does not exist"
  exit 1
fi

echo "[setup] Installing Claude Code config into $PROJECT_DIR"

# Copy .claude directory (skills, agents, rules, hooks)
mkdir -p "$PROJECT_DIR/.claude"
cp -r .claude/skills "$PROJECT_DIR/.claude/" 2>/dev/null || true
cp -r .claude/agents "$PROJECT_DIR/.claude/" 2>/dev/null || true
cp -r .claude/rules "$PROJECT_DIR/.claude/" 2>/dev/null || true
cp -r .claude/hooks "$PROJECT_DIR/.claude/" 2>/dev/null || true
chmod +x "$PROJECT_DIR/.claude/hooks/"*.sh 2>/dev/null || true

# Always deploy settings.local.json (source of truth)
if [ -f .claude/settings.local.json ]; then
  cp .claude/settings.local.json "$PROJECT_DIR/.claude/settings.local.json"
  echo "[setup] settings.local.json updated"
fi

# Copy .mcp.json (don't overwrite)
if [ -f .mcp.json ] && [ ! -f "$PROJECT_DIR/.mcp.json" ]; then
  cp .mcp.json "$PROJECT_DIR/.mcp.json"
fi

# Update CLAUDE.md additions
# Remove old additions section and re-append the latest version
if [ -f CLAUDE.additions.md ] && [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  # Check if we need to update — look for latest marker (@scope.md)
  if grep -q "@scope.md" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    echo "[setup] CLAUDE.md already up to date"
  elif grep -q "## User Interaction\|## Project Plan\|## Project Context\|## What This App Is" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    # Remove ALL old additions and re-append latest
    sed -i '/^## User Interaction$/,$d' "$PROJECT_DIR/CLAUDE.md"
    sed -i '/^## Project Plan$/,$d' "$PROJECT_DIR/CLAUDE.md"
    sed -i '/^## Project Context$/,$d' "$PROJECT_DIR/CLAUDE.md"
    sed -i '/^## What This App Is$/,$d' "$PROJECT_DIR/CLAUDE.md"
    cat CLAUDE.additions.md >> "$PROJECT_DIR/CLAUDE.md"
    echo "[setup] CLAUDE.md updated (replaced old additions)"
  else
    cat CLAUDE.additions.md >> "$PROJECT_DIR/CLAUDE.md"
    echo "[setup] Appended to CLAUDE.md"
  fi
fi

echo "[setup] Done"
