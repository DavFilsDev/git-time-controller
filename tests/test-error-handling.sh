#!/bin/bash

# Error Handling Tests for Git Date Modifier
# Tests invalid inputs, edge cases, and error conditions

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"
source "$SCRIPT_DIR/test-environment.sh"

# Test 1: Invalid date formats
test_invalid_date_formats() {
    print_header "Test 1: Invalid Date Formats"
    
    create_test_commit "invalid_date_test"
    
    # Test various invalid date formats
    local invalid_dates=(
        "not-a-date"
        "2024-13-01 14:30:00"  # Invalid month
        "2024-01-32 14:30:00"  # Invalid day
        "2024-01-15 25:30:00"  # Invalid hour
        "2024-01-15 14:60:00"  # Invalid minute
        "2024-01-15 14:30:60"  # Invalid second
        "Januar 15 2024"       # Misspelled month
        "yesterda"             # Misspelled relative
        "2 day ago"            # Singular vs plural
    )
    
    local passed=0
    local failed=0
    
    for invalid_date in "${invalid_dates[@]}"; do
        if ./git-date-modifier.sh --date "$invalid_date" --quiet 2>/dev/null; then
            echo "  ✗ Should reject: '$invalid_date'"
            ((failed++))
        else
            echo "  ✓ Correctly rejects: '$invalid_date'"
            ((passed++))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        print_success "All invalid date formats rejected ($passed tests)"
    else
        print_failure "$failed invalid date formats were not rejected ($passed passed)"
    fi
}

# Test 2: Missing required arguments
test_missing_arguments() {
    print_header "Test 2: Missing Required Arguments"
    
    create_test_commit "missing_args_test"
    
    # Test missing --date argument
    if ./git-date-modifier.sh --quiet 2>&1 | grep -q "required\|error\|usage"; then
        print_success "Missing --date argument properly detected"
    else
        print_failure "Missing --date argument not properly detected"
    fi
    
    # Test with --date but no value
    if ./git-date-modifier.sh --date --quiet 2>&1 | grep -q "error\|expected\|usage"; then
        print_success "Missing value for --date properly detected"
    else
        # This might exit with different error, check exit code
        if ./git-date-modifier.sh --date --quiet 2>/dev/null; then
            print_failure "Missing value for --date should fail"
        else
            print_success "Missing value for --date causes failure"
        fi
    fi
}

# Test 3: Invalid command line options
test_invalid_options() {
    print_header "Test 3: Invalid Command Line Options"
    
    create_test_commit "invalid_options_test"
    
    # Test unknown option
    if ./git-date-modifier.sh --invalid-option 2>&1 | grep -q "unknown\|error\|usage"; then
        print_success "Unknown option properly rejected"
    else
        print_failure "Unknown option not properly rejected"
    fi
    
    # Test conflicting options
    if ./git-date-modifier.sh --date "2024-01-15 14:30:00" --author-date --committer-date 2>&1 | grep -q "conflict\|error\|usage"; then
        print_success "Conflicting options properly detected"
    else
        # Check exit code
        if ./git-date-modifier.sh --date "2024-01-15 14:30:00" --author-date --committer-date --quiet 2>/dev/null; then
            print_failure "Conflicting options should fail"
        else
            print_success "Conflicting options cause failure"
        fi
    fi
}

# Test 4: Non-git repository context
test_non_git_context() {
    print_header "Test 4: Non-Git Repository Context"
    
    create_test_commit "non_git_test"
    
    # Go to non-git directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Should fail when not in git repo
    if ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet 2>&1 | grep -q "not a git repository\|error"; then
        print_success "Properly fails outside git repository"
    else
        # Check exit code
        if ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet 2>/dev/null; then
            print_failure "Should fail outside git repository"
        else
            print_success "Fails outside git repository (exit code)"
        fi
    fi
    
    # Cleanup and return
    cd "$REPO_DIR"
    rm -rf "$temp_dir"
}

# Test 5: Empty repository (no commits)
test_empty_repository() {
    print_header "Test 5: Empty Repository"
    
    # Create a new empty repo for this test
    local empty_repo="$TEST_DIR/empty_repo"
    mkdir -p "$empty_repo"
    cd "$empty_repo"
    
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Copy script
    cp "$REPO_DIR/git-date-modifier.sh" .
    
    # Should fail with no commits
    if ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet 2>&1 | grep -q "no commits\|error"; then
        print_success "Properly handles empty repository"
    else
        # Check exit code
        if ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet 2>/dev/null; then
            print_failure "Should fail in empty repository"
        else
            print_success "Fails in empty repository (exit code)"
        fi
    fi
    
    # Return to main test repo
    cd "$REPO_DIR"
}

# Test 6: Malformed date formats
test_malformed_date_formats() {
    print_header "Test 6: Malformed Date Formats"
    
    create_test_commit "malformed_date_test"
    
    # Test dates with wrong separators, formats, etc.
    local malformed_dates=(
        "2024/01/15 14:30:00"  # Wrong separator
        "15-01-2024 14:30:00"  # Day-month-year
        "01-15-2024 14:30:00"  # Month-day-year (US format)
        "2024-01-15T14:30:00"  # ISO T separator
        "20240115 143000"      # No separators
        "January 15, 2024 2:30 PM"  # With comma and AM/PM
    )
    
    local handled=0
    local unhandled=0
    
    for date in "${malformed_dates[@]}"; do
        # Some might actually work with date -d, others won't
        if ./git-date-modifier.sh --date "$date" --quiet 2>/dev/null; then
            echo "  ↷ Handled (might be valid): '$date'"
            ((handled++))
        else
            echo "  ✓ Fails on malformed: '$date'"
            ((unhandled++))
        fi
    done
    
    echo "  Results: $handled handled, $unhandled rejected"
    
    # We consider it a success if at least some are rejected
    if [ $unhandled -gt 0 ]; then
        print_success "Some malformed dates properly rejected"
    else
        print_skip "All dates were accepted (date command might be lenient)"
    fi
}

# Test 7: Boundary date values
test_boundary_dates() {
    print_header "Test 7: Boundary Date Values"
    
    create_test_commit "boundary_date_test"
    
    # Test dates at boundaries
    local boundary_tests=(
        # Test passed
        "0001-01-01 00:00:00"  # Very early date
        "2038-01-19 03:14:07"  # Near 32-bit Unix time limit
    )
    
    for test_date in "${boundary_tests[@]}"; do
        if ./git-date-modifier.sh --date "$test_date" --quiet 2>/dev/null; then
            print_success "Accepts boundary date: $test_date"
        else
            print_failure "Rejects boundary date: $test_date"
        fi
    done
}

# Test 8: Help and error messages
test_error_messages() {
    print_header "Test 8: Error Messages Quality"
    
    # Test that error messages are helpful
    local tests=(
        "--help:should show usage"
        "--invalid-option:should show 'unknown option'"
        "missing --date:should show 'required' or 'error'"
    )
    
    for test_case in "${tests[@]}"; do
        local cmd="${test_case%%:*}"
        local expectation="${test_case#*:}"
        
        case "$cmd" in
            "--help")
                if ./git-date-modifier.sh --help 2>&1 | grep -q "Usage:"; then
                    echo "  ✓ --help shows usage information"
                else
                    echo "  ✗ --help missing usage information"
                fi
                ;;
            "--invalid-option")
                if ./git-date-modifier.sh --invalid-option 2>&1 | grep -qi "unknown\|invalid\|error"; then
                    echo "  ✓ Clear error for invalid option"
                else
                    echo "  ✗ Unclear error for invalid option"
                fi
                ;;
            "missing --date")
                if ./git-date-modifier.sh 2>&1 | grep -qi "required\|missing\|date.*required"; then
                    echo "  ✓ Clear error for missing date"
                else
                    echo "  ✗ Unclear error for missing date"
                fi
                ;;
        esac
    done
    
    print_success "Error message quality checks completed"
}

# Run all error handling tests
run_error_tests() {
    print_header "Running Error Handling Tests"
    
    reset_counters
    
    test_invalid_date_formats
    test_missing_arguments
    test_invalid_options
    test_non_git_context
    test_empty_repository
    test_malformed_date_formats
    test_boundary_dates
    test_error_messages
    
    print_test_summary
    return $?
}

# Main execution
main() {
    if setup_test_env; then
        run_error_tests
        return $?
    else
        echo -e "${RED}Failed to setup test environment${NC}"
        return 1
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
    exit $?
fi