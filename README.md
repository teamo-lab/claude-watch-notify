# Claude Watch Notify

> Claude Code 多端通知推送 Skill — Mac + iPhone + Apple Watch

让 Claude Code 在任务完成或需要输入时，同时推送通知到 Mac、iPhone 和 Apple Watch，离开电脑也能实时掌握工作状态。

## 效果演示

| 场景 | Mac | iPhone / Apple Watch |
|------|-----|---------------------|
| Claude 完成任务 | 系统通知 + 提示音 | Bark 推送 + Watch 震动 |
| Claude 需要你的输入 | 系统通知 + 提示音 | Bark 推送 + Watch 震动 |
| 新 Session 开始 | 弹窗给 Claude 起名字 | — |

通知标题会使用你给 Claude 起的名字，例如：
- ✅ **大聪明**完成了任务
- 🔔 **大聪明**等待你的回复

## 工作原理

```
Claude Code Hook 触发
        │
        ├──→ osascript      → Mac 通知中心弹窗
        ├──→ afplay          → Mac 提示音
        └──→ curl → Bark API → APNs → iPhone 通知
                                         └──→ Apple Watch 震动
```

利用 Claude Code 的 [Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) 机制，在 `Stop`（任务完成）和 `Notification`（需要输入）事件触发时，同时发送三路通知。

通过 [Bark](https://github.com/Finb/Bark)（一个免费的 iOS 推送 App）将通知发送到 iPhone，Apple Watch 会自动接收 iPhone 通知并震动提醒。

## 前置要求

- macOS（已测试 13+）
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- iPhone + [Bark App](https://apps.apple.com/app/bark-customed-notifications/id1403753865)（App Store 搜索「Bark」，中国区可用）
- Apple Watch 与 iPhone 配对（可选，没有 Watch 也能用 iPhone 接收推送）

## 快速安装

### 1. 安装 Bark

在 **iPhone** App Store 搜索安装 **Bark**，打开后复制你的推送 Key：

```
https://api.day.app/YOUR_KEY/标题/内容
                    ^^^^^^^^
                    复制这个 Key
```

### 2. 创建通知脚本

```bash
mkdir -p ~/.claude/hooks

cat > ~/.claude/hooks/session_start.sh << 'EOF'
#!/bin/bash
NAME=$(/usr/bin/osascript -e 'set T to text returned of (display dialog "给 Claude 起个名字吧：" default answer "小瑶酱" with title "Claude Code Session")' 2>/dev/null)
if [ -n "$NAME" ]; then
  echo "$NAME" > /tmp/claude_session_name
else
  echo "小瑶酱" > /tmp/claude_session_name
fi
EOF

chmod +x ~/.claude/hooks/session_start.sh
```

### 3. 配置 Hooks

编辑 `~/.claude/settings.json`，在 `hooks` 字段中添加以下配置。

**替换 `YOUR_BARK_KEY`** 为你的 Bark Key，**替换 `YOUR_USERNAME`** 为你的 macOS 用户名：

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

### 4. 验证

```bash
# 测试 Bark 推送（替换 YOUR_BARK_KEY）
curl -s 'https://api.day.app/YOUR_BARK_KEY/测试/推送测试'

# 测试 Mac 通知
osascript -e 'display notification "测试内容" with title "测试标题"'
```

iPhone 收到推送 + Mac 弹出通知 = 配置成功 ✅

## 注意事项

| 要点 | 说明 |
|------|------|
| 为什么用 `osascript` 而不是 `terminal-notifier`？ | `terminal-notifier` 需要额外授予通知权限，`osascript` 开箱即用 |
| 为什么命令用绝对路径？ | Hook 在 `/bin/sh` 环境执行，Homebrew 的 PATH（`/opt/homebrew/bin`）不可用 |
| Bark 收费吗？ | 免费，推送走苹果 APNs 通道，无需自建服务器 |
| 重启后名字会丢失吗？ | 会，`/tmp` 重启后被清除，下次新 session 会重新弹窗询问 |

## 故障排查

| 问题 | 解决方案 |
|------|---------|
| Mac 不弹通知 | 系统设置 → 通知 → Script Editor → 开启 |
| iPhone 收不到推送 | 确认 Bark Key 正确 + iPhone 通知权限已开启 |
| Apple Watch 不震动 | 确认 Watch 与 iPhone 已配对 + Bark 通知未被静音 |
| Hook 报 command not found | 确保使用绝对路径（`/usr/bin/curl` 等） |

## License

MIT
