#!/bin/bash

# Git Date Modifier Test Suite
# Comprehensive testing for all features

set -e

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TEST_DIR="/tmp/git-date-modifier-test-$(date +%s)"
REPO_DIR="$TEST_DIR/repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

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

cleanup() {
    echo -e "\n${YELLOW}Cleaning up test directory...${NC}"
    rm -rf "$TEST_DIR"
}

# Trap cleanup on exit
trap cleanup EXIT

# Setup test environment
setup_test_env() {
    print_header "Setting up test environment"
    
    mkdir -p "$REPO_DIR"
    cd "$REPO_DIR"
    
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
    cp "$SCRIPT_DIR/src/git-date-modifier.sh" .
    cp "$SCRIPT_DIR/src/git-hook.sh" .
    cp "$SCRIPT_DIR/src/setup-hooks.sh" .
    chmod +x git-date-modifier.sh git-hook.sh setup-hooks.sh
    
    echo "Test repository created at: $REPO_DIR"
}

# Test 1: Basic functionality
test_basic_functionality() {
    print_header "Test 1: Basic Functionality"
    
    # Create a test commit
    echo "test1" > file1.txt
    git add file1.txt
    git commit --quiet -m "Test commit 1"
    
    # Get original date
    original_date=$(git log -1 --format="%cd" --date=iso)
    
    # Modify date
    ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet
    
    # Get new date
    new_date=$(git log -1 --format="%cd" --date=iso)
    
    if [ "$new_date" = "2024-01-15 14:30:00 +0000" ]; then
        print_success "Date modified successfully"
    else
        print_failure "Date modification failed. Got: $new_date"
    fi
}

# Test 2: Relative dates
test_relative_dates() {
    print_header "Test 2: Relative Dates"
    
    echo "test2" > file2.txt
    git add file2.txt
    git commit --quiet -m "Test commit 2"
    
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
    echo "test3" > file3.txt
    git add file3.txt
    git commit --quiet -m "Test commit 3"
    
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
    
    echo "test4" > file4.txt
    git add file4.txt
    git commit --quiet -m "Test commit 4"
    
    # Test custom format
    ./git-date-modifier.sh --date "15/01/2024 14:30" --format "%d/%m/%Y %H:%M" --quiet
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
    
    echo "test5" > file5.txt
    git add file5.txt
    git commit --quiet -m "Test commit 5"
    
    # Modify only author date
    ./git-date-modifier.sh --date "2024-01-10 09:00:00" --author-date --quiet
    
    author_date=$(git log -1 --format="%ad" --date=iso)
    committer_date=$(git log -1 --format="%cd" --date=iso)
    
    if [[ "$author_date" =~ "2024-01-10" && "$committer_date" =~ "2024-01" ]]; then
        print_success "Author date modified separately"
    else
        print_failure "Author date modification failed"
    fi
    
    # Modify only committer date
    echo "test6" > file6.txt
    git add file6.txt
    git commit --quiet -m "Test commit 6"
    
    ./git-date-modifier.sh --date "2024-01-20 17:00:00" --committer-date --quiet
    
    author_date=$(git log -1 --format="%ad" --date=iso)
    committer_date=$(git log -1 --format="%cd" --date=iso)
    
    if [[ "$committer_date" =~ "2024-01-20" ]]; then
        print_success "Committer date modified separately"
    else
        print_failure "Committer date modification failed"
    fi
}

# Test 5: Hook installation
test_hook_installation() {
    print_header "Test 5: Hook Installation"
    
    # Install hooks
    ./setup-hooks.sh
    
    if [ -f ".git/hooks/pre-push" ]; then
        print_success "Pre-push hook installed"
        
        # Check hook is executable
        if [ -x ".git/hooks/pre-push" ]; then
            print_success "Hook is executable"
        else
            print_failure "Hook is not executable"
        fi
        
        # Check configuration file
        if [ -f ".git/git-date-modifier.conf" ]; then
            print_success "Configuration file created"
        else
            print_failure "Configuration file not created"
        fi
    else
        print_failure "Hook installation failed"
    fi
}

# Test 6: Error handling
test_error_handling() {
    print_header "Test 6: Error Handling"
    
    # Test invalid date
    echo "test7" > file7.txt
    git add file7.txt
    git commit --quiet -m "Test commit 7"
    
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
    cd /tmp
    if ./git-date-modifier.sh --date "2024-01-15 14:30:00" --quiet 2>/dev/null; then
        print_failure "Should fail outside git repo"
    else
        print_success "Fails outside git repository"
    fi
    cd "$REPO_DIR"
}

# Test 7: Verbose mode
test_verbose_mode() {
    print_header "Test 7: Verbose Mode"
    
    echo "test8" > file8.txt
    git add file8.txt
    git commit --quiet -m "Test commit 8"
    
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

# Test 9: Hook execution simulation
test_hook_execution() {
    print_header "Test 9: Hook Execution Simulation"
    
    # Create a simple test hook that simulates user input
    cat > test-hook.sh << 'EOF'
#!/bin/bash
# Simulate user choosing to modify date
echo "y"
echo "2024-01-30 15:45:00"
EOF
    chmod +x test-hook.sh
    
    # Create test commit
    echo "test9" > file9.txt
    git add file9.txt
    git commit --quiet -m "Test commit 9"
    
    # The actual hook test would require interactive input
    # For now, we'll test that the hook script exists and is callable
    if [ -f ".git/hooks/pre-push" ]; then
        print_skip "Hook execution test (requires manual testing)"
    else
        print_failure "Hook not installed for execution test"
    fi
}

# Test 10: Performance with multiple commits
test_performance() {
    print_header "Test 10: Performance"
    
    # Create 10 commits
    for i in {1..10}; do
        echo "performance-$i" > "perf-$i.txt"
        git add "perf-$i.txt"
        git commit --quiet -m "Performance commit $i"
    done
    
    start_time=$(date +%s.%N)
    
    # Modify the last commit
    ./git-date-modifier.sh --date "2024-02-01 12:00:00" --quiet
    
    end_time=$(date +%s.%N)
    execution_time=$(echo "$end_time - $start_time" | bc)
    
    if (( $(echo "$execution_time < 2.0" | bc -l) )); then
        print_success "Performance acceptable: ${execution_time}s"
    else
        print_failure "Performance slow: ${execution_time}s"
    fi
    
    # Verify the modification worked
    last_date=$(git log -1 --format="%cd" --date=format:"%Y-%m-%d %H:%M")
    if [ "$last_date" = "2024-02-01 12:00" ]; then
        print_success "Date modification verified"
    else
        print_failure "Date modification not persisted"
    fi
}

# Run all tests
run_all_tests() {
    print_header "Git Date Modifier Test Suite"
    echo "Starting tests at: $(date)"
    echo "Test directory: $TEST_DIR"
    
    setup_test_env
    
    # Run tests
    test_basic_functionality
    test_relative_dates
    test_custom_formats
    test_author_committer_dates
    test_hook_installation
    test_error_handling
    test_verbose_mode
    test_help_usage
    test_hook_execution
    test_performance
    
    # Summary
    print_header "Test Summary"
    echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    echo -e "${YELLOW}Skipped: $SKIP_COUNT${NC}"
    
    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "\n${GREEN}✅ All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}❌ $FAIL_COUNT test(s) failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo "Git Date Modifier Test Suite"
    echo "============================"
    
    if [ ! -f "$SCRIPT_DIR/src/git-date-modifier.sh" ]; then
        echo -e "${RED}Error: Could not find git-date-modifier.sh${NC}"
        echo "Please run from the project root directory"
        exit 1
    fi
    
    if run_all_tests; then
        echo -e "\n${GREEN}Test suite completed successfully!${NC}"
        exit 0
    else
        echo -e "\n${RED}Test suite failed!${NC}"
        exit 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi