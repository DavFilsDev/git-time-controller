#!/bin/bash

# UI and Output Tests for Git Date Modifier
# Tests verbose mode, help output, and user interface

# Test 7: Verbose mode
test_verbose_mode() {
    print_header "Test 7: Verbose Mode"
    
    create_test_commit "verbose_test"
    
    # Capture verbose output
    verbose_output=$(./git-date-modifier.sh --date "2024-01-25 10:00:00" --verbose 2>&1)
    
    if echo "$verbose_output" | grep -q "Parsing date:" && \
       echo "$verbose_output" | grep -q "Modifying last commit"; then
        print_success "Verbose mode provides detailed output"
    else
        print_failure "Verbose mode output incomplete"
    fi
}

# Test 8: Help and usage
test_help_usage() {
    print_header "Test 8: Help and Usage"
    
    # Test help output
    help_output=$(./git-date-modifier.sh --help)
    
    if echo "$help_output" | grep -q "Usage:" && \
       echo "$help_output" | grep -q "Examples:"; then
        print_success "Help output is comprehensive"
    else
        print_failure "Help output incomplete"
    fi
    
    # Test invalid option
    if ./git-date-modifier.sh --invalid-option 2>&1 | grep -q "Unknown option"; then
        print_success "Handles invalid options gracefully"
    else
        print_failure "Doesn't handle invalid options properly"
    fi
}

# Run UI/output tests
run_ui_tests() {
    print_header "Running UI and Output Tests"
    
    test_verbose_mode
    test_help_usage
    
    print_test_summary
    return $?
}

# Source dependencies
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/test-utils.sh"
    source "$(dirname "${BASH_SOURCE[0]}")/test-environment.sh"
    
    if setup_test_env; then
        run_ui_tests
        exit $?
    else
        echo "Failed to setup test environment"
        exit 1
    fi
fi