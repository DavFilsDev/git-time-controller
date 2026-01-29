#!/bin/bash

# Setup Git Hooks for Date Modifier

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

HOOK_DIR=".git/hooks"
PRE_PUSH_HOOK="$HOOK_DIR/pre-push"
CONFIG_FILE=".git/git-date-modifier.conf"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

echo -e "${BLUE}Setting up Git Date Modifier Hooks${NC}"
echo "======================================="

# Create hooks directory if it doesn't exist
mkdir -p "$HOOK_DIR"

# Create or update pre-push hook
if [ -f "$PRE_PUSH_HOOK" ]; then
    echo -e "${YELLOW}Warning: pre-push hook already exists${NC}"
    echo "Backing up existing hook to $PRE_PUSH_HOOK.backup"
    cp "$PRE_PUSH_HOOK" "$PRE_PUSH_HOOK.backup"
    
    # Check if our hook is already installed
    if grep -q "Git Date Modifier Hook" "$PRE_PUSH_HOOK"; then
        echo -e "${YELLOW}Hook already contains date modifier. Updating...${NC}"
    else
        echo "Appending date modifier to existing hook..."
        echo "" >> "$PRE_PUSH_HOOK"
        echo "# Git Date Modifier Hook (appended)" >> "$PRE_PUSH_HOOK"
        
        # Try to find git-hook.sh in various locations
        HOOK_SCRIPT=""
        if [ -f "/usr/local/bin/git-hook.sh" ]; then
            HOOK_SCRIPT="/usr/local/bin/git-hook.sh"
        elif [ -f "./git-hook.sh" ]; then
            HOOK_SCRIPT="./git-hook.sh"
        elif [ -f "$(dirname "$0")/git-hook.sh" ]; then
            HOOK_SCRIPT="$(dirname "$0")/git-hook.sh"
        fi
        
        if [ -n "$HOOK_SCRIPT" ]; then
            echo "bash \"$HOOK_SCRIPT\"" >> "$PRE_PUSH_HOOK"
        else
            echo -e "${RED}Error: Could not find git-hook.sh${NC}"
            echo "Please install git-date-modifier globally or copy git-hook.sh to this directory"
            exit 1
        fi
    fi
else
    echo "Creating new pre-push hook..."
    
    # Create the hook
    cat > "$PRE_PUSH_HOOK" << 'EOF'
#!/bin/bash

# Git Pre-push Hook
# This hook calls the Git Date Modifier

HOOK_SCRIPT=""

# Try to find git-hook.sh in various locations
if [ -f "/usr/local/bin/git-hook.sh" ]; then
    HOOK_SCRIPT="/usr/local/bin/git-hook.sh"
elif [ -f "./git-hook.sh" ]; then
    HOOK_SCRIPT="./git-hook.sh"
elif [ -f "$(dirname "$0")/../git-hook.sh" ]; then
    HOOK_SCRIPT="$(dirname "$0")/../git-hook.sh"
fi

if [ -n "$HOOK_SCRIPT" ] && [ -f "$HOOK_SCRIPT" ]; then
    bash "$HOOK_SCRIPT"
else
    echo "Warning: Git Date Modifier hook script not found"
    echo "Install git-date-modifier or run setup-hooks.sh again"
fi

EOF
    
    chmod +x "$PRE_PUSH_HOOK"
fi

# Create configuration file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating configuration file..."
    cat > "$CONFIG_FILE" << 'EOF'
# Git Date Modifier Configuration
# This file configures the behavior of the git-date-modifier hooks

# Enable/disable the prompt before pushing
ENABLE_PROMPT=true

# Default date format (strftime format)
DEFAULT_DATE_FORMAT="%Y-%m-%d %H:%M:%S"

# Auto-detect date format (true/false)
AUTO_DETECT_FORMAT=true

# Show verbose output
VERBOSE=false

# Modify both author and committer dates by default
MODIFY_AUTHOR_DATE=true
MODIFY_COMMITTER_DATE=true

EOF
fi

echo ""
echo -e "${GREEN}Hook setup complete!${NC}"
echo ""
echo "The following has been configured:"
echo "1. pre-push hook installed in $PRE_PUSH_HOOK"
echo "2. Configuration file created at $CONFIG_FILE"
echo ""
echo "You can edit the configuration file to customize behavior:"
echo "  - Set ENABLE_PROMPT=false to disable the prompt"
echo "  - Change DEFAULT_DATE_FORMAT for different date formats"
echo ""
echo "Next time you run 'git push', you'll be prompted to modify commit dates!"