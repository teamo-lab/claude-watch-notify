#!/bin/bash
# Per-session key: use TTY to isolate multiple Claude Code windows
SESSION_KEY="${TERM_SESSION_ID:-default}"

# Session start: ask user for a name for Claude this session
NAME=$(/usr/bin/osascript -e 'set T to text returned of (display dialog "给小瑶酱起个名字吧：" default answer "小瑶酱" with title "Claude Code Session")' 2>/dev/null)
if [ -n "$NAME" ]; then
  echo "$NAME" > "/tmp/claude_session_name_${SESSION_KEY}"
else
  echo "小瑶酱" > "/tmp/claude_session_name_${SESSION_KEY}"
fi

# Save Terminal window ID for notification click-to-focus
WINDOW_ID=$(/usr/bin/osascript -e 'tell application "Terminal" to get id of front window' 2>/dev/null)
if [ -n "$WINDOW_ID" ]; then
  echo "$WINDOW_ID" > "/tmp/claude_window_${SESSION_KEY}"
fi
