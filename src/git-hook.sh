#!/bin/bash

# Git Pre-push Hook
# Automatically prompts to modify commit date before pushing

CONFIG_FILE=".git/git-date-modifier.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load configuration with defaults
load_config() {
    # Default configuration
    ENABLE_PROMPT=true
    DEFAULT_DATE_FORMAT="%Y-%m-%d %H:%M:%S"
    AUTO_DETECT_FORMAT=true
    VERBOSE=false
    MODIFY_AUTHOR_DATE=true
    MODIFY_COMMITTER_DATE=true
    
    # Override with config file if it exists
    if [ -f "$CONFIG_FILE" ]; then
        # Source in a subshell to avoid polluting main shell
        (
            source "$CONFIG_FILE" 2>/dev/null || true
            # Export variables back to parent
            declare -p ENABLE_PROMPT DEFAULT_DATE_FORMAT AUTO_DETECT_FORMAT \
                      VERBOSE MODIFY_AUTHOR_DATE MODIFY_COMMITTER_DATE 2>/dev/null || true
        ) | while IFS='=' read -r var value; do
            if [[ "$var" =~ ^declare\ --\ [a-zA-Z_] ]]; then
                eval "$var"
            fi
        done
    fi
}

# Validate and parse date
validate_and_parse_date() {
    local date_input="$1"
    local format="$2"
    local auto_detect="$3"
    
    # Handle "now" special case
    if [ "$date_input" = "now" ]; then
        date +"$format"
        return 0
    fi
    
    # Try to parse date
    if [ "$auto_detect" = true ]; then
        # Try multiple common formats
        if parsed=$(date -d "$date_input" +"$format" 2>/dev/null); then
            echo "$parsed"
            return 0
        fi
    else
        # Try exact format
        if parsed=$(date -d "$date_input" +"$format" 2>/dev/null); then
            echo "$parsed"
            return 0
        fi
    fi
    
    echo -e "${RED}Error: Could not parse date: $date_input${NC}" >&2
    return 1
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
    
    echo "Last commit: ${LAST_COMMIT_HASH:0:8}..."  # Show only first 8 chars
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
            # Parse the date
            parsed_date=$(validate_and_parse_date "$new_date" "$DEFAULT_DATE_FORMAT" "$AUTO_DETECT_FORMAT")
            if [ $? -ne 0 ]; then
                echo -e "${RED}Invalid date format. Skipping modification.${NC}"
                exit 0  # Don't fail the hook, just skip
            fi
            
            # Build git-date-modifier command with options
            CMD=""
            if command -v git-date-modifier &> /dev/null; then
                CMD="git-date-modifier"
            elif command -v gdm &> /dev/null; then
                CMD="gdm"
            fi
            
            if [ -n "$CMD" ]; then
                # Build arguments based on config
                ARGS="--date \"$parsed_date\" --format \"$DEFAULT_DATE_FORMAT\""
                
                if [ "$MODIFY_AUTHOR_DATE" = true ] && [ "$MODIFY_COMMITTER_DATE" = false ]; then
                    ARGS="$ARGS --author-date"
                elif [ "$MODIFY_AUTHOR_DATE" = false ] && [ "$MODIFY_COMMITTER_DATE" = true ]; then
                    ARGS="$ARGS --committer-date"
                fi
                
                if [ "$VERBOSE" = true ]; then
                    ARGS="$ARGS --verbose"
                fi
                
                # Execute the command
                eval "$CMD $ARGS"
            else
                echo -e "${YELLOW}Warning: git-date-modifier not found. Using git commands directly.${NC}"
                
                # Set environment variables based on config
                if [ "$MODIFY_AUTHOR_DATE" = true ]; then
                    export GIT_AUTHOR_DATE="$parsed_date"
                fi
                
                if [ "$MODIFY_COMMITTER_DATE" = true ]; then
                    export GIT_COMMITTER_DATE="$parsed_date"
                fi
                
                # Amend commit
                if git commit --amend --no-edit --date="$parsed_date" --quiet; then
                    echo -e "${GREEN}Commit date updated to: $parsed_date${NC}"
                else
                    echo -e "${RED}Error: Failed to update commit date${NC}" >&2
                fi
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