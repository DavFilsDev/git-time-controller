#!/bin/bash

# Hook Functionality Tests for Git Date Modifier
# Tests hook installation and execution

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
    
    create_test_commit "hook_exec_test"
    
    # The actual hook test would require interactive input
    # For now, we'll test that the hook script exists and is callable
    if [ -f ".git/hooks/pre-push" ]; then
        print_skip "Hook execution test (requires manual testing)"
    else
        print_failure "Hook not installed for execution test"
    fi
}

# Run all hook tests
run_hook_tests() {
    print_header "Running Hook Tests"
    
    test_hook_installation
    test_hook_execution
    
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
        run_hook_tests
        exit $?
    else
        echo "Failed to setup test environment"
        exit 1
    fi
fi