#!/bin/bash
# Install Base44 import skills and agents into a project directory
# Usage: ./install-b44.sh /path/to/project
# Only called when a project is created via "Import from Base44"

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR does not exist"
  exit 1
fi

echo "[b44-setup] Installing Base44 conversion skills into $PROJECT_DIR"

# Copy b44-* skills
mkdir -p "$PROJECT_DIR/.claude/skills"
for skill_dir in "$SCRIPT_DIR/.claude/skills"/b44-*/; do
  [ -d "$skill_dir" ] && cp -r "$skill_dir" "$PROJECT_DIR/.claude/skills/"
done

# Copy b44-* agents
mkdir -p "$PROJECT_DIR/.claude/agents"
for agent_file in "$SCRIPT_DIR/.claude/agents"/b44-*.md; do
  [ -f "$agent_file" ] && cp "$agent_file" "$PROJECT_DIR/.claude/agents/"
done

# Copy b44-* rules
mkdir -p "$PROJECT_DIR/.claude/rules"
for rule_file in "$SCRIPT_DIR/.claude/rules"/b44-*.md; do
  [ -f "$rule_file" ] && cp "$rule_file" "$PROJECT_DIR/.claude/rules/"
done

echo "[b44-setup] Done — installed b44 skills, agents, and rules"
