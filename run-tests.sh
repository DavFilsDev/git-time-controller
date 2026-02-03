#!/bin/bash

# Git Date Modifier - Main Test Runner
# Run this from the project root directory

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Git Date Modifier Test Suite${NC}"
echo "=================================="
echo ""

# Check if we're in the project root
check_project_root() {
    if [ -f "./src/git-date-modifier.sh" ] && [ -d "./tests" ]; then
        return 0
    else
        echo -e "${RED}Error: Not in project root directory${NC}"
        echo "Please run this script from the project root where src/ and tests/ directories exist."
        echo ""
        echo "Current directory: $(pwd)"
        echo "Expected files:"
        echo "  - ./src/git-date-modifier.sh"
        echo "  - ./tests/"
        return 1
    fi
}

# Make all scripts executable
make_executable() {
    echo -e "${BLUE}Setting executable permissions...${NC}"
    chmod +x src/*.sh tests/*.sh 2>/dev/null || true
}

# Run all tests
run_all() {
    echo -e "${BLUE}Running all tests...${NC}"
    cd tests && ./run-all-tests.sh
}

# Run specific test module
run_module() {
    local module="$1"
    echo -e "${BLUE}Running $module tests...${NC}"
    
    if [ ! -f "tests/$module.sh" ]; then
        echo -e "${RED}Error: Test module '$module' not found${NC}"
        echo "Available modules:"
        ls tests/test-*.sh | sed 's|tests/test-||;s|\.sh||' | sort
        return 1
    fi
    
    cd tests && ./$module.sh
}

# Show help
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  all               Run all tests (default)"
    echo "  core              Run core functionality tests"
    echo "  hooks             Run hook installation tests"
    echo "  errors            Run error handling tests"
    echo "  ui                Run UI/output tests"
    echo "  performance       Run performance tests"
    echo "  list              List all available test modules"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                # Run all tests"
    echo "  $0 core           # Run only core tests"
    echo "  $0 hooks ui       # Run hooks and UI tests"
}

# List available modules
list_modules() {
    echo -e "${BLUE}Available test modules:${NC}"
    echo ""
    for module in tests/test-*.sh; do
        module_name=$(basename "$module" .sh | sed 's/test-//')
        echo "  $module_name"
    done
    echo ""
    echo "Run: $0 <module-name>"
    echo "Run: $0 all (for all tests)"
}

# Main execution
main() {
    # Check project root first
    if ! check_project_root; then
        exit 1
    fi
    
    # Make scripts executable
    make_executable
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        # Default: run all tests
        run_all
    else
        case "$1" in
            all)
                run_all
                ;;
            list)
                list_modules
                ;;
            help|--help|-h)
                show_help
                ;;
            *)
                # Check if it's a valid module
                if [ -f "tests/test-$1.sh" ]; then
                    run_module "test-$1.sh"
                else
                    # Try to run multiple modules
                    all_valid=true
                    for module in "$@"; do
                        if [ ! -f "tests/test-$module.sh" ]; then
                            echo -e "${RED}Error: Unknown test module '$module'${NC}"
                            all_valid=false
                        fi
                    done
                    
                    if [ "$all_valid" = true ]; then
                        for module in "$@"; do
                            run_module "test-$module.sh"
                        done
                    else
                        show_help
                        exit 1
                    fi
                fi
                ;;
        esac
    fi
}

# Run main function
main "$@"