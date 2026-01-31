#!/bin/bash

# Git Date Modifier Test Suite Runner
# Orchestrates all modular tests

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
    
    # Source environment setup
    source "$SCRIPT_DIR/test-environment.sh"
    
    if ! setup_test_env; then
        echo -e "${RED}Failed to setup test environment${NC}"
        return 1
    fi
    
    local total_passed=0
    local total_failed=0
    local total_skipped=0
    
    # Run each test module
    for module in "${TEST_MODULES[@]}"; do
        module_path="$SCRIPT_DIR/$module"
        
        if [ ! -f "$module_path" ]; then
            echo -e "${YELLOW}Warning: Test module $module not found${NC}"
            continue
        fi
        
        echo -e "\n${BLUE}=== Running $module ===${NC}"
        
        # Reset counters for this module
        reset_counters
        
        # Run the module
        if bash "$module_path"; then
            echo -e "${GREEN}✓ $module completed successfully${NC}"
        else
            echo -e "${RED}✗ $module failed${NC}"
        fi
        
        # Accumulate results
        total_passed=$((total_passed + PASS_COUNT))
        total_failed=$((total_failed + FAIL_COUNT))
        total_skipped=$((total_skipped + SKIP_COUNT))
    done
    
    # Final summary
    print_header "Overall Test Summary"
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

# Run individual test module
run_test_module() {
    local module="$1"
    local module_path="$SCRIPT_DIR/$module"
    
    if [ ! -f "$module_path" ]; then
        echo -e "${RED}Error: Test module $module not found${NC}"
        return 1
    fi
    
    source "$SCRIPT_DIR/test-environment.sh"
    
    if ! setup_test_env; then
        echo -e "${RED}Failed to setup test environment${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Running $module ===${NC}"
    bash "$module_path"
}

# Main execution
main() {
    echo "Git Date Modifier Test Suite Runner"
    echo "==================================="
    
    # Check if we're in the project root
    if [ ! -f "../src/git-date-modifier.sh" ] && [ ! -f "./src/git-date-modifier.sh" ]; then
        echo -e "${RED}Error: Could not find git-date-modifier.sh${NC}"
        echo "Please run from the project root directory or tests/ directory"
        exit 1
    fi
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        # Run all tests
        run_all_tests
        exit $?
    else
        case "$1" in
            --module|-m)
                if [ -z "$2" ]; then
                    echo "Usage: $0 --module <module-name>"
                    echo "Available modules:"
                    for module in "${TEST_MODULES[@]}"; do
                        echo "  - ${module%.sh}"
                    done
                    exit 1
                fi
                run_test_module "$2.sh"
                exit $?
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --module, -m <name>  Run specific test module"
                echo "  --help, -h           Show this help message"
                echo ""
                echo "Available test modules:"
                for module in "${TEST_MODULES[@]}"; do
                    echo "  ${module%.sh}"
                done
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi