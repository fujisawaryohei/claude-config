#!/bin/bash
# Cross-platform notification for Claude Code hooks
# Usage: notify.sh '<message>'

MSG="${1:-通知}"
echo "$(date) notify.sh called: $MSG" >> /tmp/claude-notify.log

# tmux status bar
tmux display-message "$MSG" 2>/dev/null || true

OS=$(uname -s)
if [ "$OS" = "Darwin" ]; then
    osascript -e "display notification \"$MSG\" with title \"Claude Code\"" 2>/dev/null
elif grep -qi microsoft /proc/version 2>/dev/null; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PS1_WIN="$(wslpath -w "$SCRIPT_DIR/wsl-toast.ps1")"
    PWSH=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
    "$PWSH" -NonInteractive -ExecutionPolicy Bypass -File "$PS1_WIN" "$MSG" 2>/dev/null
fi
