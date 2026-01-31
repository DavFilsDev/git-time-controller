#!/bin/bash

# Test Utilities for Git Date Modifier
# Shared functions and variables for all tests

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters (can be shared or isolated per test file)
declare -i PASS_COUNT=0
declare -i FAIL_COUNT=0
declare -i SKIP_COUNT=0

# Utility functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASS_COUNT++))
}

print_failure() {
    echo -e "${RED}✗ $1${NC}"
    ((FAIL_COUNT++))
}

print_skip() {
    echo -e "${YELLOW}↷ $1${NC}"
    ((SKIP_COUNT++))
}

print_test_summary() {
    print_header "Test Summary"
    echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    echo -e "${YELLOW}Skipped: $SKIP_COUNT${NC}"
    
    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "\n${GREEN} All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED} $FAIL_COUNT test(s) failed${NC}"
        return 1
    fi
}

# Reset counters for new test run
reset_counters() {
    PASS_COUNT=0
    FAIL_COUNT=0
    SKIP_COUNT=0
}

# Source this file safely
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This file contains utilities and should be sourced, not executed directly."
    echo "Use: source test-utils.sh"
    exit 1
fi