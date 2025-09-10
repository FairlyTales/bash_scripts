#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_environment
}

teardown() {
    teardown_utility_tests
}

@test "reports no processes when both ports are empty" {
    # No processes on either port
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    assert_output --partial "No processes are running on port 3000 and 3001"
    
    # Verify lsof was called for both ports
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3000 -sTCP:LISTEN -t"
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3001 -sTCP:LISTEN -t"
    
    # No kill calls should be made
    assert_no_mock_calls "$TEST_TEMP_DIR/kill_calls.log"
}

@test "terminates process on port 3000 only" {
    # Create process only on port 3000
    create_mock_process "3000" "12345"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3000..."
    assert_output --partial "Process on port 3000 terminated"
    
    # Should not mention port 3001 termination
    refute_output --partial "Terminating current process on port 3001..."
    
    # Verify correct kill command
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 12345"
}

@test "terminates process on port 3001 only" {
    # Create process only on port 3001
    create_mock_process "3001" "23456"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3001..."
    assert_output --partial "Process on port 3001 terminated"
    
    # Should not mention port 3000 termination
    refute_output --partial "Terminating current process on port 3000..."
    
    # Verify correct kill command
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 23456"
}

@test "terminates processes on both ports" {
    # Create processes on both ports
    create_mock_process "3000" "12345"
    create_mock_process "3001" "23456"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3000..."
    assert_output --partial "Process on port 3000 terminated"
    assert_output --partial "Terminating current process on port 3001..."
    assert_output --partial "Process on port 3001 terminated"
    
    # Verify both kill commands
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 12345"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 23456"
}

@test "waits for port 3000 process termination" {
    create_mock_process "3000" "12345"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Verify it checked if process still exists (kill -s 0)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 12345"
}

@test "waits for port 3001 process termination" {
    create_mock_process "3001" "23456"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Verify it checked if process still exists (kill -s 0)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 23456"
}

@test "uses SIGTERM for graceful termination" {
    create_mock_process "3000" "11111"
    create_mock_process "3001" "22222"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Verify both processes killed with SIGTERM (-15)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 11111"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 22222"
    
    # Ensure SIGKILL is not used
    if grep -q "kill -9" "$TEST_TEMP_DIR/kill_calls.log" 2>/dev/null; then
        fail "Script should use SIGTERM (-15), not SIGKILL (-9)"
    fi
}

@test "provides informative startup message" {
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    assert_output --partial "Attempting to terminate:"
    assert_output --partial "MySky AppShell on port 3000..."
    assert_output --partial "MySky Spend on port 3001..."
}

@test "handles multiple processes on port 3000" {
    # Create multiple PIDs for port 3000
    echo -e "12345\n67890" > "$TEST_TEMP_DIR/mock_process_3000"
    echo "active" > "$TEST_TEMP_DIR/mock_process_by_pid_12345"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Should terminate the first PID found
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 12345"
}

@test "handles multiple processes on port 3001" {
    # Create multiple PIDs for port 3001
    echo -e "33333\n44444" > "$TEST_TEMP_DIR/mock_process_3001"
    echo "active" > "$TEST_TEMP_DIR/mock_process_by_pid_33333"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Should terminate the first PID found
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 33333"
}

@test "uses correct lsof command format" {
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Verify the exact lsof command format for both ports
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3000 -sTCP:LISTEN -t"
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3001 -sTCP:LISTEN -t"
}

@test "processes are handled independently" {
    # Create only port 3000 process
    create_mock_process "3000" "55555"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Should terminate port 3000 process
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 55555"
    
    # Should still check for port 3001 but not try to kill anything
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3001 -sTCP:LISTEN -t"
    
    # Verify only one kill command was issued
    local kill_count=$(grep -c "kill -15" "$TEST_TEMP_DIR/kill_calls.log" 2>/dev/null || echo "0")
    [ "$kill_count" -eq 1 ] || fail "Expected exactly one kill -15 call, got $kill_count"
}

@test "handles process termination sequence correctly" {
    create_mock_process "3000" "77777"
    create_mock_process "3001" "88888"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
    
    assert_success
    
    # Verify the sequence: terminate, then wait for termination
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 77777"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 77777"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 88888"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 88888"
}