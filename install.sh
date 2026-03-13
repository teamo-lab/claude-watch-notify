#!/bin/bash
# Claude Watch Notify - 安装脚本
# 自动编译 Swift 通知工具、部署 hook 脚本、配置签名

set -e

HOOK_DIR="$HOME/.claude/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$HOOK_DIR/ClaudeNotify.app/Contents"

echo "📦 Claude Watch Notify 安装脚本"
echo "================================"
echo ""

# 1. 创建 hooks 目录
mkdir -p "$HOOK_DIR"

# 2. 复制脚本文件
echo "→ 复制 hook 脚本..."
cp "$SCRIPT_DIR/hooks/session_start.sh" "$HOOK_DIR/"
cp "$SCRIPT_DIR/hooks/send_notify.sh" "$HOOK_DIR/"
cp "$SCRIPT_DIR/hooks/focus_terminal.sh" "$HOOK_DIR/"
chmod +x "$HOOK_DIR/session_start.sh" "$HOOK_DIR/send_notify.sh" "$HOOK_DIR/focus_terminal.sh"

# 3. 编译 Swift 通知工具
echo "→ 编译 ClaudeNotify.app..."
mkdir -p "$APP_DIR/MacOS"
cp "$SCRIPT_DIR/hooks/ClaudeNotify.app/Contents/Info.plist" "$APP_DIR/"
swiftc "$SCRIPT_DIR/hooks/claude_notify.swift" \
  -o "$APP_DIR/MacOS/claude_notify" \
  -framework Cocoa \
  -framework UserNotifications

# 4. Ad-hoc 签名（macOS 要求签名才能获得通知权限）
echo "→ 签名 ClaudeNotify.app..."
codesign --force --sign - "$HOOK_DIR/ClaudeNotify.app"

# 5. 首次运行以注册通知权限
echo "→ 注册通知权限（请在弹出的权限请求中点击「允许」）..."
"$APP_DIR/MacOS/claude_notify" "✅ 安装成功" "Claude Watch Notify 已就绪" "" &
NOTIFY_PID=$!
sleep 5
kill $NOTIFY_PID 2>/dev/null || true

echo ""
echo "✅ 安装完成！"
echo ""
echo "接下来请手动配置 ~/.claude/settings.json 中的 hooks（详见 README.md）"
echo "并替换 send_notify.sh 中的 BARK_KEY 为你自己的 Key"
