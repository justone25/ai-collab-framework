#!/bin/bash
# collab-status.sh — Show current collaboration status
# Usage: ./scripts/collab-status.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COLLAB_DIR="$PROJECT_ROOT/.collab"
LOG_FILE="$COLLAB_DIR/logs/activity.jsonl"

# JSON field extractor: jq when available, grep/cut fallback
HAS_JQ=false
command -v jq &>/dev/null && HAS_JQ=true

json_field() {
    local json="$1" field="$2"
    if $HAS_JQ; then
        echo "$json" | jq -r ".$field // empty"
    else
        echo "$json" | grep -o "\"$field\":\"[^\"]*\"" | cut -d'"' -f4
    fi
}

echo "╔══════════════════════════════════════════════════╗"
echo "║       AI Collaboration Status Dashboard          ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Current focus
echo "📌 Current Focus:"
echo "─────────────────"
if [ -f "$COLLAB_DIR/context/current_focus.md" ]; then
    cat "$COLLAB_DIR/context/current_focus.md"
else
    echo "  (No focus set)"
fi
echo ""

# Recent activity
echo "📋 Recent Activity (last 10):"
echo "─────────────────────────────"
if [ -f "$LOG_FILE" ]; then
    tail -10 "$LOG_FILE" | while IFS= read -r line; do
        agent=$(json_field "$line" "agent")
        action=$(json_field "$line" "action_type")
        summary=$(json_field "$line" "summary")
        timestamp=$(json_field "$line" "timestamp")

        if [ "$agent" = "claude-code" ]; then
            icon="🟣"
        else
            icon="🟢"
        fi
        echo "  $icon [$timestamp] $agent/$action: $summary"
    done

    echo ""
    total=$(wc -l < "$LOG_FILE")
    claude_count=$(grep -c '"agent":"claude-code"' "$LOG_FILE" 2>/dev/null || echo 0)
    codex_count=$(grep -c '"agent":"codex"' "$LOG_FILE" 2>/dev/null || echo 0)
    echo "  📊 Total: $total actions (🟣 Claude: $claude_count | 🟢 Codex: $codex_count)"
else
    echo "  (No activity yet)"
fi
echo ""

# Pending reviews
echo "📝 Review Files:"
echo "─────────────────"
if [ -d "$COLLAB_DIR/reviews" ] && [ "$(ls -A "$COLLAB_DIR/reviews" 2>/dev/null)" ]; then
    ls -lt "$COLLAB_DIR/reviews/"*.md 2>/dev/null | head -5 | while read -r line; do
        filename=$(echo "$line" | awk '{print $NF}')
        basename "$filename"
    done
else
    echo "  (No reviews yet)"
fi
echo ""

# Known issues
echo "⚠️  Known Issues:"
echo "─────────────────"
if [ -f "$COLLAB_DIR/context/known_issues.md" ]; then
    head -20 "$COLLAB_DIR/context/known_issues.md"
else
    echo "  (None tracked)"
fi

echo ""
echo "════════════════════════════════════════════════════"
