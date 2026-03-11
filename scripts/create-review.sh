#!/bin/bash
# create-review.sh — Generate a peer review template
# Usage: ./scripts/create-review.sh <reviewer_agent> <action_id> <reviewed_agent> <action_summary>

set -e

REVIEWER="${1:?Usage: create-review.sh <reviewer> <action_id> <reviewed_agent> <summary>}"
ACTION_ID="${2:?Missing action_id to review}"
REVIEWED="${3:?Missing reviewed agent name}"
SUMMARY="${4:-Untitled action}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%s)
TIMESTAMP_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REVIEW_FILE="$PROJECT_ROOT/.collab/reviews/REVIEW-${TIMESTAMP}-${REVIEWER}.md"

cat > "$REVIEW_FILE" <<EOF
# Peer Review: ${SUMMARY}

- **Reviewer**: ${REVIEWER}
- **Reviewing Action ID**: ${ACTION_ID}
- **Reviewed Agent**: ${REVIEWED}
- **Timestamp**: ${TIMESTAMP_ISO}

## 🔍 Issues Found
- [ ] (List issues here, with severity: critical|major|minor|suggestion)

## ✅ Things Worth Learning
- (What was done well? What techniques or patterns are worth adopting?)

## 💡 Suggestions
- (Alternative approaches, improvements, optimizations)

## 📊 Overall Assessment
(Brief paragraph summarizing quality, approach, and collaboration notes)
EOF

echo "✅ Review template created: $REVIEW_FILE"
echo "   Please edit the file to complete your review."
