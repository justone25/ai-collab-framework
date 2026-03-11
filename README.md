# 🤖 AI Collaborative Development Framework

## Claude Code × Codex 协作开发框架

让 Claude Code 和 Codex 在同一个项目中实现**异步共享感知、互相评审**的协作开发。

---

## 🧠 设计理念

两个 AI Agent 都能读写项目文件。我们利用这一点，**用文件系统作为通信通道**：

```
┌──────────────┐     .collab/logs/activity.jsonl     ┌──────────────┐
│              │  ──────── write action ──────────▶   │              │
│  Claude Code │                                      │    Codex     │
│              │  ◀──────── read & review ─────────   │              │
└──────────────┘     .collab/reviews/REVIEW-*.md      └──────────────┘
        │                                                     │
        └──────────── Shared Project Files ───────────────────┘
```

### 核心机制

| 机制 | 实现方式 | 目的 |
|------|---------|------|
| **行为日志** | `.collab/logs/activity.jsonl` | 记录每次操作，让对方感知 |
| **互相评审** | `.collab/reviews/REVIEW-*.md` | 指出问题、学习亮点 |
| **共享上下文** | `.collab/context/` | 保持对项目状态的共识 |
| **协议规范** | `.collab/PROTOCOL.md` | 统一行为规则 |
| **Git Hook** | `.git/hooks/post-commit.ai-collab` | 可选自动捕获代码变更 |

---

## 🚀 Quick Start / 快速开始

### 一键远程安装（推荐）

在你的项目根目录执行：

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/justone25/ai-collab-framework/main/install.sh | bash
```

安装脚本会自动下载框架文件、复制到当前项目、配置 git hook，不会修改你的现有代码。

### 本地安装

如果你已经 clone 了本仓库：

```bash
cd your-project
bash /path/to/ai-collab-framework/scripts/setup-collab.sh /path/to/ai-collab-framework
```

---

## 📖 使用流程

### Step 1: 打开 Claude Code
```bash
cd your-project
claude  # Claude Code 会自动读取 CLAUDE.md
```
Claude Code 自动遵守协议，每次操作后记录日志。

### Step 2: 打开 Codex
```bash
cd your-project
codex   # Codex 会自动读取 AGENTS.md
```
Codex 自动遵守协议，每次操作后记录日志。

### Step 3: 切换工作时使用 "同步" 命令
在任意一个 Agent 中说：
- **"sync"** 或 **"同步"** → 查看对方最近的操作
- **"review"** 或 **"评审"** → 评审对方最后一次操作
- **"status"** 或 **"状态"** → 查看整体协作状态
- **"handoff"** 或 **"交接"** → 写详细的上下文交接文档

### Step 4: 查看协作面板
```bash
./scripts/collab-status.sh
```

---

## 🔄 典型工作流示例

```
你 → Claude Code: "设计一个用户认证模块的架构"
     Claude Code: 输出架构方案，写入 .collab/plans/auth-plan.md
                  日志记录: {action_type: "design", summary: "Auth module architecture"}

你 → Codex: "同步一下，看看 Claude 做了什么"
     Codex: 读取日志，发现架构方案
            评审: "JWT 方案合理，但建议考虑 refresh token rotation"
            写入 .collab/reviews/REVIEW-xxx-codex.md

你 → Codex: "按照这个架构开始实现"
     Codex: 读取架构方案，开始编码
            日志记录: {action_type: "code", summary: "Implemented auth middleware"}

你 → Claude Code: "同步一下"
     Claude Code: 读取日志和代码变更
                  评审: "实现基本正确，但缺少 rate limiting 和错误日志"
                  写入 .collab/reviews/REVIEW-xxx-claude-code.md
```

---

## 📁 Framework Structure / 框架结构

```
your-project/
├── CLAUDE.md                    # Claude Code 的指令文件（自动读取）
├── AGENTS.md                    # Codex 的指令文件（自动读取）
├── scripts/
│   ├── setup-collab.sh          # 一键安装脚本
│   ├── log-action.sh            # 记录操作
│   ├── collab-status.sh         # 协作状态面板
│   ├── sync-peer.sh             # 同步对方操作
│   └── create-review.sh         # 创建评审模板
└── .collab/
    ├── PROTOCOL.md              # 协作协议（核心规则）
    ├── logs/
    │   └── activity.jsonl       # 操作日志（JSONL 格式）
    ├── reviews/
    │   └── REVIEW-{ts}-{agent}.md  # 互评文件
    ├── plans/
    │   └── {feature}-plan.md    # 共享设计方案
    └── context/
        ├── current_focus.md     # 当前工作焦点
        ├── decisions.md         # 架构决策记录
        └── known_issues.md      # 已知问题追踪
```

---

## ⚠️ Important Notes / 注意事项

1. **双方均自动读取指令**：Claude Code 自动读取 `CLAUDE.md`，Codex 自动读取 `AGENTS.md`，两者启动后即遵守协作协议，无需额外引导。

2. **不是实时通信**：这是基于文件的异步协作，不是 WebSocket 实时通信。更准确地说，这是“异步共享感知”：每次启动、同步或查看状态时，双方都能看到对方已经写入的操作记录。

3. **日志会增长**：长期项目中 `activity.jsonl` 会变大，可以定期归档旧日志。

4. **Git 版本控制**：建议将 `.collab/` 纳入 git，这样协作历史也被版本控制。

5. **Git Hook 为链式安装**：安装脚本会创建独立的 `post-commit.ai-collab` hook，并尽量把它挂接到现有 `post-commit`，避免直接覆盖已有 hook 逻辑。

6. **人类仍是指挥者**：这个框架不是让两个 AI 自动对话，而是让你在两个 AI 间切换时保持上下文连续性。

---

## 🔧 Customization / 自定义

### 添加更多 Agent
修改 `PROTOCOL.md`，在 Agent Identification 部分添加新的 agent 名称。

### 修改日志格式
编辑 `PROTOCOL.md` 中的 Activity Log Format 部分和 `log-action.sh`。

### 添加自定义命令
在 `CLAUDE.md` 或 `AGENTS.md` 中添加新的自然语言命令映射。

---

## License
MIT — 自由使用和修改。
