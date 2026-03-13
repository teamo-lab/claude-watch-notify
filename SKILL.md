---
name: watch-notify
description: |
  Configure Claude Code notifications to Mac, iPhone, and Apple Watch via Bark.
  Use when user asks to "set up notifications", "configure watch notifications",
  "配置通知", "Apple Watch 通知", "Bark 推送", "手表震动",
  "notify me on my phone", "send notifications to iPhone".
tools: Read, Edit, Write, Bash
---

# Claude Watch Notify

为 Claude Code 配置多端通知推送（Mac + iPhone + Apple Watch），让你离开电脑也能实时掌握 Claude 的工作状态。

## 通知策略

### 触发时机

| Hook 事件 | 触发场景 | 通知标题 | 通知内容 |
|-----------|---------|---------|---------|
| **Stop** | Claude 完成任务、停止输出 | ✅ {名字}完成了任务 | 快来看看结果吧 |
| **Notification** | Claude 需要你的输入/确认 | 🔔 {名字}等待你的回复 | 快回来看看吧 |
| **SessionStart** | 新会话开始 | （弹窗）给 Claude 起个名字 | — |

### 通知渠道

每次触发会同时发送到三个渠道：

1. **Mac 系统通知** — `osascript display notification`，原生通知中心弹窗
2. **Mac 提示音** — `afplay Glass.aiff`
3. **Bark 推送** — 发送到 iPhone，如果 Apple Watch 已配对则自动震动

### 自定义名字机制

- 每次新开 session 时，通过 macOS 原生弹窗询问用户给 Claude 起个名字
- 名字保存到 `/tmp/claude_session_name`，后续所有通知使用该名字
- 默认名字：「小瑶酱」
- 重启电脑后 `/tmp` 被清空，下次 session 会重新询问

## 安装步骤

### Step 1: 安装 Bark（iPhone）

1. 在 **iPhone** 的 App Store 搜索「**Bark**」并安装（中国区可用）
2. 打开 Bark App，首页会显示你的推送 URL，格式为：
   ```
   https://api.day.app/YOUR_KEY/推送标题/推送内容
   ```
3. 复制 URL 中的 **KEY**（`YOUR_KEY` 部分），后续配置要用

### Step 2: 配对 Apple Watch（可选）

如果你希望通知震动 Apple Watch：

1. 确保 Apple Watch 与 **当前 iPhone** 配对
2. 如果 Watch 之前配对了旧手机，需要先在 Watch 上重置：
   - Watch 上操作：**设置 → 通用 → 还原 → 抹掉所有内容和设置**
   - 重启后在当前 iPhone 的 **Watch App** 中重新配对
3. Bark 的推送会自动转发到 Apple Watch 并触发震动，无需额外配置

### Step 3: 安装 Mac 依赖

```bash
# jq 用于 JSON 解析（可选，未来扩展用）
brew install jq
```

> `osascript` 和 `curl` 是 macOS 自带的，无需额外安装。

### Step 4: 创建 Session 启动脚本

创建文件 `~/.claude/hooks/session_start.sh`：

```bash
#!/bin/bash
NAME=$(/usr/bin/osascript -e 'set T to text returned of (display dialog "给小瑶酱起个名字吧：" default answer "小瑶酱" with title "Claude Code Session")' 2>/dev/null)
if [ -n "$NAME" ]; then
  echo "$NAME" > /tmp/claude_session_name
else
  echo "小瑶酱" > /tmp/claude_session_name
fi
```

```bash
chmod +x ~/.claude/hooks/session_start.sh
```

### Step 5: 配置 Claude Code Hooks

编辑 `~/.claude/settings.json`，将 `YOUR_BARK_KEY` 替换为你在 Step 1 获取的 Key：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/YOUR_USERNAME/.claude/hooks/session_start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "NAME=$(cat /tmp/claude_session_name 2>/dev/null || echo 小瑶酱); /usr/bin/osascript -e \"display notification \\\"快来看看结果吧\\\" with title \\\"✅ ${NAME}完成了任务\\\"\"; /usr/bin/afplay /System/Library/Sounds/Glass.aiff & /usr/bin/curl -s \"https://api.day.app/YOUR_BARK_KEY/✅${NAME}完成了任务/快来看看结果吧\" > /dev/null &"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "NAME=$(cat /tmp/claude_session_name 2>/dev/null || echo 小瑶酱); /usr/bin/osascript -e \"display notification \\\"快回来看看吧\\\" with title \\\"🔔 ${NAME}等待你的回复\\\"\"; /usr/bin/afplay /System/Library/Sounds/Glass.aiff & /usr/bin/curl -s \"https://api.day.app/YOUR_BARK_KEY/🔔${NAME}等待你的回复/快回来看看吧\" > /dev/null &"
          }
        ]
      }
    ]
  }
}
```

> **注意**：将 `YOUR_USERNAME` 替换为你的 macOS 用户名，`YOUR_BARK_KEY` 替换为 Bark 的 Key。

### Step 6: 验证

```bash
# 测试 Bark 推送
curl -s 'https://api.day.app/YOUR_BARK_KEY/测试/推送测试'

# 测试 Mac 通知
osascript -e 'display notification "测试内容" with title "测试标题"'
```

如果 iPhone 收到推送、Mac 弹出通知，就说明配置成功了。

## 注意事项

- **Mac 通知用 `osascript`** 而非 `terminal-notifier`，因为后者需要额外授予通知权限
- **所有命令使用绝对路径**（`/usr/bin/osascript`、`/usr/bin/curl`、`/usr/bin/afplay`），因为 hook 在 `/bin/sh` 环境执行，Homebrew 的 PATH 不可用
- **Bark 免费且无需服务器**，推送走苹果 APNs 通道，稳定可靠
- Apple Watch 震动依赖 iPhone 与 Watch 的配对，确保蓝牙/WiFi 连接正常
- `/tmp/claude_session_name` 在电脑重启后会被清除，这是预期行为

## 故障排查

| 问题 | 解决方案 |
|------|---------|
| Mac 不弹通知 | 检查「系统设置 → 通知 → Script Editor」是否开启 |
| iPhone 收不到推送 | 打开 Bark App 确认 Key 正确，检查 iPhone 通知权限 |
| Apple Watch 不震动 | 确认 Watch 与 iPhone 已配对，Bark 通知权限已开启 |
| hook 报 command not found | 确保命令使用绝对路径，不要依赖 PATH |
| 名字显示「小瑶酱」而非自定义名 | 检查 `/tmp/claude_session_name` 文件是否存在 |
