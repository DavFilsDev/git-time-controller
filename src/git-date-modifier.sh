#!/bin/bash

# Git Date Modifier
# Script to modify the date of the last commit

set -e

# Default values
DATE_FORMAT="%Y-%m-%d %H:%M:%S"
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Modify the date of the last commit in Git"
    echo ""
    echo "Options:"
    echo "  --date DATE         Date to set (required)"
    echo "                      Formats:"
    echo "                      - ISO: '2024-01-15 14:30:00'"
    echo "                      - Relative: '2 days ago', '1 hour ago'"
    echo "                      - RFC2822: 'Mon, 15 Jan 2024 14:30:00 +0000'"
    echo "  --format FORMAT     Date format (default: '%Y-%m-%d %H:%M:%S')"
    echo "  --author-date       Change author date only"
    echo "  --committer-date    Change committer date only (default: both)"
    echo "  --verbose           Show detailed output"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --date '2024-01-15 14:30:00'"
    echo "  $0 --date '2 days ago'"
    echo "  $0 --date 'Jan 15 2024 14:30' --format '%b %d %Y %H:%M'"
}

# Function to parse date input
parse_date() {
    local date_input="$1"
    local format="$2"#!/bin/bash

# Git Date Modifier
# Script to modify the date of the last commit

set -e

# Default values
DATE_FORMAT="%Y-%m-%d %H:%M:%S"
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Modify the date of the last commit in Git"
    echo ""
    echo "Options:"
    echo "  --date DATE         Date to set (required)"
    echo "                      Formats:"
    echo "                      - ISO: '2024-01-15 14:30:00'"
    echo "                      - Relative: '2 days ago', '1 hour ago'"
    echo "                      - RFC2822: 'Mon, 15 Jan 2024 14:30:00 +0000'"
    echo "  --format FORMAT     Date format (default: '%Y-%m-%d %H:%M:%S')"
    echo "  --author-date       Change author date only"
    echo "  --committer-date    Change committer date only (default: both)"
    echo "  --verbose           Show detailed output"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --date '2024-01-15 14:30:00'"
    echo "  $0 --date '2 days ago'"
    echo "  $0 --date 'Jan 15 2024 14:30' --format '%b %d %Y %H:%M'"
}

# Function to parse date input
parse_date() {
    local date_input="$1"
    local format="$2"
    
    # Check if it's a relative date (e.g., "2 days ago")
    if [[ "$date_input" =~ [0-9]+\ (seconds|minutes|hours|days|weeks|months|years)\ ago ]]; then
        if date -d "$date_input" &>/dev/null; then
            date -d "$date_input" +"$format"
            return 0
        fi
    fi
    
    # Try parsing with given format
    if date -d "$date_input" &>/dev/null; then
        date -d "$date_input" +"$format"
        return 0
    fi
    
    # Try different common formats
    for fmt in "%Y-%m-%d %H:%M:%S" "%b %d %Y %H:%M" "%d/%m/%Y %H:%M" "%Y%m%d %H:%M"; do
        if date -d "$date_input" +"$format" &>/dev/null; then
            date -d "$date_input" +"$format"
            return 0
        fi
    done
    
    echo -e "${RED}Error: Could not parse date: $date_input${NC}" >&2
    return 1
}

# Function to modify commit date
modify_commit_date() {
    local new_date="$1"
    local change_author="${2:-true}"
    local change_committer="${3:-true}"
    
    # Get current commit info
    local author_name=$(git log -1 --format="%an")
    local author_email=$(git log -1 --format="%ae")
    local commit_msg=$(git log -1 --format="%B")
    
    # Prepare environment variables for git commit
    if [ "$change_author" = true ]; then
        export GIT_AUTHOR_DATE="$new_date"
    fi
    
    if [ "$change_committer" = true ]; then
        export GIT_COMMITTER_DATE="$new_date"
    fi
    
    # Create amended commit
    git commit --amend --no-edit --author="$author_name <$author_email>" --date="$new_date" --quiet
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${GREEN}Commit date updated to: $new_date${NC}"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --date)
            DATE_INPUT="$2"
            shift 2
            ;;
        --format)
            DATE_FORMAT="$2"
            shift 2
            ;;
        --author-date)
            CHANGE_AUTHOR=true
            CHANGE_COMMITTER=false
            shift
            ;;
        --committer-date)
            CHANGE_AUTHOR=false
            CHANGE_COMMITTER=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [ -z "$DATE_INPUT" ]; then
    echo -e "${RED}Error: --date option is required${NC}"
    usage
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

# Parse the date
if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}Parsing date: $DATE_INPUT${NC}"
fi

PARSED_DATE=$(parse_date "$DATE_INPUT" "$DATE_FORMAT")
if [ $? -ne 0 ]; then
    exit 1
fi

if [ "$VERBOSE" = true ]; then
    echo -e "${GREEN}Parsed date: $PARSED_DATE${NC}"
    echo -e "${BLUE}Modifying last commit...${NC}"
fi

# Modify the commit
modify_commit_date "$PARSED_DATE" "${CHANGE_AUTHOR:-true}" "${CHANGE_COMMITTER:-true}"

if [ "$VERBOSE" = true ]; then
    echo -e "${GREEN}Done!${NC}"
    echo ""
    echo "New commit details:"
    git log -1 --format="%H%nAuthor: %an <%ae>%nDate:   %ad%nCommit: %cd%n%B"
else
    echo -e "${GREEN}Commit date modified successfully${NC}"
fi
    
    # Check if it's a relative date (e.g., "2 days ago")
    if [[ "$date_input" =~ [0-9]+\ (seconds|minutes|hours|days|weeks|months|years)\ ago ]]; then
        if date -d "$date_input" &>/dev/null; then
            date -d "$date_input" +"$format"
            return 0
        fi
    fi
    
    # Try parsing with given format
    if date -d "$date_input" &>/dev/null; then
        date -d "$date_input" +"$format"
        return 0
    fi
    
    # Try different common formats
    for fmt in "%Y-%m-%d %H:%M:%S" "%b %d %Y %H:%M" "%d/%m/%Y %H:%M" "%Y%m%d %H:%M"; do
        if date -d "$date_input" +"$format" &>/dev/null; then
            date -d "$date_input" +"$format"
            return 0
        fi
    done
    
    echo -e "${RED}Error: Could not parse date: $date_input${NC}" >&2
    return 1
}

# Function to modify commit date
modify_commit_date() {
    local new_date="$1"
    local change_author="${2:-true}"
    local change_committer="${3:-true}"
    
    # Get current commit info
    local author_name=$(git log -1 --format="%an")
    local author_email=$(git log -1 --format="%ae")
    local commit_msg=$(git log -1 --format="%B")
    
    # Prepare environment variables for git commit
    if [ "$change_author" = true ]; then
        export GIT_AUTHOR_DATE="$new_date"
    fi
    
    if [ "$change_committer" = true ]; then
        export GIT_COMMITTER_DATE="$new_date"
    fi
    
    # Create amended commit
    git commit --amend --no-edit --author="$author_name <$author_email>" --date="$new_date" --quiet
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${GREEN}Commit date updated to: $new_date${NC}"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --date)
            DATE_INPUT="$2"
            shift 2
            ;;
        --format)
            DATE_FORMAT="$2"
            shift 2
            ;;
        --author-date)
            CHANGE_AUTHOR=true
            CHANGE_COMMITTER=false
            shift
            ;;
        --committer-date)
            CHANGE_AUTHOR=false
            CHANGE_COMMITTER=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [ -z "$DATE_INPUT" ]; then
    echo -e "${RED}Error: --date option is required${NC}"
    usage
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

# Parse the date
if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}Parsing date: $DATE_INPUT${NC}"
fi

PARSED_DATE=$(parse_date "$DATE_INPUT" "$DATE_FORMAT")
if [ $? -ne 0 ]; then
    exit 1
fi

if [ "$VERBOSE" = true ]; then
    echo -e "${GREEN}Parsed date: $PARSED_DATE${NC}"
    echo -e "${BLUE}Modifying last commit...${NC}"
fi

# Modify the commit
modify_commit_date "$PARSED_DATE" "${CHANGE_AUTHOR:-true}" "${CHANGE_COMMITTER:-true}"

if [ "$VERBOSE" = true ]; then
    echo -e "${GREEN}Done!${NC}"
    echo ""
    echo "New commit details:"
    git log -1 --format="%H%nAuthor: %an <%ae>%nDate:   %ad%nCommit: %cd%n%B"
else
    echo -e "${GREEN}Commit date modified successfully${NC}"
fi