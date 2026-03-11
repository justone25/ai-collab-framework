#!/bin/bash
# sync-peer.sh — Show what the peer agent has done since your last action
# Usage: ./scripts/sync-peer.sh <your_agent_name>

set -e

MY_AGENT="${1:?Usage: sync-peer.sh <your_agent_name> (claude-code|codex)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/.collab/logs/activity.jsonl"

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

json_array_field() {
    local json="$1" field="$2"
    if $HAS_JQ; then
        echo "$json" | jq -r ".$field // empty"
    else
        echo "$json" | grep -o "\"$field\":\[[^]]*\]" | sed "s/\"$field\"://"
    fi
}

if [ ! -f "$LOG_FILE" ]; then
    echo "📭 No activity log found. This appears to be a fresh project."
    exit 0
fi

# Determine peer agent
if [ "$MY_AGENT" = "claude-code" ]; then
    PEER="codex"
elif [ "$MY_AGENT" = "codex" ]; then
    PEER="claude-code"
else
    echo "❌ Unknown agent: $MY_AGENT (expected: claude-code or codex)"
    exit 1
fi

# Find the line number of my last action
MY_LAST_LINE=$(grep -n "\"agent\":\"$MY_AGENT\"" "$LOG_FILE" | tail -1 | cut -d: -f1)

if [ -z "$MY_LAST_LINE" ]; then
    echo "📭 You ($MY_AGENT) have no previous actions. Showing all of $PEER's activity:"
    echo ""
    grep "\"agent\":\"$PEER\"" "$LOG_FILE" | while IFS= read -r line; do
        action=$(json_field "$line" "action_type")
        summary=$(json_field "$line" "summary")
        timestamp=$(json_field "$line" "timestamp")
        echo "  🟢 [$timestamp] $action: $summary"
    done
    exit 0
fi

# Get all peer actions AFTER my last action
TOTAL_LINES=$(wc -l < "$LOG_FILE")
if [ "$MY_LAST_LINE" -ge "$TOTAL_LINES" ]; then
    echo "✅ No new activity from $PEER since your last action."
    exit 0
fi

PEER_ACTIONS=$(tail -n +$((MY_LAST_LINE + 1)) "$LOG_FILE" | grep "\"agent\":\"$PEER\"")

if [ -z "$PEER_ACTIONS" ]; then
    echo "✅ No new activity from $PEER since your last action."
    exit 0
fi

COUNT=$(echo "$PEER_ACTIONS" | wc -l)
echo "📬 $PEER has $COUNT new action(s) since your last activity:"
echo ""

echo "$PEER_ACTIONS" | while IFS= read -r line; do
    id=$(json_field "$line" "id")
    action=$(json_field "$line" "action_type")
    summary=$(json_field "$line" "summary")
    details=$(json_field "$line" "details")
    files=$(json_array_field "$line" "files_changed")
    timestamp=$(json_field "$line" "timestamp")

    echo "  ┌─────────────────────────────────────"
    echo "  │ 🕐 $timestamp"
    echo "  │ 📌 [$action] $summary"
    [ -n "$details" ] && echo "  │ 📝 $details"
    [ -n "$files" ] && [ "$files" != "[]" ] && echo "  │ 📁 Files: $files"
    echo "  │ 🔑 ID: $id"
    echo "  └─────────────────────────────────────"
    echo ""
done

echo "💡 Tip: Use './scripts/create-review.sh $MY_AGENT <action_id> $PEER <summary>' to review"
