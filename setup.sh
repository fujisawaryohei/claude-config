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

echo ""
echo "Done! Skills and settings are now active globally."
