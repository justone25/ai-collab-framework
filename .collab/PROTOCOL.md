# AI Collaborative Development Protocol v1.0

## 🎯 Purpose

This protocol enables **Claude Code** and **Codex** to collaborate on the same project with
full mutual awareness. Both agents MUST read this file before performing ANY operation.

---

## 📌 Core Rules

### Rule 1: Log Every Action
After completing ANY task (Q&A, design, planning, coding, debugging, refactoring),
the agent MUST append an entry to `.collab/logs/activity.jsonl`.

### Rule 2: Read Before Act
Before starting ANY task, the agent MUST:
1. Read the last 20 entries in `.collab/logs/activity.jsonl`
2. Read `.collab/context/current_focus.md` for ongoing context
3. Check `.collab/reviews/` for any pending reviews addressed to it

### Rule 3: Review After Peer Action
When you detect a new entry from the OTHER agent, you SHOULD:
1. Read the diff/changes made
2. Write a review to `.collab/reviews/REVIEW-{timestamp}-{reviewer}.md`
3. The review should include: problems found, things worth learning, suggestions

### Rule 4: Maintain Shared Context
After significant decisions or direction changes, update `.collab/context/current_focus.md`

---

## 📁 Directory Structure

```
.collab/
├── PROTOCOL.md              # This file - collaboration rules
├── logs/
│   └── activity.jsonl       # Append-only activity log (JSONL format)
├── reviews/
│   └── REVIEW-{ts}-{agent}.md  # Peer review files
├── plans/
│   └── {feature}-plan.md    # Shared design plans
└── context/
    ├── current_focus.md     # What we're working on right now
    ├── decisions.md         # Key architectural decisions log
    └── known_issues.md      # Known problems and tech debt
```

---

## 📝 Activity Log Format

Each line in `activity.jsonl` is a JSON object:

```json
{
  "id": "uuid-v4",
  "timestamp": "2025-01-15T10:30:00Z",
  "agent": "claude-code | codex",
  "action_type": "qa | design | plan | code | review | debug | refactor | discuss",
  "summary": "Brief description of what was done",
  "files_changed": ["src/foo.ts", "src/bar.ts"],
  "details": "Detailed description of the action, reasoning, and decisions made",
  "tags": ["feature-auth", "bugfix"],
  "parent_id": "uuid of the action this is responding to, if any"
}
```

---

## 📋 Review Format

```markdown
# Peer Review: {action_summary}

- **Reviewer**: claude-code | codex
- **Reviewing Action ID**: {action_id}
- **Reviewed Agent**: claude-code | codex
- **Timestamp**: ISO-8601

## 🔍 Issues Found
- [ ] Issue 1: description (severity: critical|major|minor|suggestion)

## ✅ Things Worth Learning
- Learning 1: what was done well and why

## 💡 Suggestions
- Suggestion 1: alternative approach or improvement

## 📊 Overall Assessment
Brief paragraph summarizing overall quality and collaboration notes.
```

---

## 🔄 Workflow: How a Typical Session Works

### When YOU start a new session:

```
1. Read .collab/logs/activity.jsonl (last 20 entries)
2. Read .collab/context/current_focus.md
3. Check .collab/reviews/ for reviews addressed to you
4. Announce: log an entry with action_type="discuss", summary="Session started, reviewing peer's recent work"
5. If peer has new actions since your last session:
   a. Read the changes (git diff or file inspection)
   b. Write a review
   c. Log the review action
6. Proceed with user's requested task
7. Log your action
8. Update context if needed
```

### When you COMPLETE a task:

```
1. Log the action to activity.jsonl
2. If it was a significant change, update current_focus.md
3. If it was a design decision, update decisions.md
4. Summarize what you did for the user
```

---

## 🏷️ Agent Identification

Each agent identifies itself as:
- `claude-code` — Anthropic Claude Code CLI
- `codex` — OpenAI Codex CLI

---

## ⚡ Quick Commands

Both agents should support these natural language commands from the user:

| Command | Action |
|---|---|
| "sync" / "同步" | Read all recent peer activity and summarize |
| "review" / "评审" | Review the last action by the peer agent |
| "status" / "状态" | Show current focus, recent activity, pending reviews |
| "plan" / "规划" | Create or update a shared plan |
| "handoff" / "交接" | Write a detailed context summary for the other agent |

---

## 🌐 Language Convention

- Log entries: English (for consistent JSON parsing)
- Reviews: Match the user's language preference (中文/English)
- Context files: Match the user's language preference
- Code comments: English
