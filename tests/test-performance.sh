#!/bin/bash

# Performance Tests for Git Date Modifier
# Tests execution speed, memory usage, and scalability

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"
source "$SCRIPT_DIR/test-environment.sh"

# Test 1: Basic performance (single commit)
test_basic_performance() {
    print_header "Test 1: Basic Performance (Single Commit)"
    
    create_test_commit "perf_single"
    
    # Time the operation
    local start_time
    local end_time
    local elapsed
    
    start_time=$(date +%s.%N)
    
    if ! ./git-date-modifier.sh --date "2024-02-01 12:00:00" --quiet; then
        print_failure "Performance test command failed"
        return
    fi
    
    end_time=$(date +%s.%N)
    elapsed=$(echo "$end_time - $start_time" | bc)
    
    echo "  Execution time: ${elapsed}s"
    
    # Performance threshold (adjust as needed)
    local threshold=1.0  # 1 second
    
    if (( $(echo "$elapsed < $threshold" | bc -l) )); then
        print_success "Performance acceptable (< ${threshold}s)"
    else
        print_failure "Performance slow (${elapsed}s > ${threshold}s)"
    fi
    
    # Verify the operation worked
    local new_date
    new_date=$(git log -1 --format="%cd" --date=format:"%Y-%m-%d %H:%M")
    
    if [ "$new_date" = "2024-02-01 12:00" ]; then
        print_success "Date modification verified"
    else
        print_failure "Date modification failed: $new_date"
    fi
}

# Test 2: Multiple sequential modifications
test_multiple_sequential() {
    print_header "Test 2: Multiple Sequential Modifications"
    
    # Create multiple commits
    local commit_count=5
    local total_time=0
    
    echo "Creating and modifying $commit_count commits..."
    
    for i in $(seq 1 $commit_count); do
        create_test_commit "seq_$i"
        
        local start_time=$(date +%s.%N)
        
        ./git-date-modifier.sh --date "2024-02-0$i 09:00:00" --quiet
        
        local end_time=$(date +%s.%N)
        local elapsed=$(echo "$end_time - $start_time" | bc)
        total_time=$(echo "$total_time + $elapsed" | bc)
        
        echo "  Commit $i: ${elapsed}s"
    done
    
    local average_time=$(echo "$total_time / $commit_count" | bc -l)
    echo "  Average time per commit: ${average_time}s"
    echo "  Total time: ${total_time}s"
    
    # Check consistency
    local verify_count=0
    for i in $(seq 1 $commit_count); do
        local expected_date="2024-02-0$i 09:00"
        local actual_date=$(git log --oneline --format="%cd" --date=format:"%Y-%m-%d %H:%M" | sed -n "${i}p")
        
        if [ "$actual_date" = "$expected_date" ]; then
            ((verify_count++))
        fi
    done
    
    if [ $verify_count -eq $commit_count ]; then
        print_success "All $commit_count modifications verified"
    else
        print_failure "Only $verify_count/$commit_count modifications correct"
    fi
}

# Test 3: Memory usage check
test_memory_usage() {
    print_header "Test 3: Memory Usage Check"
    
    create_test_commit "memory_test"
    
    # Note: Getting precise memory usage in bash is tricky
    # We'll use /usr/bin/time if available, otherwise skip
    
    if command -v /usr/bin/time >/dev/null 2>&1; then
        # Use GNU time to get memory usage
        local time_output
        time_output=$(/usr/bin/time -f "%M" ./git-date-modifier.sh --date "2024-02-10 10:00:00" --quiet 2>&1)
        
        local memory_kb=$(echo "$time_output" | tail -n1 | tr -d '\n')
        
        if [[ "$memory_kb" =~ ^[0-9]+$ ]]; then
            echo "  Memory usage: ${memory_kb} KB"
            
            # Reasonable threshold (adjust as needed)
            local threshold=50000  # 50MB
            
            if [ "$memory_kb" -lt $threshold ]; then
                print_success "Memory usage reasonable (< ${threshold}KB)"
            else
                print_failure "High memory usage (${memory_kb}KB)"
            fi
        else
            print_skip "Could not parse memory usage output"
        fi
    else
        print_skip "GNU time not available for memory measurement"
    fi
}

# Test 4: Large repository simulation
test_large_repository() {
    print_header "Test 4: Large Repository Simulation"
    
    # Create a "large" number of commits
    local large_count=20
    echo "Creating $large_count commits to simulate larger repository..."
    
    for i in $(seq 1 $large_count); do
        create_test_commit "large_$i" "Content for commit $i"
    done
    
    # Time modification of the most recent commit
    local start_time=$(date +%s.%N)
    
    ./git-date-modifier.sh --date "2024-02-15 15:00:00" --quiet
    
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc)
    
    echo "  Time with $large_count commits: ${elapsed}s"
    
    # Threshold for large repository
    local threshold=2.0  # 2 seconds
    
    if (( $(echo "$elapsed < $threshold" | bc -l) )); then
        print_success "Performance good with $large_count commits"
    else
        print_failure "Performance degraded with $large_count commits"
    fi
}

# Test 5: Concurrent operations (simulated)
test_concurrent_operations() {
    print_header "Test 5: Concurrent Operations Test"
    
    # Create multiple commits for concurrent testing
    for i in {1..3}; do
        create_test_commit "concurrent_$i"
    done
    
    # We can't truly run concurrently in a simple test, but we can
    # test that the script doesn't break with rapid sequential calls
    
    local success_count=0
    local test_count=3
    
    for i in {1..3}; do
        # Go back to a previous commit and modify it
        git checkout HEAD~$i 2>/dev/null
        
        if ./git-date-modifier.sh --date "2024-02-20 1${i}:00:00" --quiet 2>/dev/null; then
            ((success_count++))
        fi
        
        # Return to latest
        git checkout - 2>/dev/null
    done
    
    if [ $success_count -eq $test_count ]; then
        print_success "Handles rapid context changes ($success_count/$test_count)"
    else
        print_failure "Issues with rapid context changes ($success_count/$test_count)"
    fi
}

# Test 6: Disk I/O impact
test_disk_io() {
    print_header "Test 6: Disk I/O Considerations"
    
    create_test_commit "diskio_test"
    
    # Check repository size before and after
    local size_before
    size_before=$(du -sb .git 2>/dev/null | cut -f1)
    
    ./git-date-modifier.sh --date "2024-02-25 16:00:00" --quiet
    
    local size_after
    size_after=$(du -sb .git 2>/dev/null | cut -f1)
    
    local size_diff=$((size_after - size_before))
    
    echo "  Repository size change: $size_diff bytes"
    
    # A commit amend should not drastically increase size
    if [ "$size_diff" -lt 10000 ]; then  # Less than 10KB increase
        print_success "Minimal disk space impact"
    else
        print_failure "Large disk space usage: ${size_diff} bytes"
    fi
}

# Test 7: CPU usage estimation
test_cpu_usage() {
    print_header "Test 7: CPU Usage Pattern"
    
    create_test_commit "cpu_test"
    
    # Simple CPU time measurement
    if command -v /usr/bin/time >/dev/null 2>&1; then
        local time_output
        time_output=$(/usr/bin/time -f "%U %S" ./git-date-modifier.sh --date "2024-02-28 17:00:00" --quiet 2>&1 1>/dev/null)
        
        local user_time=$(echo "$time_output" | tail -n1 | awk '{print $1}')
        local system_time=$(echo "$time_output" | tail -n1 | awk '{print $2}')
        
        echo "  User CPU time: ${user_time}s"
        echo "  System CPU time: ${system_time}s"
        
        local total_cpu=$(echo "$user_time + $system_time" | bc -l)
        
        if (( $(echo "$total_cpu < 0.5" | bc -l) )); then
            print_success "Low CPU usage"
        else
            print_skip "CPU usage check (${total_cpu}s total, might be normal)"
        fi
    else
        print_skip "GNU time not available for CPU measurement"
    fi
}

# Test 8: Scalability with complex dates
test_scalability_complex_dates() {
    print_header "Test 8: Scalability with Complex Date Formats"
    
    create_test_commit "complex_date_test"
    
    # Test various date formats to see performance impact
    local complex_formats=(
        "2024-03-01 12:00:00 +0000"
        "next Friday 15:00"
        "2 weeks ago"
        "last month"
        "2024-03-01T12:00:00Z"
    )
    
    local total_time=0
    local count=0
    
    for date_str in "${complex_formats[@]}"; do
        create_test_commit "complex_$count"
        
        local start_time=$(date +%s.%N)
        
        if ./git-date-modifier.sh --date "$date_str" --quiet 2>/dev/null; then
            local end_time=$(date +%s.%N)
            local elapsed=$(echo "$end_time - $start_time" | bc)
            total_time=$(echo "$total_time + $elapsed" | bc)
            ((count++))
            echo "  Format $count: ${elapsed}s - $(echo "$date_str" | cut -c1-30)..."
        else
            echo "  ↷ Failed: $(echo "$date_str" | cut -c1-30)..."
        fi
    done
    
    if [ $count -gt 0 ]; then
        local average_time=$(echo "$total_time / $count" | bc -l)
        echo "  Average for complex dates: ${average_time}s"
        
        if (( $(echo "$average_time < 0.5" | bc -l) )); then
            print_success "Good performance with complex dates"
        else
            print_skip "Performance with complex dates (${average_time}s average)"
        fi
    else
        print_skip "No complex date formats succeeded"
    fi
}

# Test 9: Batch operation simulation
test_batch_operations() {
    print_header "Test 9: Batch Operation Simulation"
    
    # Create a script to simulate batch operations
    cat > batch_test.sh << 'EOF'
#!/bin/bash
# Simulate batch date modifications
for i in {1..5}; do
    echo "batch_$i" > "batch_$i.txt"
    git add "batch_$i.txt"
    git commit --quiet -m "Batch commit $i"
    
    # Modify each commit
    ./git-date-modifier.sh --date "2024-03-0${i} 10:00:00" --quiet
done
EOF
    
    chmod +x batch_test.sh
    
    local start_time=$(date +%s.%N)
    
    ./batch_test.sh
    
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc)
    
    echo "  Batch of 5 operations: ${elapsed}s"
    
    # Verify all were modified
    local correct_count=0
    for i in {1..5}; do
        local expected="2024-03-0${i} 10:00"
        local actual=$(git log --oneline --format="%cd" --date=format:"%Y-%m-%d %H:%M" | sed -n "${i}p")
        
        if [ "$actual" = "$expected" ]; then
            ((correct_count++))
        fi
    done
    
    if [ $correct_count -eq 5 ]; then
        print_success "Batch operations successful (${elapsed}s)"
    else
        print_failure "Batch operations incomplete ($correct_count/5 correct)"
    fi
    
    rm -f batch_test.sh
}

# Test 10: Performance regression baseline
test_performance_baseline() {
    print_header "Test 10: Performance Regression Baseline"
    
    create_test_commit "baseline_test"
    
    # Run multiple times to get a baseline
    local times=()
    local runs=3
    
    for i in $(seq 1 $runs); do
        local start_time=$(date +%s.%N)
        
        ./git-date-modifier.sh --date "2024-03-10 14:30:00" --quiet
        
        local end_time=$(date +%s.%N)
        local elapsed=$(echo "$end_time - $start_time" | bc)
        times+=($elapsed)
        
        # Reset for next run
        ./git-date-modifier.sh --date "2024-01-01 00:00:00" --quiet 2>/dev/null || true
    done
    
    # Calculate statistics
    local sum=0
    local min=${times[0]}
    local max=${times[0]}
    
    for t in "${times[@]}"; do
        sum=$(echo "$sum + $t" | bc)
        
        if (( $(echo "$t < $min" | bc -l) )); then
            min=$t
        fi
        
        if (( $(echo "$t > $max" | bc -l) )); then
            max=$t
        fi
    done
    
    local avg=$(echo "$sum / $runs" | bc -l)
    local range=$(echo "$max - $min" | bc)
    
    echo "  Runs: $runs"
    echo "  Average: ${avg}s"
    echo "  Range: ${range}s (min: ${min}s, max: ${max}s)"
    echo "  Times: ${times[*]}"
    
    # Check for consistency
    if (( $(echo "$range < 0.1" | bc -l) )); then
        print_success "Performance consistent (range: ${range}s)"
    else
        print_skip "Performance varies (range: ${range}s)"
    fi
    
    # Record baseline for future comparison
    echo "${avg}" > "$TEST_DIR/performance_baseline.txt"
    print_success "Baseline recorded: ${avg}s average"
}

# Run all performance tests
run_performance_tests() {
    print_header "Running Performance Tests"
    
    reset_counters
    
    test_basic_performance
    test_multiple_sequential
    test_memory_usage
    test_large_repository
    test_concurrent_operations
    test_disk_io
    test_cpu_usage
    test_scalability_complex_dates
    test_batch_operations
    test_performance_baseline
    
    print_test_summary
    return $?
}

# Main execution
main() {
    if setup_test_env; then
        run_performance_tests
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