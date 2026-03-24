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

# Copy .claude directory (skills, agents, rules)
mkdir -p "$PROJECT_DIR/.claude"
cp -r .claude/skills "$PROJECT_DIR/.claude/" 2>/dev/null || true
cp -r .claude/agents "$PROJECT_DIR/.claude/" 2>/dev/null || true
cp -r .claude/rules "$PROJECT_DIR/.claude/" 2>/dev/null || true
cp -r .claude/hooks "$PROJECT_DIR/.claude/" 2>/dev/null || true
chmod +x "$PROJECT_DIR/.claude/hooks/"*.sh 2>/dev/null || true

# Merge settings.local.json (don't overwrite if exists)
if [ -f .claude/settings.local.json ]; then
  if [ -f "$PROJECT_DIR/.claude/settings.local.json" ]; then
    echo "[setup] settings.local.json exists, skipping (merge manually if needed)"
  else
    cp .claude/settings.local.json "$PROJECT_DIR/.claude/settings.local.json"
  fi
fi

# Copy .mcp.json (don't overwrite)
if [ -f .mcp.json ] && [ ! -f "$PROJECT_DIR/.mcp.json" ]; then
  cp .mcp.json "$PROJECT_DIR/.mcp.json"
fi

# Append to CLAUDE.md (if our section isn't already there)
if [ -f CLAUDE.additions.md ]; then
  if ! grep -q "## User Interaction" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    cat CLAUDE.additions.md >> "$PROJECT_DIR/CLAUDE.md"
    echo "[setup] Appended to CLAUDE.md"
  else
    echo "[setup] CLAUDE.md already has our sections"
  fi
fi

echo "[setup] Done"
