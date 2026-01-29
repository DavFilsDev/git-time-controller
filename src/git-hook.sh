#!/bin/bash

# Git Pre-push Hook
# Automatically prompts to modify commit date before pushing

HOOK_NAME="pre-push"
CONFIG_FILE=".git/git-date-modifier.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        # Default configuration
        ENABLE_PROMPT=true
        DEFAULT_DATE_FORMAT="%Y-%m-%d %H:%M:%S"
    fi
}

# Main hook function
main() {
    load_config
    
    # Skip if prompt is disabled
    if [ "$ENABLE_PROMPT" = false ]; then
        exit 0
    fi
    
    echo -e "${BLUE}Git Date Modifier Hook${NC}"
    echo "========================="
    
    # Get the last commit
    LAST_COMMIT_HASH=$(git log -1 --format="%H")
    LAST_COMMIT_DATE=$(git log -1 --format="%cd" --date=format:"%Y-%m-%d %H:%M:%S")
    
    echo "Last commit: $LAST_COMMIT_HASH"
    echo "Current date: $LAST_COMMIT_DATE"
    echo ""
    
    # Prompt user
    read -p "Do you want to modify the commit date? [y/N]: " response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Enter new date (press Enter to skip):"
        echo "Examples:"
        echo "  '2024-01-15 14:30:00' (ISO format)"
        echo "  '2 days ago' (relative time)"
        echo "  'now' (current time)"
        echo ""
        read -p "New date: " new_date
        
        if [ -n "$new_date" ]; then
            if [ "$new_date" = "now" ]; then
                new_date=$(date +"$DEFAULT_DATE_FORMAT")
            fi
            
            # Use git-date-modifier if available
            if command -v git-date-modifier &> /dev/null; then
                git-date-modifier --date "$new_date" --format "$DEFAULT_DATE_FORMAT"
            elif command -v gdm &> /dev/null; then
                gdm --date "$new_date" --format "$DEFAULT_DATE_FORMAT"
            else
                echo -e "${YELLOW}Warning: git-date-modifier not found. Using git commands directly.${NC}"
                
                # Parse date
                parsed_date=$(date -d "$new_date" +"$DEFAULT_DATE_FORMAT" 2>/dev/null || echo "$new_date")
                
                # Amend commit with new date
                export GIT_AUTHOR_DATE="$parsed_date"
                export GIT_COMMITTER_DATE="$parsed_date"
                
                git commit --amend --no-edit --date="$parsed_date" --quiet
                
                echo -e "${GREEN}Commit date updated to: $parsed_date${NC}"
            fi
            
            echo ""
            echo -e "${GREEN}Ready to push with updated date!${NC}"
        else
            echo -e "${YELLOW}Date not changed.${NC}"
        fi
    fi
    
    echo ""
    exit 0
}

# Run main function
main "$@"