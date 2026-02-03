#!/bin/bash

# Test Environment Setup for Git Date Modifier
# Handles test directory creation, repository setup, and cleanup

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"

# Global variables
TEST_DIR=""
REPO_DIR=""
PROJECT_ROOT=""

# Find project root (relative to tests directory)
find_project_root() {
    local current_dir="$SCRIPT_DIR"
    
    # Go up until we find src/git-date-modifier.sh or install.sh
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/src/git-date-modifier.sh" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    echo -e "${RED}Error: Cannot find project root directory${NC}" >&2
    return 1
}

# Cleanup function
cleanup() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        echo -e "\n${YELLOW}Cleaning up test directory...${NC}"
        rm -rf "$TEST_DIR"
    fi
}

# Setup trap for cleanup
setup_cleanup_trap() {
    trap cleanup EXIT INT TERM
}

# Setup test environment
setup_test_env() {
    print_header "Setting up test environment"
    
    # Find project root
    PROJECT_ROOT="$(find_project_root)"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "Project root: $PROJECT_ROOT"
    
    # Create unique test directory
    TEST_DIR="/tmp/git-date-modifier-test-$(date +%s)"
    REPO_DIR="$TEST_DIR/repo"
    
    mkdir -p "$REPO_DIR"
    cd "$REPO_DIR" || return 1
    
    # Initialize test repository
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit with specific date
    echo "# Test Project" > README.md
    git add README.md
    GIT_AUTHOR_DATE="2024-01-01 00:00:00" \
    GIT_COMMITTER_DATE="2024-01-01 00:00:00" \
    git commit --quiet -m "Initial commit"
    
    # Copy scripts from project to test directory
    echo "Copying scripts to test directory..."
    cp "$PROJECT_ROOT/src/git-date-modifier.sh" .
    cp "$PROJECT_ROOT/src/git-hook.sh" .
    cp "$PROJECT_ROOT/src/setup-hooks.sh" .
    chmod +x git-date-modifier.sh git-hook.sh setup-hooks.sh
    
    # Verify scripts are copied
    if [ ! -f "git-date-modifier.sh" ]; then
        echo -e "${RED}Error: Failed to copy git-date-modifier.sh${NC}" >&2
        return 1
    fi
    
    echo "Test repository created at: $REPO_DIR"
    
    # Setup cleanup trap
    setup_cleanup_trap
    
    return 0
}

# Get repository directory
get_repo_dir() {
    echo "$REPO_DIR"
}

# Get test directory
get_test_dir() {
    echo "$TEST_DIR"
}

# Create a test commit (helper function)
create_test_commit() {
    local test_name="$1"
    local content="${2:-$test_name}"
    local counter="${3:-}"
    
    local filename="${test_name}${counter}.txt"
    echo "$content" > "$filename"
    git add "$filename"
    git commit --quiet -m "Test commit: $test_name$counter"
}

# Run git-date-modifier (wrapper with proper path)
run_git_date_modifier() {
    ./git-date-modifier.sh "$@"
}