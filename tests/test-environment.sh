#!/bin/bash

# Test Environment Setup for Git Date Modifier
# Handles test directory creation, repository setup, and cleanup

# Global variables (set by setup_test_env)
TEST_DIR=""
REPO_DIR=""

# Cleanup function
cleanup() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        echo -e "\n${YELLOW}Cleaning up test directory...${NC}"
        rm -rf "$TEST_DIR"
    fi
}

# Setup trap for cleanup
trap cleanup EXIT

# Setup test environment
setup_test_env() {
    print_header "Setting up test environment"
    
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
    
    # Copy test scripts to accessible location
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    cp "$SCRIPT_DIR/src/git-date-modifier.sh" .
    cp "$SCRIPT_DIR/src/git-hook.sh" .
    cp "$SCRIPT_DIR/src/setup-hooks.sh" .
    chmod +x git-date-modifier.sh git-hook.sh setup-hooks.sh
    
    echo "Test repository created at: $REPO_DIR"
    return 0
}

# Get repository directory
get_repo_dir() {
    echo "$REPO_DIR"
}

# Create a test commit (helper function)
create_test_commit() {
    local test_name="$1"
    local content="${2:-$test_name}"
    
    echo "$content" > "${test_name}.txt"
    git add "${test_name}.txt"
    git commit --quiet -m "Test commit: $test_name"
}

# Source utils if not already sourced
if [ -z "$TEST_UTILS_SOURCED" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/test-utils.sh"
    TEST_UTILS_SOURCED=1
fi