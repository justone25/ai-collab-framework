# 🤖 AI Collaborative Development Framework

English | **[中文](README.zh-CN.md)**

Enable **async shared awareness and mutual code review** between Claude Code and Codex working on the same project.

---

## 🧠 How It Works

Both AI agents can read and write project files. This framework uses the **filesystem as a communication channel**:

```
┌──────────────┐     .collab/logs/activity.jsonl     ┌──────────────┐
│              │  ──────── write action ──────────▶   │              │
│  Claude Code │                                      │    Codex     │
│              │  ◀──────── read & review ─────────   │              │
└──────────────┘     .collab/reviews/REVIEW-*.md      └──────────────┘
        │                                                     │
        └──────────── Shared Project Files ───────────────────┘
```

### Core Mechanisms

| Mechanism | Implementation | Purpose |
|-----------|---------------|---------|
| **Activity Log** | `.collab/logs/activity.jsonl` | Record every action for peer awareness |
| **Peer Reviews** | `.collab/reviews/REVIEW-*.md` | Identify issues, highlight strengths |
| **Shared Context** | `.collab/context/` | Maintain consensus on project state |
| **Protocol** | `.collab/PROTOCOL.md` | Unified behavior rules |
| **Git Hook** | `.git/hooks/post-commit.ai-collab` | Optional auto-capture of commits |

---

## 🚀 Quick Start

### One-Line Remote Install (Recommended)

Run in your project root:

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/justone25/ai-collab-framework/main/install.sh | bash
```

The installer downloads the framework, copies files into your project, and sets up the git hook. It does not modify your existing code.

### Local Install

If you've already cloned this repo:

```bash
cd your-project
bash /path/to/ai-collab-framework/scripts/setup-collab.sh /path/to/ai-collab-framework
```

---

## 📖 Usage

After installation, open two terminal windows in your project directory:

```bash
# Terminal 1                       # Terminal 2
cd your-project                    cd your-project
claude                             codex
```

Both agents auto-read their instruction files (`CLAUDE.md` / `AGENTS.md`) on startup — no extra prompting needed.

### Core Commands

Type any of these in either agent's chat:

| Command | Action |
|---------|--------|
| **"sync"** | Read peer's recent actions, write a review |
| **"review"** | Review the peer's last action |
| **"status"** | Show collaboration status dashboard |
| **"handoff"** | Write a detailed context handoff document |

You can also run scripts directly in the terminal:

```bash
./scripts/collab-status.sh         # Status dashboard
./scripts/sync-peer.sh claude-code # See what codex has been doing
./scripts/sync-peer.sh codex       # See what claude-code has been doing
```

---

## 🔄 End-to-End Example

A real collaboration scenario: two agents building a user auth module together.

### Round 1: Claude Code designs the architecture

```
┌─ Terminal 1 (Claude Code) ──────────────────────────────────────────┐
│                                                                      │
│  You: Design a user auth module with JWT + refresh token support     │
│                                                                      │
│  Claude Code:                                                        │
│    → Outputs architecture proposal                                   │
│    → Writes .collab/plans/auth-plan.md                              │
│    → Auto-logs to activity.jsonl                                     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

A new entry appears in `.collab/logs/activity.jsonl`:

```json
{"agent":"claude-code","action_type":"design","summary":"Auth module architecture with JWT + refresh token",...}
```

### Round 2: Switch to Codex — sync + review

```
┌─ Terminal 2 (Codex) ────────────────────────────────────────────────┐
│                                                                      │
│  You: sync                                                           │
│                                                                      │
│  Codex:                                                              │
│    → Reads activity.jsonl, discovers Claude's architecture design    │
│    → Reads .collab/plans/auth-plan.md                               │
│    → Writes review: "JWT approach is solid, suggest adding           │
│      refresh token rotation"                                         │
│    → Saves .collab/reviews/REVIEW-1773200000-codex.md               │
│                                                                      │
│  You: Implement the auth middleware based on that architecture       │
│                                                                      │
│  Codex:                                                              │
│    → Reads the plan, writes src/middleware/auth.ts                   │
│    → Auto-logs the action                                            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Round 3: Back to Claude Code — sync + review + iterate

```
┌─ Terminal 1 (Claude Code) ──────────────────────────────────────────┐
│                                                                      │
│  You: sync                                                           │
│                                                                      │
│  Claude Code:                                                        │
│    → Finds 2 new actions from Codex: review + implementation        │
│    → Reads src/middleware/auth.ts                                    │
│    → Writes review:                                                  │
│       "Implementation is mostly correct, but found two issues:       │
│        1. Missing rate limiting — brute force risk                   │
│        2. Error responses leak internal stack traces"                │
│    → Saves .collab/reviews/REVIEW-1773201000-claude-code.md         │
│                                                                      │
│  You: Fix the two issues from your review                            │
│                                                                      │
│  Claude Code:                                                        │
│    → Adds rate limiter and secure error handling                     │
│    → Auto-logs the action                                            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Check collaboration status anytime

```bash
$ ./scripts/collab-status.sh

╔══════════════════════════════════════════════════╗
║       AI Collaboration Status Dashboard          ║
╚══════════════════════════════════════════════════╝

📌 Current Focus:
─────────────────
  Status: 🟢 Implementing auth module

📋 Recent Activity (last 10):
─────────────────────────────
  🟣 [2026-03-11T03:30:00Z] claude-code/design: Auth module architecture
  🟢 [2026-03-11T03:35:00Z] codex/review: Reviewed auth architecture
  🟢 [2026-03-11T03:40:00Z] codex/code: Implemented auth middleware
  🟣 [2026-03-11T03:45:00Z] claude-code/review: Reviewed auth implementation
  🟣 [2026-03-11T03:50:00Z] claude-code/code: Added rate limiting and error handling

  📊 Total: 5 actions (🟣 Claude: 3 | 🟢 Codex: 2)

📝 Review Files:
─────────────────
  REVIEW-1773201000-claude-code.md
  REVIEW-1773200000-codex.md
```

### The Collaboration Loop

```
  You instruct       You instruct       You instruct
      │                  │                  │
      ▼                  ▼                  ▼
  ┌────────┐  sync   ┌────────┐  sync   ┌────────┐
  │ Claude │ ──────▶ │  Codex │ ──────▶ │ Claude │  ...
  │ design │         │review+  │        │review+  │
  │        │         │implement│        │  fix    │
  └────────┘         └────────┘         └────────┘
      │                  │                  │
      ▼                  ▼                  ▼
  activity.jsonl     activity.jsonl     activity.jsonl
  plans/auth.md      REVIEW-codex.md    REVIEW-claude.md
```

**Key point: You are always in control.** You decide when to switch agents and what tasks to assign. The framework just ensures context is preserved across switches.

---

## 📁 Framework Structure

```
your-project/
├── CLAUDE.md                    # Claude Code instructions (auto-read)
├── AGENTS.md                    # Codex instructions (auto-read)
├── scripts/
│   ├── setup-collab.sh          # Setup script
│   ├── log-action.sh            # Log an action
│   ├── collab-status.sh         # Status dashboard
│   ├── sync-peer.sh             # Sync peer activity
│   └── create-review.sh         # Create review template
└── .collab/
    ├── PROTOCOL.md              # Collaboration protocol (core rules)
    ├── logs/
    │   └── activity.jsonl       # Activity log (JSONL)
    ├── reviews/
    │   └── REVIEW-{ts}-{agent}.md  # Peer review files
    ├── plans/
    │   └── {feature}-plan.md    # Shared design plans
    └── context/
        ├── current_focus.md     # Current work focus
        ├── decisions.md         # Architecture decision records
        └── known_issues.md      # Known issues tracker
```

---

## ⚠️ Important Notes

1. **Auto-read instructions**: Claude Code reads `CLAUDE.md`, Codex reads `AGENTS.md`. Both follow the collaboration protocol immediately on startup.

2. **Not real-time**: This is file-based async collaboration, not WebSocket messaging. More precisely, it's "async shared awareness" — each agent sees what the other has written whenever it syncs.

3. **Log growth**: In long-running projects, `activity.jsonl` will grow. Archive old entries periodically.

4. **Version control**: We recommend tracking `.collab/` in git so collaboration history is preserved.

5. **Non-destructive hooks**: The installer creates a separate `post-commit.ai-collab` hook and chains it from your existing `post-commit` — it never overwrites your hooks.

6. **Human in the loop**: This framework doesn't make two AIs talk to each other automatically. It keeps context continuous as *you* switch between them.

---

## 🔧 Customization

### Add more agents

Edit `PROTOCOL.md` → Agent Identification section.

### Change log format

Edit `PROTOCOL.md` → Activity Log Format section, and update `log-action.sh`.

### Add custom commands

Add new natural language command mappings in `CLAUDE.md` or `AGENTS.md`.

---

## License

MIT — free to use and modify.
