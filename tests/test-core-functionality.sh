#!/bin/bash

# Core Functionality Tests for Git Date Modifier

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"
source "$SCRIPT_DIR/test-environment.sh"

# Test 1: Basic functionality
test_basic_functionality() {
    print_header "Test 1: Basic Functionality"
    
    create_test_commit "basic"
    
    # Get original date
    original_date=$(git log -1 --format="%cd" --date=iso)
    echo "Original date: $original_date"
    
    # Modify date
    if ! ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet; then
        print_failure "git-date-modifier command failed"
        return
    fi
    
    # Get new date
    new_date=$(git log -1 --format="%cd" --date=iso)
    echo "New date: $new_date"
    
    if [ "$new_date" = "2024-01-15 14:30:00 +0000" ]; then
        print_success "Date modified successfully"
    else
        print_failure "Date modification failed. Expected: 2024-01-15 14:30:00 +0000, Got: $new_date"
    fi
}

# Test 2: Relative dates
test_relative_dates() {
    print_header "Test 2: Relative Dates"
    
    # Test "yesterday"
    create_test_commit "yesterday_test"
    
    if ! ./git-date-modifier.sh --date "yesterday" --quiet; then
        print_failure "git-date-modifier command failed for 'yesterday'"
        return
    fi
    
    yesterday_date=$(git log -1 --format="%cd" --date=short)
    expected_yesterday=$(date -d "yesterday" +"%Y-%m-%d")
    
    if [ "$yesterday_date" = "$expected_yesterday" ]; then
        print_success "'yesterday' works correctly"
    else
        print_failure "'yesterday' failed. Expected: $expected_yesterday, Got: $yesterday_date"
    fi
    
    # Test "2 days ago"
    create_test_commit "twodays_test"
    
    if ! ./git-date-modifier.sh --date "2 days ago" --quiet; then
        print_failure "git-date-modifier command failed for '2 days ago'"
        return
    fi
    
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
    
    if ! ./git-date-modifier.sh --date "15/01/2024 14:30" --format "%d/%m/%Y %H:%M" --quiet; then
        print_failure "git-date-modifier command failed for custom format"
        return
    fi
    
    custom_date=$(git log -1 --format="%cd" --date=format:"%Y-%m-%d %H:%M")
    
    if [ "$custom_date" = "2024-01-15 14:30" ]; then
        print_success "Custom format works correctly"
    else
        print_failure "Custom format failed. Expected: 2024-01-15 14:30, Got: $custom_date"
    fi
}

# Test 4: Author vs Committer dates
test_author_committer_dates() {
    print_header "Test 4: Author vs Committer Dates"
    
    # Modify only author date
    create_test_commit "author_test"
    
    if ! ./git-date-modifier.sh --date "2024-01-10 09:00:00" --author-date --quiet; then
        print_failure "git-date-modifier command failed for --author-date"
        return
    fi
    
    author_date=$(git log -1 --format="%ad" --date=iso)
    committer_date=$(git log -1 --format="%cd" --date=iso)
    
    if [[ "$author_date" =~ "2024-01-10" ]] && [[ ! "$committer_date" =~ "2024-01-10" ]]; then
        print_success "Author date modified separately"
    else
        print_failure "Author date modification failed. Author: $author_date, Committer: $committer_date"
    fi
    
    # Modify only committer date
    create_test_commit "committer_test"
    
    if ! ./git-date-modifier.sh --date "2024-01-20 17:00:00" --committer-date --quiet; then
        print_failure "git-date-modifier command failed for --committer-date"
        return
    fi
    
    author_date=$(git log -1 --format="%ad" --date=iso)
    committer_date=$(git log -1 --format="%cd" --date=iso)
    
    if [[ "$committer_date" =~ "2024-01-20" ]] && [[ ! "$author_date" =~ "2024-01-20" ]]; then
        print_success "Committer date modified separately"
    else
        print_failure "Committer date modification failed. Author: $author_date, Committer: $committer_date"
    fi
}

# Run all core functionality tests
run_core_tests() {
    print_header "Running Core Functionality Tests"
    
    reset_counters
    
    test_basic_functionality
    test_relative_dates
    test_custom_formats
    test_author_committer_dates
    
    print_test_summary
    return $?
}

# Main execution
main() {
    if setup_test_env; then
        run_core_tests
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