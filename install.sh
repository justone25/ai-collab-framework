#!/bin/bash
# install.sh — One-line remote installer for AI Collaborative Development Framework
# Usage: curl -fsSL https://raw.githubusercontent.com/<user>/ai-collab-framework/main/install.sh | bash
#
# Run this in your project's root directory.

set -e

REPO_URL="https://github.com/justone25/ai-collab-framework"
BRANCH="main"

echo "🤖 Installing AI Collaborative Development Framework..."
echo ""

# Require git
if ! command -v git &>/dev/null; then
    echo "❌ git is required but not found. Please install git first."
    exit 1
fi

# Must be run inside an existing project directory
if [ ! -d .git ] && [ ! -f package.json ] && [ ! -f Makefile ] && [ ! -f README.md ]; then
    echo "⚠️  This doesn't look like a project directory."
    echo "   Run this command in your project root:"
    echo "   cd /path/to/your/project && curl -fsSL <install-url> | bash"
    exit 1
fi

# Download framework to temp directory
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "📥 Downloading framework..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMPDIR/ai-collab-framework" 2>/dev/null

FRAMEWORK_DIR="$TMPDIR/ai-collab-framework"

if [ ! -f "$FRAMEWORK_DIR/scripts/setup-collab.sh" ]; then
    echo "❌ Download failed or repo structure unexpected."
    exit 1
fi

# Run setup with framework source
bash "$FRAMEWORK_DIR/scripts/setup-collab.sh" "$FRAMEWORK_DIR"

echo ""
echo "🗑️  Cleaned up temporary files."
echo "📖 See README: $REPO_URL"
