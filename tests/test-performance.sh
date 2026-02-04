#!/bin/bash

# Performance Tests for Git Date Modifier
# Tests execution speed and resource usage

# Test 10: Performance with multiple commits
test_performance() {
    print_header "Test 10: Performance"
    
    # Create 10 commits
    for i in {1..10}; do
        create_test_commit "perf_$i"
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

# Run performance tests
run_performance_tests() {
    print_header "Running Performance Tests"
    
    test_performance
    
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
        run_performance_tests
        exit $?
    else
        echo "Failed to setup test environment"
        exit 1
    fi
fi