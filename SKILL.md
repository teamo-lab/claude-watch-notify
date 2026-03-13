---
name: watch-notify
description: |
  Configure Claude Code notifications to Mac, iPhone, and Apple Watch via Bark.
  Supports click-to-focus: clicking a Mac notification jumps to the exact Terminal window.
  Use when user asks to "set up notifications", "configure watch notifications",
  "配置通知", "Apple Watch 通知", "Bark 推送", "手表震动",
  "notify me on my phone", "send notifications to iPhone",
  "click notification to focus", "点击通知跳转".
tools: Read, Edit, Write, Bash
---

# Claude Watch Notify

为 Claude Code 配置多端通知推送（Mac + iPhone + Apple Watch），支持点击通知跳转到对应终端窗口。

## 系统要求

- **macOS 13 Ventura** 或更高（13 Ventura / 14 Sonoma / 15 Sequoia）
- **Xcode Command Line Tools**（`xcode-select --install`）— 用于编译 Swift 通知工具
- **仅支持 Terminal.app**（点击跳转依赖 AppleScript 控制 Terminal.app）
- iTerm2 / Warp / VS Code Terminal 用户需自行适配 `focus_terminal.sh`

## 通知策略

### 触发时机

| Hook 事件 | 触发场景 | 通知标题 | 通知内容 |
|-----------|---------|---------|---------|
| **Stop** | Claude 完成任务、停止输出 | ✅ {名字}完成了任务 | 快来看看结果吧 |
| **Notification** | Claude 需要你的输入/确认 | 🔔 {名字}等待你的回复 | 快回来看看吧 |
| **SessionStart** | 新会话开始 | （弹窗）给 Claude 起个名字 | — |

### 通知渠道

每次触发同时发送：

1. **Mac 系统通知** — 通过 `ClaudeNotify.app`（自编译 Swift 工具），点击可跳转到对应 Terminal 窗口
2. **Bark 推送** — 发送到 iPhone，Apple Watch 自动震动

### 多窗口隔离

- 使用 `TERM_SESSION_ID` 作为 session key，每个 Terminal tab 独立
- 通知点击跳转到发出通知的窗口，不会串到其他窗口

### 自定义名字机制

- 每次新 session 弹窗询问名字，保存到 `/tmp/claude_session_name_${SESSION_KEY}`
- 默认名字：「小瑶酱」

## 安装步骤

### Step 1: 安装 Bark（iPhone）

1. iPhone App Store 搜索「**Bark**」并安装
2. 打开 Bark App，复制推送 URL 中的 **KEY**

### Step 2: 运行安装脚本

```bash
git clone https://github.com/teamo-lab/claude-watch-notify.git
cd claude-watch-notify
./install.sh
```

安装脚本自动完成：编译 Swift 通知工具 → Ad-hoc 签名 → 部署脚本 → 注册通知权限

### Step 3: 配置 Bark Key

编辑 `~/.claude/hooks/send_notify.sh`，替换 `YOUR_BARK_KEY`。

### Step 4: 配置 Claude Code Hooks

编辑 `~/.claude/settings.json`：

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

### Step 5: 验证

```bash
~/.claude/hooks/send_notify.sh stop
```

收到 Mac 通知并能点击跳转 = 配置成功。

## 技术说明

### 为什么自编译 Swift 工具？

| 方案 | 问题 |
|------|------|
| `terminal-notifier` | macOS 13+ 兼容性问题，可能无法弹出通知 |
| `osascript display notification` | 点击通知后打开 Script Editor，无法跳转到 Terminal |
| **ClaudeNotify.app（本项目）** | 使用 `UNUserNotificationCenter`，原生支持点击回调 |

### 关键文件

```
~/.claude/hooks/
├── session_start.sh          # Session 启动：起名字 + 记录窗口 ID
├── send_notify.sh            # 通知调度：Mac 通知 + Bark 推送
├── focus_terminal.sh         # 点击回调：AppleScript 激活指定 Terminal 窗口
├── claude_notify.swift       # Swift 源码
└── ClaudeNotify.app/         # 编译后的通知工具（ad-hoc 签名）
    └── Contents/
        ├── Info.plist
        └── MacOS/claude_notify
```

## 故障排查

| 问题 | 解决方案 |
|------|---------|
| Mac 不弹通知 | 系统设置 → 通知 → Claude Notify → 确认开启 |
| 编译失败 | `xcode-select --install` 安装 CLI Tools |
| 点击通知没跳转 | 检查 `/tmp/claude_window_*` 文件是否存在 |
| 多窗口通知串了 | 确认 `TERM_SESSION_ID` 环境变量存在 |
| iPhone 收不到推送 | 检查 Bark Key 和通知权限 |
