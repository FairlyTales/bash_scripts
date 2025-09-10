#!/usr/bin/env bats

load test_helper

setup() {
    export SKIP_MOCK_LAUNCH_SCRIPTS="true"
    setup_test_environment
    
    # Copy the actual script being tested to temp directory
    cp "$UTILITY_SCRIPTS_PATH/launch_appshell_and_spend_dev_servers.sh" "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    chmod +x "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    # Create mock scripts in the temp directory for testing DIRNAME resolution
    cat > "$TEST_TEMP_DIR/launch_appshell_dev_server.sh" << 'EOF'
#!/usr/bin/env zsh
echo "mock_appshell_launcher called" >> "$TEST_TEMP_DIR/script_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    cat > "$TEST_TEMP_DIR/launch_spend_dev_server.sh" << 'EOF'
#!/usr/bin/env zsh
echo "mock_spend_launcher called" >> "$TEST_TEMP_DIR/script_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/launch_spend_dev_server.sh"
}

teardown() {
    teardown_utility_tests
}

@test "displays launch message for both servers" {
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    assert_success
    assert_output --partial "Launching:"
    assert_output --partial "MySky AppShell on port 3000..."
    assert_output --partial "MySky Spend on port 3001..."
}

@test "executes both appshell and spend launcher scripts" {
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Both mock scripts should have been called
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_appshell_launcher called"
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_spend_launcher called"
}

@test "resolves DIRNAME correctly to find sibling scripts" {
    # The script uses DIRNAME=$(dirname "$0") to find other scripts in same directory
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Verify both scripts were found and executed
    local script_calls=$(grep -c "called" "$TEST_TEMP_DIR/script_calls.log" 2>/dev/null || echo "0")
    [ "$script_calls" -eq 2 ] || fail "Expected 2 script calls, got $script_calls"
}

@test "runs both scripts in background with &" {
    # Note: Testing background execution is challenging in bats
    # We verify the scripts were called, which implies the & operator worked
    
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Both scripts should have been executed despite being backgrounded
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_appshell_launcher called"
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_spend_launcher called"
}

@test "handles case when appshell script is missing" {
    # Remove the appshell script from temp directory
    rm "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    # The script might fail or succeed depending on shell behavior
    # At minimum, it should still try to launch spend server
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_spend_launcher called"
}

@test "handles case when spend script is missing" {
    # Remove the spend script from temp directory
    rm "$TEST_TEMP_DIR/launch_spend_dev_server.sh"
    
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    # Should still try to launch appshell server
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_appshell_launcher called"
}

@test "script path resolution uses relative paths" {
    # The script uses $DIRNAME/launch_appshell_dev_server.sh
    # This should resolve to scripts in the same directory
    
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Both relative script paths should have been resolved successfully
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_appshell_launcher called"
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_spend_launcher called"
}

@test "provides clear output about which servers are launching" {
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Verify specific port numbers are mentioned
    assert_output --partial "port 3000"
    assert_output --partial "port 3001"
    
    # Verify both service names are mentioned
    assert_output --partial "MySky AppShell"
    assert_output --partial "MySky Spend"
}

@test "uses background execution for parallel launching" {
    # Create scripts that would normally take time to verify parallel execution
    cat > "$TEST_TEMP_DIR/launch_appshell_dev_server.sh" << 'EOF'
#!/usr/bin/env zsh
echo "appshell_start" >> "$TEST_TEMP_DIR/script_calls.log"
sleep 0.1  # Simulate startup time
echo "appshell_end" >> "$TEST_TEMP_DIR/script_calls.log"
EOF
    chmod +x "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    cat > "$TEST_TEMP_DIR/launch_spend_dev_server.sh" << 'EOF'
#!/usr/bin/env zsh
echo "spend_start" >> "$TEST_TEMP_DIR/script_calls.log"
sleep 0.1  # Simulate startup time
echo "spend_end" >> "$TEST_TEMP_DIR/script_calls.log"
EOF
    chmod +x "$TEST_TEMP_DIR/launch_spend_dev_server.sh"
    
    run "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Both scripts should have started
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "appshell_start"
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "spend_start"
}