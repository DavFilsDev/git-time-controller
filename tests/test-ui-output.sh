#!/bin/bash

# UI and Output Tests for Git Date Modifier
# Tests verbose mode, help output, formatting, and user experience

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"
source "$SCRIPT_DIR/test-environment.sh"

# Test 1: Verbose mode output
test_verbose_mode() {
    print_header "Test 1: Verbose Mode Output"
    
    create_test_commit "verbose_test"
    
    # Capture verbose output
    local verbose_output
    verbose_output=$(./git-date-modifier.sh --date "2024-01-25 10:00:00" --verbose 2>&1)
    
    # Check for expected verbose messages
    local checks_passed=0
    local checks_total=0
    
    # Define expected patterns
    local expected_patterns=(
        "Parsing date"
        "Modifying last commit"
        "Commit date updated"
        "Done!"
    )
    
    for pattern in "${expected_patterns[@]}"; do
        ((checks_total++))
        if echo "$verbose_output" | grep -q "$pattern"; then
            echo "  ✓ Contains: '$pattern'"
            ((checks_passed++))
        else
            echo "  ✗ Missing: '$pattern'"
        fi
    done
    
    # Check for commit details in output
    ((checks_total++))
    if echo "$verbose_output" | grep -q "Author:"; then
        echo "  ✓ Shows author information"
        ((checks_passed++))
    else
        echo "  ✗ Missing author information"
    fi
    
    ((checks_total++))
    if echo "$verbose_output" | grep -q "Date:"; then
        echo "  ✓ Shows date information"
        ((checks_passed++))
    else
        echo "  ✗ Missing date information"
    fi
    
    if [ $checks_passed -eq $checks_total ]; then
        print_success "Verbose mode provides complete output ($checks_passed/$checks_total checks)"
    else
        print_failure "Verbose mode output incomplete ($checks_passed/$checks_total checks)"
    fi
}

# Test 2: Quiet mode vs normal mode
test_quiet_mode() {
    print_header "Test 2: Quiet Mode vs Normal Mode"
    
    create_test_commit "quiet_test"
    
    # Test quiet mode
    local quiet_output
    quiet_output=$(./git-date-modifier.sh --date "2024-01-26 11:00:00" --quiet 2>&1)
    
    # Test normal mode (no --quiet)
    create_test_commit "normal_test"
    local normal_output
    normal_output=$(./git-date-modifier.sh --date "2024-01-26 12:00:00" 2>&1)
    
    # Compare outputs
    local quiet_length=${#quiet_output}
    local normal_length=${#normal_output}
    
    echo "  Quiet output length: $quiet_length characters"
    echo "  Normal output length: $normal_length characters"
    
    if [ $quiet_length -lt $normal_length ]; then
        print_success "Quiet mode produces less output than normal mode"
    else
        print_failure "Quiet mode not producing less output"
    fi
    
    # Check quiet mode is actually quiet
    if [ $quiet_length -lt 50 ]; then
        print_success "Quiet mode is appropriately quiet"
    else
        print_skip "Quiet mode output length check (might vary by implementation)"
    fi
}

# Test 3: Help output completeness
test_help_output() {
    print_header "Test 3: Help Output Completeness"
    
    # Get help output
    local help_output
    help_output=$(./git-date-modifier.sh --help 2>&1)
    
    local checks_passed=0
    local checks_total=0
    
    # Check for required sections
    local required_sections=(
        "Usage:"
        "Options:"
        "Examples:"
        "--date"
        "--format"
        "--help"
    )
    
    for section in "${required_sections[@]}"; do
        ((checks_total++))
        if echo "$help_output" | grep -q "$section"; then
            echo "  ✓ Contains: '$section'"
            ((checks_passed++))
        else
            echo "  ✗ Missing: '$section'"
        fi
    done
    
    # Check for example commands
    ((checks_total++))
    if echo "$help_output" | grep -q "git-date-modifier.*--date"; then
        echo "  ✓ Contains example command"
        ((checks_passed++))
    else
        echo "  ✗ Missing example command"
    fi
    
    # Check help is not empty
    ((checks_total++))
    if [ ${#help_output} -gt 100 ]; then
        echo "  ✓ Help output has sufficient content"
        ((checks_passed++))
    else
        echo "  ✗ Help output too short"
    fi
    
    if [ $checks_passed -eq $checks_total ]; then
        print_success "Help output is complete ($checks_passed/$checks_total checks)"
    else
        print_failure "Help output incomplete ($checks_passed/$checks_total checks)"
    fi
}

# Test 4: Color output (if applicable)
test_color_output() {
    print_header "Test 4: Color and Formatting Output"
    
    create_test_commit "color_test"
    
    # Check if output contains color codes (ANSI escape sequences)
    local output
    output=$(./git-date-modifier.sh --date "2024-01-27 09:00:00" --verbose 2>&1 || true)
    
    # Look for ANSI escape sequences
    if echo "$output" | grep -q $'\033'\|$'\e'\|$'\x1b'; then
        print_success "Output contains color/formatting codes"
        
        # Check for specific colors (basic check)
        if echo "$output" | grep -q $'\033\[0;32m'\|$'\033\[32m'; then
            echo "  ✓ Contains green color codes"
        fi
        
        if echo "$output" | grep -q $'\033\[0;31m'\|$'\033\[31m'; then
            echo "  ✓ Contains red color codes"
        fi
    else
        print_skip "No color codes detected (might be intentional or terminal dependent)"
    fi
    
    # Check formatting consistency
    local line_count=$(echo "$output" | wc -l)
    if [ $line_count -gt 5 ]; then
        print_success "Output has reasonable formatting ($line_count lines)"
    else
        print_failure "Output seems too short ($line_count lines)"
    fi
}

# Test 5: Progress indicators
test_progress_indicators() {
    print_header "Test 5: Progress and Status Indicators"
    
    create_test_commit "progress_test"
    
    # Test with verbose mode to see progress
    local output
    output=$(./git-date-modifier.sh --date "2024-01-28 14:30:00" --verbose 2>&1)
    
    # Look for action indicators
    local indicators=0
    
    if echo "$output" | grep -qi "parsing\|processing\|modifying\|updating"; then
        ((indicators++))
        echo "  ✓ Shows action indicators"
    fi
    
    if echo "$output" | grep -qi "success\|done\|complete\|updated"; then
        ((indicators++))
        echo "  ✓ Shows completion indicators"
    fi
    
    if echo "$output" | grep -q "✓\|✗\|↷"; then
        ((indicators++))
        echo "  ✓ Uses status symbols"
    fi
    
    if [ $indicators -ge 2 ]; then
        print_success "Good progress indication ($indicators/3 indicators)"
    else
        print_failure "Insufficient progress indication ($indicators/3 indicators)"
    fi
}

# Test 6: Error message formatting
test_error_formatting() {
    print_header "Test 6: Error Message Formatting"
    
    create_test_commit "error_format_test"
    
    # Generate an error
    local error_output
    error_output=$(./git-date-modifier.sh --invalid-option 2>&1)
    
    # Check error formatting
    local checks_passed=0
    
    # Error should be clear
    if echo "$error_output" | grep -qi "error\|unknown\|invalid"; then
        echo "  ✓ Error message is clear"
        ((checks_passed++))
    fi
    
    # Should suggest help
    if echo "$error_output" | grep -qi "help\|usage"; then
        echo "  ✓ Error suggests help"
        ((checks_passed++))
    fi
    
    # Should mention the invalid option
    if echo "$error_output" | grep -q "invalid-option"; then
        echo "  ✓ Error mentions the problem"
        ((checks_passed++))
    fi
    
    if [ $checks_passed -eq 3 ]; then
        print_success "Error messages well formatted"
    elif [ $checks_passed -ge 1 ]; then
        print_success "Basic error formatting present"
    else
        print_failure "Error messages poorly formatted"
    fi
}

# Test 7: Output consistency
test_output_consistency() {
    print_header "Test 7: Output Consistency"
    
    # Run the same command multiple times
    local outputs=()
    
    for i in {1..3}; do
        create_test_commit "consistency_test_$i"
        
        # Run with same parameters
        outputs+=("$(./git-date-modifier.sh --date "2024-01-29 15:00:00" 2>&1)")
        
        # Check exit code consistency
        if [ $? -ne 0 ]; then
            print_failure "Command failed on iteration $i"
            return
        fi
    done
    
    # Compare outputs (they should be similar)
    local first_output="${outputs[0]}"
    local consistent=true
    
    for i in {1..2}; do
        if [ "${outputs[$i]}" != "$first_output" ]; then
            echo "  ✗ Output $i differs from first"
            consistent=false
        fi
    done
    
    if [ "$consistent" = true ]; then
        print_success "Output is consistent across runs"
    else
        print_failure "Output varies across runs"
    fi
}

# Test 8: International date handling
test_international_dates() {
    print_header "Test 8: International Date Handling"
    
    create_test_commit "intl_date_test"
    
    # Test various international formats
    local intl_tests=(
        "2024-01-30 14:30:00"  # ISO
        "30/01/2024 14:30"     # European
        "01/30/2024 14:30"     # US
        "2024年1月30日 14時30分"  # Japanese (might fail, and that's OK)
    )
    
    local passed=0
    local total=0
    
    for test_date in "${intl_tests[@]}"; do
        ((total++))
        if ./git-date-modifier.sh --date "$test_date" --quiet 2>/dev/null; then
            echo "  ✓ Handled: $(echo "$test_date" | cut -c1-20)..."
            ((passed++))
        else
            echo "  ↷ Failed: $(echo "$test_date" | cut -c1-20)..."
        fi
    done
    
    # At least ISO should work
    if [ $passed -ge 1 ]; then
        print_success "Handles some international formats ($passed/$total)"
    else
        print_failure "No international formats handled"
    fi
}

# Run all UI/output tests
run_ui_tests() {
    print_header "Running UI and Output Tests"
    
    reset_counters
    
    test_verbose_mode
    test_quiet_mode
    test_help_output
    test_color_output
    test_progress_indicators
    test_error_formatting
    test_output_consistency
    test_international_dates
    
    print_test_summary
    return $?
}

# Main execution
main() {
    if setup_test_env; then
        run_ui_tests
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