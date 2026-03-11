#!/bin/bash
# setup-collab.sh — Initialize AI collaboration framework in an existing project
# Usage: Run this script in your project root directory
#   curl -s <url> | bash   OR   bash /path/to/setup-collab.sh

set -e

echo "🤖 Setting up AI Collaborative Development Framework..."
echo ""

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    echo "⚠️  Not a git repository. Initializing git..."
    git init
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

FRAMEWORK_SOURCE="${1:-.}"  # Source directory of the framework files

# Create directory structure
echo "📁 Creating .collab directory structure..."
mkdir -p .collab/{logs,reviews,plans,context}
mkdir -p scripts

# Copy framework files if source specified
if [ -d "$FRAMEWORK_SOURCE/.collab" ] && [ "$FRAMEWORK_SOURCE" != "." ]; then
    echo "📋 Copying framework files..."
    cp -r "$FRAMEWORK_SOURCE/.collab/"* .collab/
    cp -r "$FRAMEWORK_SOURCE/scripts/"* scripts/
    [ -f "$FRAMEWORK_SOURCE/CLAUDE.md" ] && cp "$FRAMEWORK_SOURCE/CLAUDE.md" .
    [ -f "$FRAMEWORK_SOURCE/AGENTS.md" ] && cp "$FRAMEWORK_SOURCE/AGENTS.md" .
fi

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

# Create empty activity log if not exists
touch .collab/logs/activity.jsonl

# Setup .gitignore additions
if ! grep -q ".collab/logs/activity.jsonl" .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# AI Collaboration - track the framework but activity logs are optional" >> .gitignore
    echo "# Uncomment next line if you don't want to version control the activity log" >> .gitignore
    echo "# .collab/logs/activity.jsonl" >> .gitignore
fi

# Setup git hook for auto-logging (optional)
if [ -d .git ]; then
    echo "🔗 Setting up git post-commit hook chain..."
    HOOK_FILE=".git/hooks/post-commit"
    HOOK_IMPL=".git/hooks/post-commit.ai-collab"
    HOOK_MARKER="# AI Collaboration Framework hook"

    cat > "$HOOK_IMPL" <<'HOOK'
#!/bin/bash
# Auto-log git commits to collaboration activity log
# This helps track file changes even when agents forget to log

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
LOG_ACTION="$REPO_ROOT/scripts/log-action.sh"
[ -x "$LOG_ACTION" ] || exit 0

COMMIT_MSG=$(git log -1 --pretty=format:"%s")
COMMIT_HASH=$(git log -1 --pretty=format:"%h")
AUTHOR=$(git log -1 --pretty=format:"%an")
FILES=$(git diff-tree --no-commit-id --name-only -r HEAD | tr '\n' ',' | sed 's/,$//')

# Try to detect which agent made the commit
AGENT="unknown"
if echo "$AUTHOR" | grep -qi "claude\|anthropic"; then
    AGENT="claude-code"
elif echo "$AUTHOR" | grep -qi "codex\|openai"; then
    AGENT="codex"
fi

"$LOG_ACTION" \
    "$AGENT" \
    "code" \
    "git commit: $COMMIT_MSG ($COMMIT_HASH)" \
    "$FILES" \
    "Auto-logged from git commit" \
    "auto-git" \
    >/dev/null 2>&1 || true
HOOK

    if [ ! -f "$HOOK_FILE" ]; then
        cat > "$HOOK_FILE" <<'HOOK'
#!/bin/bash
# AI Collaboration Framework hook
if [ -x ".git/hooks/post-commit.ai-collab" ]; then
    .git/hooks/post-commit.ai-collab
fi
HOOK
    elif ! grep -Fq "$HOOK_MARKER" "$HOOK_FILE"; then
        printf '\n%s\n%s\n%s\n' \
            "$HOOK_MARKER" \
            'if [ -x ".git/hooks/post-commit.ai-collab" ]; then' \
            '    .git/hooks/post-commit.ai-collab' \
            >> "$HOOK_FILE"
        printf '%s\n' 'fi' >> "$HOOK_FILE"
    fi

    chmod +x "$HOOK_IMPL"
    chmod +x "$HOOK_FILE"
fi

echo ""
echo "✅ AI Collaboration Framework is ready!"
echo ""
echo "📌 Quick Start:"
echo "  1. Open Claude Code in this directory → it reads CLAUDE.md automatically"
echo "  2. Open Codex in this directory → it reads AGENTS.md automatically"
echo "  3. Both agents will now follow the collaboration protocol"
echo ""
echo "📋 Available scripts:"
echo "  ./scripts/log-action.sh    — Log an action manually"
echo "  ./scripts/collab-status.sh — View collaboration dashboard"
echo "  ./scripts/sync-peer.sh     — See what the other agent did"
echo "  ./scripts/create-review.sh — Create a peer review template"
echo ""
echo "🎯 Tell either agent 'sync' or '同步' to catch up on peer activity"
echo ""
