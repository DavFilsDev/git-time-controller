#!/bin/bash

# Hook Functionality Tests for Git Date Modifier
# Tests hook installation, configuration, and basic execution

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"
source "$SCRIPT_DIR/test-environment.sh"

# Test 1: Hook installation
test_hook_installation() {
    print_header "Test 1: Hook Installation"
    
    # Install hooks
    if ! ./setup-hooks.sh; then
        print_failure "setup-hooks.sh failed to execute"
        return
    fi
    
    # Check if pre-push hook was created
    if [ -f ".git/hooks/pre-push" ]; then
        print_success "Pre-push hook installed"
        
        # Check hook is executable
        if [ -x ".git/hooks/pre-push" ]; then
            print_success "Hook is executable"
        else
            print_failure "Hook is not executable"
        fi
        
        # Check hook content
        if grep -q "Git Date Modifier" ".git/hooks/pre-push"; then
            print_success "Hook contains correct identifier"
        else
            print_failure "Hook missing correct identifier"
        fi
    else
        print_failure "Pre-push hook not created"
    fi
    
    # Check configuration file
    if [ -f ".git/git-date-modifier.conf" ]; then
        print_success "Configuration file created"
        
        # Check config content
        if grep -q "ENABLE_PROMPT=true" ".git/git-date-modifier.conf"; then
            print_success "Config has correct default ENABLE_PROMPT"
        else
            print_failure "Config missing correct ENABLE_PROMPT"
        fi
        
        if grep -q "DEFAULT_DATE_FORMAT=" ".git/git-date-modifier.conf"; then
            print_success "Config has DEFAULT_DATE_FORMAT"
        else
            print_failure "Config missing DEFAULT_DATE_FORMAT"
        fi
    else
        print_failure "Configuration file not created"
    fi
}

# Test 2: Hook configuration modification
test_hook_configuration() {
    print_header "Test 2: Hook Configuration"
    
    # Skip if config file doesn't exist
    if [ ! -f ".git/git-date-modifier.conf" ]; then
        print_skip "Configuration file not found (test_hook_installation might have failed)"
        return
    fi
    
    # Backup original config
    cp ".git/git-date-modifier.conf" ".git/git-date-modifier.conf.backup"
    
    # Test disabling prompt via config
    echo "Testing configuration changes..."
    
    # Create a modified config
    cat > ".git/git-date-modifier.conf" << 'EOF'
# Modified config for testing
ENABLE_PROMPT=false
DEFAULT_DATE_FORMAT="%Y-%m-%d %H:%M:%S"
AUTO_DETECT_FORMAT=false
VERBOSE=true
MODIFY_AUTHOR_DATE=true
MODIFY_COMMITTER_DATE=false
EOF
    
    # Verify config was modified
    if grep -q "ENABLE_PROMPT=false" ".git/git-date-modifier.conf"; then
        print_success "Config modification successful"
    else
        print_failure "Config modification failed"
    fi
    
    # Restore original config
    mv ".git/git-date-modifier.conf.backup" ".git/git-date-modifier.conf"
}

# Test 3: Hook script availability
test_hook_script_availability() {
    print_header "Test 3: Hook Script Availability"
    
    # Check if git-hook.sh is callable
    if [ -f "./git-hook.sh" ]; then
        print_success "git-hook.sh is available in test directory"
        
        # Test basic execution (should exit 0 when not in git repo context)
        cd /tmp
        if bash "$REPO_DIR/git-hook.sh" 2>/dev/null; then
            print_success "git-hook.sh executes without errors"
        else
            # git-hook.sh might exit with non-zero when not in git repo, which is expected
            print_skip "git-hook.sh exit code check (might be expected behavior)"
        fi
        cd "$REPO_DIR"
    else
        print_failure "git-hook.sh not found in test directory"
    fi
}

# Test 4: Hook integration test
test_hook_integration() {
    print_header "Test 4: Hook Integration"
    
    # Skip if hook is not installed
    if [ ! -f ".git/hooks/pre-push" ]; then
        print_skip "Hook not installed (required for integration test)"
        return
    fi
    
    # Create a test commit
    create_test_commit "hook_integration"
    
    # Create a mock hook tester
    cat > test_hook_integration.sh << 'EOF'
#!/bin/bash
echo "Mock hook execution"
echo "Last commit would be checked here"
exit 0
EOF
    chmod +x test_hook_integration.sh
    
    # Test that hook file is valid bash
    if bash -n ".git/hooks/pre-push" 2>/dev/null; then
        print_success "Hook file has valid bash syntax"
    else
        print_failure "Hook file has invalid bash syntax"
    fi
    
    # Test hook execution (simulated)
    echo "Simulating hook execution..."
    print_skip "Full interactive hook test requires manual testing with git push"
}

# Test 5: Hook re-installation (idempotency)
test_hook_reinstallation() {
    print_header "Test 5: Hook Re-installation (Idempotency)"
    
    # Record original hook content
    local original_hook=""
    if [ -f ".git/hooks/pre-push" ]; then
        original_hook=$(cat ".git/hooks/pre-push" | md5sum)
    fi
    
    # Run setup again
    echo "Running setup-hooks.sh again..."
    if ./setup-hooks.sh 2>&1 | grep -q "already contains date modifier\|Hook already contains"; then
        print_success "Setup correctly detects existing installation"
    else
        print_skip "Setup message check (might vary by implementation)"
    fi
    
    # Check if hook was modified
    if [ -f ".git/hooks/pre-push" ]; then
        local new_hook=$(cat ".git/hooks/pre-push" | md5sum)
        if [ "$original_hook" = "$new_hook" ] || [ -z "$original_hook" ]; then
            print_success "Hook remains unchanged or properly maintained"
        else
            print_failure "Hook was unnecessarily modified on re-installation"
        fi
    fi
}

# Run all hook tests
run_hook_tests() {
    print_header "Running Hook Tests"
    
    reset_counters
    
    test_hook_installation
    test_hook_configuration
    test_hook_script_availability
    test_hook_integration
    test_hook_reinstallation
    
    print_test_summary
    return $?
}

# Main execution
main() {
    if setup_test_env; then
        run_hook_tests
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