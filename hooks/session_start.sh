#!/bin/bash
# Per-session key: TERM_SESSION_ID is unique per Terminal tab
SESSION_KEY="${TERM_SESSION_ID:-default}"

# Only show naming dialog for interactive top-level sessions
# Skip if: no TERM_SESSION_ID (subagent/background), or SESSION_KEY is "default"
if [ "$SESSION_KEY" = "default" ]; then
  exit 0
fi

# Use a lock file to prevent concurrent dialogs from the same tab
LOCK="/tmp/claude_session_lock_${SESSION_KEY}"
if [ -f "$LOCK" ]; then
  # Another session_start.sh is already showing a dialog for this tab
  exit 0
fi
touch "$LOCK"

# Ask for a name on every new Claude Code session
NAME=$(/usr/bin/osascript -e 'set T to text returned of (display dialog "给小瑶酱起个名字吧：" default answer "小瑶酱" with title "Claude Code Session")' 2>/dev/null)
if [ -n "$NAME" ]; then
  echo "$NAME" > "/tmp/claude_session_name_${SESSION_KEY}"
else
  echo "小瑶酱" > "/tmp/claude_session_name_${SESSION_KEY}"
fi

rm -f "$LOCK"

# Save Terminal window ID for notification click-to-focus
WINDOW_ID=$(/usr/bin/osascript -e 'tell application "Terminal" to get id of front window' 2>/dev/null)
if [ -n "$WINDOW_ID" ]; then
  echo "$WINDOW_ID" > "/tmp/claude_window_${SESSION_KEY}"
fi
