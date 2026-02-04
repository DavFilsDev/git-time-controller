#!/bin/bash

# Error Handling Tests for Git Date Modifier
# Tests error cases and edge conditions

# Test 6: Error handling
test_error_handling() {
    print_header "Test 6: Error Handling"
    
    create_test_commit "error_test"
    
    # Test invalid date
    if ./git-date-modifier.sh --date "invalid-date-format" --quiet 2>/dev/null; then
        print_failure "Should reject invalid date format"
    else
        print_success "Rejects invalid date format"
    fi
    
    # Test missing date parameter
    if ./git-date-modifier.sh --quiet 2>/dev/null; then
        print_failure "Should require date parameter"
    else
        print_success "Requires date parameter"
    fi
    
    # Test in non-git directory
    cd /tmp || return 1
    if ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet 2>/dev/null; then
        print_failure "Should fail outside git repo"
    else
        print_success "Fails outside git repository"
    fi
    cd "$REPO_DIR" || return 1
}

# Run error handling tests
run_error_tests() {
    print_header "Running Error Handling Tests"
    
    test_error_handling
    
    print_test_summary
    return $?
}

# Source dependencies
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/test-utils.sh"
    source "$(dirname "${BASH_SOURCE[0]}")/test-environment.sh"
    
    # Calculer SCRIPT_DIR avant d'appeler setup_test_env
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if setup_test_env "$SCRIPT_DIR"; then
        run_error_tests
        exit $?
    else
        echo "Failed to setup test environment"
        exit 1
    fi
fi