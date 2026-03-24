#!/bin/bash
set -e

DOTDIR="$(cd "$(dirname "$0")" && pwd)"

echo "Setting up claude-config..."

# Backup existing settings.json if present
if [ -f ~/.claude/settings.json ]; then
  echo "Backing up existing settings.json → ~/.claude/settings.json.bak"
  cp ~/.claude/settings.json ~/.claude/settings.json.bak
fi

# Install settings.json
cp "$DOTDIR/settings.json" ~/.claude/settings.json
echo "Installed settings.json"

# Link skills directory
# Remove existing symlink or directory if it's already a symlink
if [ -L ~/.claude/skills ]; then
  rm ~/.claude/skills
elif [ -d ~/.claude/skills ]; then
  echo "WARNING: ~/.claude/skills already exists as a real directory."
  echo "Move or remove it manually, then re-run this script."
  exit 1
fi

ln -s "$DOTDIR/skills" ~/.claude/skills
echo "Linked skills → ~/.claude/skills"

# Link hooks directory
if [ -L ~/.claude/hooks ]; then
  rm ~/.claude/hooks
elif [ -d ~/.claude/hooks ]; then
  echo "WARNING: ~/.claude/hooks already exists as a real directory."
  echo "Move or remove it manually, then re-run this script."
  exit 1
fi

ln -s "$DOTDIR/hooks" ~/.claude/hooks
chmod +x "$DOTDIR/hooks/notify.sh"
echo "Linked hooks → ~/.claude/hooks"

# Link commands directory
if [ -L ~/.claude/commands ]; then
  rm ~/.claude/commands
elif [ -d ~/.claude/commands ]; then
  echo "WARNING: ~/.claude/commands already exists as a real directory."
  echo "Move or remove it manually, then re-run this script."
  exit 1
fi

ln -s "$DOTDIR/commands" ~/.claude/commands
echo "Linked commands → ~/.claude/commands"

# Link agents directory
if [ -L ~/.claude/agents ]; then
  rm ~/.claude/agents
elif [ -d ~/.claude/agents ]; then
  echo "WARNING: ~/.claude/agents already exists as a real directory."
  echo "Move or remove it manually, then re-run this script."
  exit 1
fi

ln -s "$DOTDIR/agents" ~/.claude/agents
echo "Linked agents → ~/.claude/agents"

# Link rules directory
if [ -L ~/.claude/rules ]; then
  rm ~/.claude/rules
elif [ -d ~/.claude/rules ]; then
  echo "WARNING: ~/.claude/rules already exists as a real directory."
  echo "Move or remove it manually, then re-run this script."
  exit 1
fi

ln -s "$DOTDIR/rules" ~/.claude/rules
echo "Linked rules → ~/.claude/rules"

# Link scripts directory
if [ -L ~/.claude/scripts ]; then
  rm ~/.claude/scripts
elif [ -d ~/.claude/scripts ]; then
  echo "WARNING: ~/.claude/scripts already exists as a real directory."
  echo "Move or remove it manually, then re-run this script."
  exit 1
fi

ln -s "$DOTDIR/scripts" ~/.claude/scripts
echo "Linked scripts → ~/.claude/scripts"

echo ""
echo "Done! Skills, hooks, commands, agents, rules, scripts, and settings are now active globally."
