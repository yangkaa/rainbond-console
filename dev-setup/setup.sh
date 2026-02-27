#!/bin/bash
set -euo pipefail

# Rainbond AI Development Environment Setup
# One-command setup for Claude Code + Superpowers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================
# Step 0: Pre-flight checks
# ============================================================
echo ""
echo "=========================================="
echo "  Rainbond AI Development Environment"
echo "  Claude Code + Superpowers Setup"
echo "=========================================="
echo ""

# Check Claude Code is installed
if ! command -v claude &> /dev/null; then
    error "Claude Code is not installed."
    echo "  Install: npm install -g @anthropic-ai/claude-code"
    echo "  Or:      brew install claude-code"
    exit 1
fi
ok "Claude Code found: $(claude --version 2>/dev/null || echo 'installed')"

# Check git
if ! command -v git &> /dev/null; then
    error "git is not installed."
    exit 1
fi

# Check jq (needed for statusline)
if ! command -v jq &> /dev/null; then
    warn "jq is not installed. Status line will not work."
    warn "  Install: brew install jq (macOS) or apt install jq (Linux)"
fi

# ============================================================
# Step 1: Detect code directory
# ============================================================
echo ""
info "Step 1: Detecting Rainbond repository locations..."

# Default: sibling directory of rainbond-console
DEFAULT_CODE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check if repos exist at the default location
if [ -d "$DEFAULT_CODE_DIR/rainbond" ] && [ -d "$DEFAULT_CODE_DIR/rainbond-console" ] && [ -d "$DEFAULT_CODE_DIR/rainbond-ui" ]; then
    CODE_DIR="$DEFAULT_CODE_DIR"
    ok "Found all repos at: $CODE_DIR"
else
    echo ""
    echo "Could not find all repos at: $DEFAULT_CODE_DIR"
    echo "Expected directory structure:"
    echo "  <code-dir>/"
    echo "    rainbond/"
    echo "    rainbond-console/"
    echo "    rainbond-ui/"
    echo ""
    read -p "Enter your code directory path: " CODE_DIR
    CODE_DIR="${CODE_DIR/#\~/$HOME}"

    if [ ! -d "$CODE_DIR/rainbond" ] || [ ! -d "$CODE_DIR/rainbond-console" ] || [ ! -d "$CODE_DIR/rainbond-ui" ]; then
        error "Cannot find rainbond repos at: $CODE_DIR"
        exit 1
    fi
    ok "Found all repos at: $CODE_DIR"
fi

echo "  - rainbond:         $CODE_DIR/rainbond"
echo "  - rainbond-console: $CODE_DIR/rainbond-console"
echo "  - rainbond-ui:      $CODE_DIR/rainbond-ui"

# ============================================================
# Step 2: Install global CLAUDE.md
# ============================================================
echo ""
info "Step 2: Setting up global Claude Code configuration..."

mkdir -p "$CLAUDE_DIR/commands"

# Install CLAUDE.md (with path substitution)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    warn "~/.claude/CLAUDE.md already exists, creating backup"
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak.$(date +%Y%m%d%H%M%S)"
fi

sed "s|__CODE_DIR__|$CODE_DIR|g" "$SCRIPT_DIR/claude-global/CLAUDE.md" > "$CLAUDE_DIR/CLAUDE.md"
ok "Installed ~/.claude/CLAUDE.md"

# ============================================================
# Step 3: Install global commands
# ============================================================
echo ""
info "Step 3: Installing global commands..."

for cmd_file in "$SCRIPT_DIR/claude-global/commands/"*.md; do
    filename=$(basename "$cmd_file")
    # Substitute paths
    sed "s|__CODE_DIR__|$CODE_DIR|g" "$cmd_file" > "$CLAUDE_DIR/commands/$filename"
    ok "  /$(basename "$filename" .md)"
done

# ============================================================
# Step 4: Install statusline
# ============================================================
echo ""
info "Step 4: Installing status line..."

cp "$SCRIPT_DIR/claude-global/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"
ok "Installed statusline-command.sh"

# ============================================================
# Step 5: Install Superpowers plugin
# ============================================================
echo ""
info "Step 5: Installing Superpowers plugin..."

mkdir -p "$PLUGINS_DIR/marketplaces"
mkdir -p "$PLUGINS_DIR/cache/superpowers-marketplace/superpowers"

# Clone marketplace if not exists
if [ -d "$PLUGINS_DIR/marketplaces/superpowers-marketplace" ]; then
    info "Updating superpowers marketplace..."
    git -C "$PLUGINS_DIR/marketplaces/superpowers-marketplace" pull --quiet 2>/dev/null || true
    ok "Marketplace updated"
else
    info "Cloning superpowers marketplace..."
    git clone --quiet https://github.com/obra/superpowers-marketplace.git \
        "$PLUGINS_DIR/marketplaces/superpowers-marketplace"
    ok "Marketplace cloned"
fi

# Get the latest version from marketplace.json
SUPERPOWERS_VERSION=$(python3 -c "
import json
with open('$PLUGINS_DIR/marketplaces/superpowers-marketplace/.claude-plugin/marketplace.json') as f:
    data = json.load(f)
for p in data['plugins']:
    if p['name'] == 'superpowers' and p.get('source', {}).get('ref') != 'dev':
        print(p['version'])
        break
" 2>/dev/null || echo "4.3.1")

PLUGIN_DIR="$PLUGINS_DIR/cache/superpowers-marketplace/superpowers/$SUPERPOWERS_VERSION"

# Clone or update the plugin
if [ -d "$PLUGIN_DIR" ]; then
    info "Updating superpowers plugin (v$SUPERPOWERS_VERSION)..."
    git -C "$PLUGIN_DIR" pull --quiet 2>/dev/null || true
    ok "Plugin updated to v$SUPERPOWERS_VERSION"
else
    info "Cloning superpowers plugin (v$SUPERPOWERS_VERSION)..."
    git clone --quiet https://github.com/obra/superpowers.git "$PLUGIN_DIR"
    ok "Plugin installed v$SUPERPOWERS_VERSION"
fi

# Make hooks executable
chmod +x "$PLUGIN_DIR/hooks/session-start" "$PLUGIN_DIR/hooks/run-hook.cmd" 2>/dev/null || true

# Get git SHA
PLUGIN_SHA=$(git -C "$PLUGIN_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
INSTALL_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# ============================================================
# Step 6: Register marketplace and plugin
# ============================================================
echo ""
info "Step 6: Registering plugin in Claude Code..."

# Update known_marketplaces.json
python3 -c "
import json, os

path = '$PLUGINS_DIR/known_marketplaces.json'
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)

data['superpowers-marketplace'] = {
    'source': {'source': 'github', 'repo': 'obra/superpowers-marketplace'},
    'installLocation': '$PLUGINS_DIR/marketplaces/superpowers-marketplace',
    'lastUpdated': '$INSTALL_TIME'
}

with open(path, 'w') as f:
    json.dump(data, f, indent=2)
"
ok "Marketplace registered"

# Update installed_plugins.json
python3 -c "
import json, os

path = '$PLUGINS_DIR/installed_plugins.json'
data = {'version': 2, 'plugins': {}}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)

data['plugins']['superpowers@superpowers-marketplace'] = [{
    'scope': 'user',
    'installPath': '$PLUGIN_DIR',
    'version': '$SUPERPOWERS_VERSION',
    'installedAt': '$INSTALL_TIME',
    'lastUpdated': '$INSTALL_TIME',
    'gitCommitSha': '$PLUGIN_SHA'
}]

with open(path, 'w') as f:
    json.dump(data, f, indent=2)
"
ok "Plugin registered"

# ============================================================
# Step 7: Update settings.json
# ============================================================
echo ""
info "Step 7: Configuring settings..."

python3 -c "
import json, os

path = '$CLAUDE_DIR/settings.json'
settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)

# Ensure enabledPlugins exists
if 'enabledPlugins' not in settings:
    settings['enabledPlugins'] = {}

# Enable superpowers
settings['enabledPlugins']['superpowers@superpowers-marketplace'] = True

# Set statusline
settings['statusLine'] = {
    'type': 'command',
    'command': 'bash $CLAUDE_DIR/statusline-command.sh'
}

with open(path, 'w') as f:
    json.dump(settings, f, indent=2)
"
ok "Settings updated (superpowers enabled, statusline configured)"

# ============================================================
# Step 8: Verify installation
# ============================================================
echo ""
info "Step 8: Verifying installation..."

errors=0

# Check CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && grep -q "$CODE_DIR" "$CLAUDE_DIR/CLAUDE.md"; then
    ok "Global CLAUDE.md - paths correct"
else
    error "Global CLAUDE.md - path substitution failed"
    errors=$((errors + 1))
fi

# Check commands
cmd_count=$(ls "$CLAUDE_DIR/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$cmd_count" -ge 6 ]; then
    ok "Global commands installed ($cmd_count commands)"
else
    error "Expected 6 commands, found $cmd_count"
    errors=$((errors + 1))
fi

# Check plugin files
if [ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
    ok "Superpowers plugin files present"
else
    error "Superpowers plugin files missing"
    errors=$((errors + 1))
fi

# Check hook executable
if [ -x "$PLUGIN_DIR/hooks/session-start" ]; then
    ok "Session-start hook executable"
else
    error "Session-start hook not executable"
    errors=$((errors + 1))
fi

# Check hook produces valid JSON
if CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" bash "$PLUGIN_DIR/hooks/run-hook.cmd" session-start 2>/dev/null | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    ok "Session-start hook produces valid JSON"
else
    error "Session-start hook output is invalid"
    errors=$((errors + 1))
fi

# Check settings
if python3 -c "
import json
with open('$CLAUDE_DIR/settings.json') as f:
    s = json.load(f)
assert s['enabledPlugins'].get('superpowers@superpowers-marketplace') == True
" 2>/dev/null; then
    ok "Superpowers enabled in settings"
else
    error "Superpowers not enabled in settings"
    errors=$((errors + 1))
fi

# Check skills count
skill_count=$(ls -d "$PLUGIN_DIR/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
ok "Superpowers skills available: $skill_count"

# ============================================================
# Summary
# ============================================================
echo ""
echo "=========================================="
if [ $errors -eq 0 ]; then
    echo -e "  ${GREEN}Setup completed successfully!${NC}"
else
    echo -e "  ${YELLOW}Setup completed with $errors error(s)${NC}"
fi
echo "=========================================="
echo ""
echo "What was installed:"
echo "  - ~/.claude/CLAUDE.md           (global dev standards + Rainbond architecture)"
echo "  - ~/.claude/commands/           (6 global workflow commands)"
echo "  - ~/.claude/statusline-command.sh (git + context status line)"
echo "  - Superpowers plugin v$SUPERPOWERS_VERSION    (14 process discipline skills)"
echo ""
echo "Available commands:"
echo "  /design             - Interactive feature design discussion"
echo "  /spec-gen           - Generate task specs from design docs"
echo "  /spec-driven        - Execute tasks from specs with TDD"
echo "  /tdd                - Generic TDD workflow"
echo "  /cross-repo-feature - Cross-repo development guide"
echo "  /check-api-compat   - API compatibility check"
echo "  /brainstorm         - Superpowers: structured brainstorming"
echo "  /write-plan         - Superpowers: create execution plan"
echo "  /execute-plan       - Superpowers: execute plan"
echo ""
echo "Next steps:"
echo "  1. Start a new Claude Code session:  claude"
echo "  2. Test brainstorming gate:           'Help me implement a new feature'"
echo "  3. Test cross-repo workflow:          /cross-repo-feature"
echo "  4. Test verification:                 /verify  (in any repo)"
echo ""
