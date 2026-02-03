#!/bin/bash

# Git Date Modifier - Main Test Orchestrator
# Run all test modules

set -e

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"

# Test modules to run (in order)
TEST_MODULES=(
    "test-core-functionality.sh"
    "test-hooks.sh"
    "test-error-handling.sh"
    "test-ui-output.sh"
    "test-performance.sh"
)

# Run all tests
run_all_tests() {
    print_header "Git Date Modifier Test Suite"
    echo "Starting tests at: $(date)"
    echo "Project directory: $(cd "$SCRIPT_DIR/.." && pwd)"
    echo ""
    
    local total_passed=0
    local total_failed=0
    local total_skipped=0
    local module_count=0
    
    # Run each test module
    for module in "${TEST_MODULES[@]}"; do
        module_path="$SCRIPT_DIR/$module"
        
        if [ ! -f "$module_path" ]; then
            echo -e "${YELLOW}Warning: Test module $module not found${NC}"
            continue
        fi
        
        ((module_count++))
        
        echo -e "${BLUE}=== Running $(basename "$module" .sh) ===${NC}"
        
        # Run the module
        if bash "$module_path"; then
            module_result=0
        else
            module_result=$?
        fi
        
        # Accumulate results
        total_passed=$((total_passed + PASS_COUNT))
        total_failed=$((total_failed + FAIL_COUNT))
        total_skipped=$((total_skipped + SKIP_COUNT))
        
        # Reset counters for next module
        reset_counters
        
        echo ""
    done
    
    # Final summary
    echo ""
    print_header "Overall Test Summary"
    echo "Modules executed: $module_count"
    echo -e "${GREEN}Total Passed: $total_passed${NC}"
    echo -e "${RED}Total Failed: $total_failed${NC}"
    echo -e "${YELLOW}Total Skipped: $total_skipped${NC}"
    
    if [ $total_failed -eq 0 ]; then
        echo -e "\n${GREEN}✅ All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}❌ $total_failed test(s) failed${NC}"
        return 1
    fi
}

# Show help
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --list, -l     List all test modules"
    echo ""
    echo "This script runs all test modules in sequence."
    echo ""
    echo "To run individual modules:"
    for module in "${TEST_MODULES[@]}"; do
        echo "  ./$(basename "$module")"
    done
}

# List modules
list_modules() {
    echo "Available test modules:"
    echo ""
    for module in "${TEST_MODULES[@]}"; do
        echo "  $(basename "$module" .sh)"
    done
}

# Main execution
main() {
    # Parse command line arguments
    if [ $# -gt 0 ]; then
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --list|-l)
                list_modules
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    fi
    
    run_all_tests
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi