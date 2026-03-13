#!/bin/bash
# Focus the Terminal window where Claude Code is running
# Accepts window ID as $1, or reads from session file
WINDOW_ID="${1:-$(cat /tmp/claude_terminal_window_id 2>/dev/null)}"

if [ -n "$WINDOW_ID" ]; then
  /usr/bin/osascript <<EOF
tell application "Terminal"
  activate
  set targetWindow to missing value
  repeat with w in windows
    if id of w is $WINDOW_ID then
      set targetWindow to w
      exit repeat
    end if
  end repeat
  if targetWindow is not missing value then
    set index of targetWindow to 1
  end if
end tell
EOF
else
  # Fallback: just activate Terminal
  /usr/bin/osascript -e 'tell application "Terminal" to activate'
fi
