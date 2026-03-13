# Claude Watch Notify

> Claude Code 多端通知推送 — Mac + iPhone + Apple Watch，支持点击通知跳转到对应终端窗口

让 Claude Code 在任务完成或需要输入时，同时推送通知到 Mac、iPhone 和 Apple Watch，离开电脑也能实时掌握工作状态。**点击 Mac 通知即可直接跳转到对应的 Claude Code 终端窗口**。

## 系统要求

| 组件 | 要求 |
|------|------|
| macOS | **13 Ventura** 或更高（已测试 13 Ventura，理论兼容 14 Sonoma / 15 Sequoia） |
| Xcode CLI Tools | 必须（用于编译 Swift 通知工具：`xcode-select --install`） |
| Claude Code | 最新版 CLI |
| iPhone | [Bark App](https://apps.apple.com/app/bark-customed-notifications/id1403753865)（App Store 搜索「Bark」，中国区可用） |
| Apple Watch | 与 iPhone 配对即可（可选，没有 Watch 也能用 iPhone 接收推送） |

> **为什么不用 `terminal-notifier` 或 `osascript display notification`？**
> - `terminal-notifier` 在 macOS 13+ 存在兼容问题，可能无法弹出通知
> - `osascript display notification` 点击后会打开 Script Editor 而非 Terminal
> - 本项目使用自编译的 Swift 原生通知工具（`UNUserNotificationCenter`），支持点击回调跳转

## 效果演示

| 场景 | Mac | iPhone / Apple Watch |
|------|-----|---------------------|
| Claude 完成任务 | 系统通知 + 提示音，**点击跳转到对应窗口** | Bark 推送 + Watch 震动 |
| Claude 需要你的输入 | 系统通知 + 提示音，**点击跳转到对应窗口** | Bark 推送 + Watch 震动 |
| 新 Session 开始 | 弹窗给 Claude 起名字 + 记录窗口 ID | — |

通知标题会使用你给 Claude 起的名字，例如：
- ✅ **大聪明**完成了任务
- 🔔 **大聪明**等待你的回复

## 工作原理

```
Claude Code Hook 触发
        │
        ├──→ ClaudeNotify.app → Mac 通知中心弹窗（支持点击跳转）
        └──→ curl → Bark API    → APNs → iPhone 通知
                                           └──→ Apple Watch 震动
```

### 多窗口隔离

同时开多个 Claude Code 窗口时，每个窗口的名字和通知互不干扰：
- 使用 `TERM_SESSION_ID`（每个 Terminal tab 唯一）作为 session key
- 通知点击后跳转到**发出通知的那个窗口**，而非最后激活的窗口

### 关键文件

```
~/.claude/hooks/
├── session_start.sh          # Session 启动：起名字 + 记录窗口 ID
├── send_notify.sh            # 通知调度：Mac 通知 + Bark 推送
├── focus_terminal.sh         # 点击回调：激活指定 Terminal 窗口
├── claude_notify.swift       # Swift 源码（仅安装时需要）
└── ClaudeNotify.app/         # 编译后的通知工具
    └── Contents/
        ├── Info.plist
        └── MacOS/claude_notify
```

## 快速安装

### 1. 安装 Bark（iPhone）

在 **iPhone** App Store 搜索安装 **Bark**，打开后复制你的推送 Key：

```
https://api.day.app/YOUR_KEY/标题/内容
                    ^^^^^^^^
                    复制这个 Key
```

### 2. 克隆仓库并安装

```bash
git clone https://github.com/teamo-lab/claude-watch-notify.git
cd claude-watch-notify
./install.sh
```

安装脚本会自动：
- 复制 hook 脚本到 `~/.claude/hooks/`
- 编译 Swift 通知工具并打包为 `.app`
- Ad-hoc 签名（macOS 要求签名才能获得通知权限）
- 首次运行注册通知权限（请在弹出的权限请求中点击「允许」）

### 3. 配置 Bark Key

编辑 `~/.claude/hooks/send_notify.sh`，替换第一行的 `YOUR_BARK_KEY`：

```bash
BARK_KEY="YOUR_BARK_KEY"  # ← 替换为你的 Bark Key
```

### 4. 配置 Claude Code Hooks

编辑 `~/.claude/settings.json`，在 `hooks` 字段中添加：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session_start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/send_notify.sh stop"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/send_notify.sh notification"
          }
        ]
      }
    ]
  }
}
```

### 5. 验证

```bash
# 测试 Mac 通知 + 点击跳转
~/.claude/hooks/send_notify.sh stop

# 测试 Bark 推送（替换 YOUR_BARK_KEY）
curl -s 'https://api.day.app/YOUR_BARK_KEY/测试/推送测试'
```

收到 Mac 通知 + iPhone 推送 = 配置成功 ✅

## 注意事项

| 要点 | 说明 |
|------|------|
| 通知权限 | 首次运行后，在「系统设置 → 通知 → Claude Notify」中确认已开启 |
| 多窗口支持 | 每个 Terminal tab 独立，通知不会串到其他窗口 |
| 仅支持 Terminal.app | 点击跳转功能使用 AppleScript 控制 Terminal.app，iTerm2/Warp 需自行适配 |
| Hook 不阻塞 | 通知进程在后台运行，不会阻塞 Claude Code 的 hook 流程 |
| Bark 免费 | 推送走苹果 APNs 通道，无需自建服务器 |
| 重启后名字丢失 | `/tmp` 重启后被清除，下次新 session 会重新弹窗询问 |

## 故障排查

| 问题 | 解决方案 |
|------|---------|
| Mac 不弹通知 | 系统设置 → 通知 → Claude Notify → 确认开启 |
| 编译失败 | 确认已安装 Xcode CLI Tools：`xcode-select --install` |
| 点击通知没跳转 | 检查 `/tmp/claude_window_*` 文件是否存在 |
| 多窗口通知串了 | 确认 `TERM_SESSION_ID` 环境变量存在（Terminal.app 自动设置） |
| iPhone 收不到推送 | 确认 Bark Key 正确 + iPhone 通知权限已开启 |
| Apple Watch 不震动 | 确认 Watch 与 iPhone 已配对 + Bark 通知未被静音 |
| Hook 报 command not found | 确保脚本使用绝对路径（`/usr/bin/curl` 等） |

## License

MIT
