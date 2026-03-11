# 🤖 AI 协作开发框架

**[English](README.md)** | 中文

让 Claude Code 和 Codex 在同一个项目中实现**异步共享感知、互相评审**的协作开发。

---

## 🧠 设计理念

两个 AI Agent 都能读写项目文件。我们利用这一点，**用文件系统作为通信通道**：

```
┌────────────────┐
│                │
│  Claude Code   │  读取评审─┬───────┐
│                │       │       │
└────────┬───────┘       │      读写
         │               │       │
       写入操作              │       │
         │               │       │
         │               │       │
         ▼               │       ▼
┌────────────────┐       │  ┌────────┐
│                │       │  │        │
│ activity.jsonl │       │  │ 共享项目文件 │
│                │       │  │        │
└────────┬───────┘       │  └────────┘
         │               │       ▲
       读取日志              │       │
         │               │       │
         │               │       │
         ▼               │       │
┌────────────────┐       │      读写
│                │       │       │
│     Codex      │  ├────┼───────┘
│                │       │
└────────┬───────┘       │
         │               │
       写入评审              │
         │               │
         │               │
         ▼               │
┌────────────────┐       │
│                │       │
│  REVIEW-*.md   │  ├────┘
│                │
└────────────────┘
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

## 🚀 快速开始

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

## 📖 使用方法

安装后，在项目目录下打开两个终端窗口，分别启动两个 Agent：

```bash
# 终端 1                          # 终端 2
cd your-project                    cd your-project
claude                             codex
```

两个 Agent 启动后会自动读取各自的指令文件（`CLAUDE.md` / `AGENTS.md`），无需额外引导。

### 核心命令

在任一 Agent 对话框中输入：

| 命令 | 作用 |
|------|------|
| **"同步"** 或 **"sync"** | 读取对方最近操作，写评审 |
| **"评审"** 或 **"review"** | 评审对方最后一次操作 |
| **"状态"** 或 **"status"** | 查看整体协作状态面板 |
| **"交接"** 或 **"handoff"** | 写详细上下文交接文档 |

也可以直接在终端运行脚本查看状态：

```bash
./scripts/collab-status.sh         # 协作面板
./scripts/sync-peer.sh claude-code # 查看 codex 的新动态
./scripts/sync-peer.sh codex       # 查看 claude-code 的新动态
```

---

## 🔄 完整使用示例

以下是一个真实的协作场景：用两个 Agent 协作开发一个用户认证模块。

### 第一轮：Claude Code 做架构设计

```
┌─ 终端 1 (Claude Code) ──────────────────────────────────────────────┐
│                                                                      │
│  你: 设计一个用户认证模块，要求支持 JWT + refresh token              │
│                                                                      │
│  Claude Code:                                                        │
│    → 输出架构方案                                                    │
│    → 写入 .collab/plans/auth-plan.md                                │
│    → 自动记录日志到 activity.jsonl                                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

此时 `.collab/logs/activity.jsonl` 中多了一条：

```json
{"agent":"claude-code","action_type":"design","summary":"Auth module architecture with JWT + refresh token",...}
```

### 第二轮：切到 Codex，同步 + 评审

```
┌─ 终端 2 (Codex) ────────────────────────────────────────────────────┐
│                                                                      │
│  你: 同步一下                                                        │
│                                                                      │
│  Codex:                                                              │
│    → 读取 activity.jsonl，发现 Claude Code 新增了架构设计            │
│    → 读取 .collab/plans/auth-plan.md                                │
│    → 写评审: "JWT 方案合理，建议 refresh token 加 rotation 机制"     │
│    → 写入 .collab/reviews/REVIEW-1773200000-codex.md                │
│                                                                      │
│  你: 按照这个架构开始实现认证中间件                                  │
│                                                                      │
│  Codex:                                                              │
│    → 读取架构方案，编写 src/middleware/auth.ts                       │
│    → 自动记录日志                                                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 第三轮：切回 Claude Code，同步 + 评审 + 迭代

```
┌─ 终端 1 (Claude Code) ──────────────────────────────────────────────┐
│                                                                      │
│  你: 同步一下                                                        │
│                                                                      │
│  Claude Code:                                                        │
│    → 发现 Codex 的 2 条新动态：评审 + 代码实现                       │
│    → 读取 src/middleware/auth.ts                                     │
│    → 写评审：                                                        │
│       "实现基本正确，但发现两个问题：                                │
│        1. 缺少 rate limiting，暴力破解风险                           │
│        2. 错误响应泄露了内部堆栈信息"                                │
│    → 写入 .collab/reviews/REVIEW-1773201000-claude-code.md          │
│                                                                      │
│  你: 把你评审里提到的两个问题修掉                                    │
│                                                                      │
│  Claude Code:                                                        │
│    → 添加 rate limiter 和安全的错误处理                              │
│    → 自动记录日志                                                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 随时查看协作状态

```bash
$ ./scripts/collab-status.sh

╔══════════════════════════════════════════════════╗
║       AI Collaboration Status Dashboard          ║
╚══════════════════════════════════════════════════╝

📌 当前焦点:
─────────────────
  状态: 🟢 正在实现认证模块

📋 最近活动 (最近 10 条):
─────────────────────────────
  🟣 [2026-03-11T03:30:00Z] claude-code/design: Auth module architecture
  🟢 [2026-03-11T03:35:00Z] codex/review: Reviewed auth architecture
  🟢 [2026-03-11T03:40:00Z] codex/code: Implemented auth middleware
  🟣 [2026-03-11T03:45:00Z] claude-code/review: Reviewed auth implementation
  🟣 [2026-03-11T03:50:00Z] claude-code/code: Added rate limiting and error handling

  📊 总计: 5 条操作 (🟣 Claude: 3 | 🟢 Codex: 2)

📝 评审文件:
─────────────────
  REVIEW-1773201000-claude-code.md
  REVIEW-1773200000-codex.md
```

### 协作循环总结

```
┌──────┐     ┌────────┐     ┌────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│      │     │        │     │                │     │                 │     │                  │
│      │     │        │     │                │     │                 │     │                  │
│ 你给指令 ├────►│ Claude ├─同步─►│     Codex      ├─同步─►│      Claude     ├─同步─►│       ...        │
│      │     │   设计   │     │     评审+实现      │     │      评审+修复      │     │                  │
│      │     │        │     │                │     │                 │     │                  │
└──────┘     └────┬───┘     └────────┬───────┘     └────────┬────────┘     └──────────────────┘
                  │                  │                      │
                  │                  │                      │
                  │                  └──────────┐           └───────────┐
                  │                             │                       │
                  │                             │                       │
                  │         ┌────────────────┐  │  ┌─────────────────┐  │  ┌──────────────────┐
                  │         │                │  │  │                 │  │  │                  │
                  │         │                │  │  │                 │  │  │                  │
                  └────────►│ activity.jsonl │  └─►│  activity.jsonl │  └─►│  activity.jsonl  │
                            │ plans/auth.md  │     │ REVIEW-codex.md │     │ REVIEW-claude.md │
                            │                │     │                 │     │                  │
                            └────────────────┘     └─────────────────┘     └──────────────────┘
```

**关键点：人类始终是指挥者。** 你决定何时切换 Agent、分配什么任务。框架只是确保切换时上下文不丢失。

---

## 📁 框架结构

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

## ⚠️ 注意事项

1. **双方均自动读取指令**：Claude Code 自动读取 `CLAUDE.md`，Codex 自动读取 `AGENTS.md`，两者启动后即遵守协作协议，无需额外引导。

2. **不是实时通信**：这是基于文件的异步协作，不是 WebSocket 实时通信。更准确地说，这是"异步共享感知"——每次启动、同步或查看状态时，双方都能看到对方已经写入的操作记录。

3. **日志会增长**：长期项目中 `activity.jsonl` 会变大，可以定期归档旧日志。

4. **Git 版本控制**：建议将 `.collab/` 纳入 git，这样协作历史也被版本控制。

5. **Git Hook 为链式安装**：安装脚本会创建独立的 `post-commit.ai-collab` hook，并把它挂接到现有 `post-commit`，不会覆盖已有 hook 逻辑。

6. **人类仍是指挥者**：这个框架不是让两个 AI 自动对话，而是让你在两个 AI 间切换时保持上下文连续性。

---

## 🔧 自定义

### 添加更多 Agent

修改 `PROTOCOL.md`，在 Agent Identification 部分添加新的 agent 名称。

### 修改日志格式

编辑 `PROTOCOL.md` 中的 Activity Log Format 部分和 `log-action.sh`。

### 添加自定义命令

在 `CLAUDE.md` 或 `AGENTS.md` 中添加新的自然语言命令映射。

---

## 开源协议

MIT — 自由使用和修改。
