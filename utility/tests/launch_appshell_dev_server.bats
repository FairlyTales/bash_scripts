#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_environment
    
    # Mock the directory paths to use our test environment
    export ORIGINAL_PWD="$(pwd)"
}

teardown() {
    teardown_utility_tests
    cd "$ORIGINAL_PWD" 2>/dev/null || true
}

@test "launches appshell when port 3000 is free" {
    # No existing process on port 3000
    
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    assert_output --partial "Launching MySky AppShell on port 3000..."
    
    # Verify lsof was called to check port 3000
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3000 -sTCP:LISTEN -t"
    
    # Verify yarn start was called
    assert_mock_called_with "$TEST_TEMP_DIR/yarn_calls.log" "yarn start"
    
    # Should not call kill since no process exists
    assert_no_mock_calls "$TEST_TEMP_DIR/kill_calls.log"
}

@test "terminates existing process before launching" {
    # Create existing process on port 3000
    create_mock_process "3000" "12345"
    
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3000..."
    assert_output --partial "Process on port 3000 terminated"
    assert_output --partial "Launching MySky AppShell on port 3000..."
    
    # Verify process was killed with SIGTERM
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 12345"
    
    # Verify yarn start was called
    assert_mock_called_with "$TEST_TEMP_DIR/yarn_calls.log" "yarn start"
}

@test "waits for process termination before launching" {
    # Create mock process that takes time to terminate
    create_mock_process "3000" "12345"
    
    # The script uses "until kill -s 0" to wait for process termination
    # Our mock will simulate this by removing the process file
    
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    
    # Verify it checked if process still exists (kill -s 0)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 12345"
}

@test "handles multiple processes on port 3000" {
    # Create multiple processes (though script only handles first)
    echo -e "12345\n67890" > "$TEST_TEMP_DIR/mock_process_3000"
    echo "active" > "$TEST_TEMP_DIR/mock_process_by_pid_12345"
    
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3000..."
    
    # Should terminate the first PID found
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 12345"
}

@test "navigates to correct appshell directory" {
    # The script has a hardcoded path: /Users/user/Mysky/projects/app_shell
    # We'll verify it calls yarn from the right context
    
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    
    # Check that yarn was called and verify the working directory in the mock
    assert_mock_called_with "$TEST_TEMP_DIR/yarn_calls.log" "yarn start (pwd: /Users/user/Mysky/projects/app_shell)"
}

@test "uses specific lsof command format for listening processes" {
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    
    # Verify the exact lsof command format used in the script
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3000 -sTCP:LISTEN -t"
}

@test "uses SIGTERM for graceful process termination" {
    create_mock_process "3000" "99999"
    
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    
    # Verify it uses SIGTERM (-15) not SIGKILL (-9)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 99999"
    
    # Ensure SIGKILL is not used
    if grep -q "kill -9" "$TEST_TEMP_DIR/kill_calls.log" 2>/dev/null; then
        fail "Script should use SIGTERM (-15) for graceful termination"
    fi
}

@test "handles case when process terminates quickly" {
    # Create process that terminates immediately
    create_mock_process "3000" "77777"
    # Don't create the by_pid file, simulating quick termination
    
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3000..."
    
    # Should still attempt to kill
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 77777"
}

@test "executes yarn start command" {
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    
    # Verify yarn start was executed
    assert_mock_called_with "$TEST_TEMP_DIR/yarn_calls.log" "yarn start"
    
    # Verify no other yarn commands were called
    local yarn_call_count=$(grep -c "yarn" "$TEST_TEMP_DIR/yarn_calls.log" 2>/dev/null || echo "0")
    [ "$yarn_call_count" -eq 1 ] || fail "Expected exactly one yarn call, got $yarn_call_count"
}

@test "provides informative output messages" {
    create_mock_process "3000" "55555"
    
    run "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    assert_success
    
    # Check for expected output messages in correct order
    assert_output --partial "Terminating current process on port 3000..."
    assert_output --partial "Process on port 3000 terminated"
    assert_output --partial "Launching MySky AppShell on port 3000..."
}