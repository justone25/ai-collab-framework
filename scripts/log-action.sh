#!/bin/bash
# log-action.sh — Log an action to the collaboration activity log
# Usage: ./scripts/log-action.sh <agent> <action_type> <summary> [files_changed] [details] [tags] [parent_id]
#
# Examples:
#   ./scripts/log-action.sh claude-code code "Implemented auth middleware" "src/auth.ts" "Added JWT validation"
#   ./scripts/log-action.sh codex review "Reviewed auth implementation" "" "Found potential token leak" "security"

set -e

AGENT="${1:?Usage: log-action.sh <agent> <action_type> <summary> [files] [details] [tags] [parent_id]}"
ACTION_TYPE="${2:?Missing action_type: qa|design|plan|code|review|debug|refactor|discuss}"
SUMMARY="${3:?Missing summary}"
FILES_CHANGED="${4:-}"
DETAILS="${5:-}"
TAGS="${6:-}"
PARENT_ID="${7:-null}"

# Get project root (where .collab lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/.collab/logs/activity.jsonl"

# Generate UUID
if command -v uuidgen &>/dev/null; then
    ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
else
    ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$$-$RANDOM")
fi

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Format files as JSON array
if [ -n "$FILES_CHANGED" ]; then
    FILES_JSON=$(echo "$FILES_CHANGED" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | \
        awk 'BEGIN{printf "["} NR>1{printf ","} {printf "\"%s\"", $0} END{printf "]"}')
else
    FILES_JSON="[]"
fi

# Format tags as JSON array
if [ -n "$TAGS" ]; then
    TAGS_JSON=$(echo "$TAGS" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | \
        awk 'BEGIN{printf "["} NR>1{printf ","} {printf "\"%s\"", $0} END{printf "]"}')
else
    TAGS_JSON="[]"
fi

# Handle parent_id
if [ "$PARENT_ID" = "null" ] || [ -z "$PARENT_ID" ]; then
    PARENT_FIELD="null"
else
    PARENT_FIELD="\"$PARENT_ID\""
fi

# Escape special characters in strings for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' '
}

SUMMARY_ESC=$(escape_json "$SUMMARY")
DETAILS_ESC=$(escape_json "$DETAILS")

# Build JSON entry
ENTRY=$(cat <<EOF
{"id":"$ID","timestamp":"$TIMESTAMP","agent":"$AGENT","action_type":"$ACTION_TYPE","summary":"$SUMMARY_ESC","files_changed":$FILES_JSON,"details":"$DETAILS_ESC","tags":$TAGS_JSON,"parent_id":$PARENT_FIELD}
EOF
)

# Ensure log directory and file exist (fresh-start safety)
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Atomic append with mkdir-based lock (portable, no flock dependency)
LOCK_DIR="$LOG_FILE.lock"
LOCK_ACQUIRED=false
MAX_WAIT=30
WAITED=0
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 0.1
    WAITED=$((WAITED + 1))
    if [ "$WAITED" -ge "$MAX_WAIT" ]; then
        echo "❌ Could not acquire lock after ${MAX_WAIT} attempts. Another process may be stuck." >&2
        echo "   Remove $LOCK_DIR manually if no other log-action.sh is running." >&2
        exit 1
    fi
done
LOCK_ACQUIRED=true
trap '[ "$LOCK_ACQUIRED" = true ] && rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

# Append to log
echo "$ENTRY" >> "$LOG_FILE"

# Release lock early (trap is safety net for abnormal exit)
rmdir "$LOCK_DIR" 2>/dev/null || true
LOCK_ACQUIRED=false

echo "✅ Logged action: [$AGENT] $ACTION_TYPE — $SUMMARY"
echo "   ID: $ID"
echo "   Log: $LOG_FILE"
