#!/bin/bash
# Send notification with click-to-focus support + Bark push
# Usage: send_notify.sh <event_type>
# event_type: "stop" or "notification"

BARK_KEY="YOUR_BARK_KEY"  # ← 替换为你的 Bark Key
BARK_URL="https://api.day.app/${BARK_KEY}"
HOOK_DIR="$HOME/.claude/hooks"
NOTIFY_APP="$HOOK_DIR/ClaudeNotify.app/Contents/MacOS/claude_notify"
FOCUS_SCRIPT="$HOOK_DIR/focus_terminal.sh"

# Per-session key: TERM_SESSION_ID is unique per Terminal tab
SESSION_KEY="${TERM_SESSION_ID:-default}"

NAME=$(cat "/tmp/claude_session_name_${SESSION_KEY}" 2>/dev/null || echo "小瑶酱")
WINDOW_ID=$(cat "/tmp/claude_window_${SESSION_KEY}" 2>/dev/null)
EVENT_TYPE="$1"

if [ "$EVENT_TYPE" = "stop" ]; then
  TITLE="✅ ${NAME}完成了任务"
  BODY="快来看看结果吧"
elif [ "$EVENT_TYPE" = "notification" ]; then
  TITLE="🔔 ${NAME}等待你的回复"
  BODY="快回来看看吧"
else
  exit 0
fi

# All background, don't block the hook
# Mac notification with click-to-focus (auto-kill after 60s)
(
  "$NOTIFY_APP" "$TITLE" "$BODY" "$FOCUS_SCRIPT $WINDOW_ID" &
  PID=$!
  sleep 60
  kill $PID 2>/dev/null
) &>/dev/null &
disown

# Bark push to phone (use POST to handle spaces/emoji in title/body)
/usr/bin/curl -s --max-time 5 -X POST "${BARK_URL}" \
  -d "title=${TITLE}" \
  -d "body=${BODY}" \
  > /dev/null 2>&1

# Exit immediately, don't wait
exit 0
