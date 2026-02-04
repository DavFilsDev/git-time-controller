#!/bin/bash

# Core Functionality Tests for Git Date Modifier
# Tests basic features, date formats, author/committer dates

# Test 1: Basic functionality
test_basic_functionality() {
    print_header "Test 1: Basic Functionality"
    
    create_test_commit "basic_test"
    
    # Get original date
    original_date=$(git log -1 --format="%cd" --date=iso)
    
    # Modify date
    ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet
    
    # Get new date
    new_date=$(git log -1 --format="%cd" --date=iso)
    
if [[ "$new_date" == "2024-01-15 14:30:00"* ]]; then
        print_success "Date modified successfully"
    else
        print_failure "Date modification failed. Got: $new_date"
    fi
}

# Test 2: Relative dates
test_relative_dates() {
    print_header "Test 2: Relative Dates"
    
    create_test_commit "relative_yesterday"
    
    # Test "yesterday"
    ./git-date-modifier.sh --date "yesterday" --quiet
    yesterday_date=$(git log -1 --format="%cd" --date=short)
    expected_yesterday=$(date -d "yesterday" +"%Y-%m-%d")
    
    if [ "$yesterday_date" = "$expected_yesterday" ]; then
        print_success "'yesterday' works correctly"
    else
        print_failure "'yesterday' failed. Expected: $expected_yesterday, Got: $yesterday_date"
    fi
    
    # Test "2 days ago"
    create_test_commit "relative_2days"
    
    ./git-date-modifier.sh --date "2 days ago" --quiet
    twodays_date=$(git log -1 --format="%cd" --date=short)
    expected_twodays=$(date -d "2 days ago" +"%Y-%m-%d")
    
    if [ "$twodays_date" = "$expected_twodays" ]; then
        print_success "'2 days ago' works correctly"
    else
        print_failure "'2 days ago' failed. Expected: $expected_twodays, Got: $twodays_date"
    fi
}

# Test 3: Custom date formats
test_custom_formats() {
    print_header "Test 3: Custom Date Formats"
    
    create_test_commit "custom_format"
    
    # Test custom format
    ./git-date-modifier.sh --date "2024-01-15 14:30:00" --format "%Y-%m-%d %H:%M:%S" --quiet
    custom_date=$(git log -1 --format="%cd" --date=format:"%Y-%m-%d %H:%M")
    
    if [ "$custom_date" = "2024-01-15 14:30" ]; then
        print_success "Custom format works correctly"
    else
        print_failure "Custom format failed. Got: $custom_date"
    fi
}

# Test 4: Author vs Committer dates
test_author_committer_dates() {
    print_header "Test 4: Author vs Committer Dates"
    
    # Git enforces: Author Date ≤ Committer Date
    
    # Test 1: --author-date sets author date, committer remains current
    create_test_commit "test_author"
    ./git-date-modifier.sh --date "2023-01-10 09:00:00" --author-date --quiet
    
    author_date=$(git log -1 --format="%ad" --date=short)
    if [ "$author_date" = "2023-01-10" ]; then
        print_success "--author-date sets author date correctly"
    else
        print_failure "--author-date failed. Got: $author_date"
    fi
    
    # Test 2: --committer-date with author ≤ committer
    create_test_commit "test_committer"
    
    # Set baseline dates
    ./git-date-modifier.sh --date "2023-06-15 12:00:00" --quiet
    
    # Set committer to future date
    ./git-date-modifier.sh --date "2023-12-25 18:00:00" --committer-date --quiet
    
    committer_date=$(git log -1 --format="%cd" --date=short)
    author_date=$(git log -1 --format="%ad" --date=short)
    
    # Verify committer was set and dates are consistent
    if [ "$committer_date" = "2023-12-25" ] && [[ "$author_date" < "$committer_date" || "$author_date" = "$committer_date" ]]; then
        print_success "--committer-date works (respects Author ≤ Committer constraint)"
    else
        print_failure "--committer-date failed. Author: $author_date, Committer: $committer_date"
    fi
    
    # Test 3: Verify both dates can be changed together (default behavior)
    create_test_commit "test_both"
    ./git-date-modifier.sh --date "2024-01-01 00:00:00" --quiet
    
    author_date=$(git log -1 --format="%ad" --date=short)
    committer_date=$(git log -1 --format="%cd" --date=short)
    
    if [ "$author_date" = "2024-01-01" ] && [ "$committer_date" = "2024-01-01" ]; then
        print_success "Default behavior changes both dates"
    else
        print_failure "Default date change failed. Author: $author_date, Committer: $committer_date"
    fi
}

# Run all core functionality tests
run_core_tests() {
    print_header "Running Core Functionality Tests"
    
    test_basic_functionality
    test_relative_dates
    test_custom_formats
    test_author_committer_dates
    
    print_test_summary
    return $?
}

# Source dependencies
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Standalone execution
    source "$(dirname "${BASH_SOURCE[0]}")/test-utils.sh"
    source "$(dirname "${BASH_SOURCE[0]}")/test-environment.sh"
    
    # Calculer SCRIPT_DIR avant d'appeler setup_test_env
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    # Passer SCRIPT_DIR en paramètre
    if setup_test_env "$SCRIPT_DIR"; then
        run_core_tests
        exit $?
    else
        echo "Failed to setup test environment"
        exit 1
    fi
fi