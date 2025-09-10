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
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    assert_output --partial "No processes are running on port 3000 and 3001"
    
    # Verify lsof was called for both ports
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3000 -sTCP:LISTEN -t"
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3001 -sTCP:LISTEN -t"
    
    # No kill calls should be made
    assert_no_mock_calls "$TEST_TEMP_DIR/kill_calls.log"
}

@test "terminates process on port 3000 only with SIGKILL" {
    # Create process only on port 3000
    create_mock_process "3000" "12345"
    
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3000..."
    assert_output --partial "Process on port 3000 terminated"
    
    # Should not mention port 3001 termination
    refute_output --partial "Terminating current process on port 3001..."
    
    # Verify SIGKILL (-9) was used
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 12345"
}

@test "terminates process on port 3001 only with SIGKILL" {
    # Create process only on port 3001
    create_mock_process "3001" "23456"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3001..."
    assert_output --partial "Process on port 3001 terminated"
    
    # Should not mention port 3000 termination
    refute_output --partial "Terminating current process on port 3000..."
    
    # Verify SIGKILL (-9) was used
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 23456"
}

@test "terminates processes on both ports with SIGKILL" {
    # Create processes on both ports
    create_mock_process "3000" "12345"
    create_mock_process "3001" "23456"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    assert_output --partial "Terminating current process on port 3000..."
    assert_output --partial "Process on port 3000 terminated"
    assert_output --partial "Terminating current process on port 3001..."
    assert_output --partial "Process on port 3001 terminated"
    
    # Verify both kill commands use SIGKILL
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 12345"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 23456"
}

@test "waits for port 3000 process termination" {
    create_mock_process "3000" "12345"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Verify it checked if process still exists (kill -s 0)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 12345"
}

@test "waits for port 3001 process termination" {
    create_mock_process "3001" "23456"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Verify it checked if process still exists (kill -s 0)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 23456"
}

@test "uses SIGKILL for immediate termination" {
    create_mock_process "3000" "11111"
    create_mock_process "3001" "22222"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Verify both processes killed with SIGKILL (-9)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 11111"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 22222"
    
    # Ensure SIGTERM is not used
    if grep -q "kill -15" "$TEST_TEMP_DIR/kill_calls.log" 2>/dev/null; then
        fail "Script should use SIGKILL (-9), not SIGTERM (-15)"
    fi
}

@test "provides informative startup message" {
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    assert_output --partial "Attempting to terminate:"
    assert_output --partial "MySky AppShell on port 3000..."
    assert_output --partial "MySky Spend on port 3001..."
}

@test "handles multiple processes on port 3000" {
    # Create multiple PIDs for port 3000
    echo -e "12345\n67890" > "$TEST_TEMP_DIR/mock_process_3000"
    echo "active" > "$TEST_TEMP_DIR/mock_process_by_pid_12345"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Should terminate the first PID found with SIGKILL
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 12345"
}

@test "handles multiple processes on port 3001" {
    # Create multiple PIDs for port 3001
    echo -e "33333\n44444" > "$TEST_TEMP_DIR/mock_process_3001"
    echo "active" > "$TEST_TEMP_DIR/mock_process_by_pid_33333"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Should terminate the first PID found with SIGKILL
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 33333"
}

@test "uses correct lsof command format" {
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Verify the exact lsof command format for both ports
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3000 -sTCP:LISTEN -t"
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3001 -sTCP:LISTEN -t"
}

@test "processes are handled independently" {
    # Create only port 3000 process
    create_mock_process "3000" "55555"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Should terminate port 3000 process with SIGKILL
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 55555"
    
    # Should still check for port 3001 but not try to kill anything
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -Pi :3001 -sTCP:LISTEN -t"
    
    # Verify only one kill command was issued
    local kill_count=$(grep -c "kill -9" "$TEST_TEMP_DIR/kill_calls.log" 2>/dev/null || echo "0")
    [ "$kill_count" -eq 1 ] || fail "Expected exactly one kill -9 call, got $kill_count"
}

@test "handles process termination sequence correctly" {
    create_mock_process "3000" "77777"
    create_mock_process "3001" "88888"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Verify the sequence: terminate with SIGKILL, then wait for termination
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 77777"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 77777"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 88888"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -s 0 88888"
}

@test "difference from soft kill - uses SIGKILL instead of SIGTERM" {
    create_mock_process "3000" "99999"
    create_mock_process "3001" "88888"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # This test specifically verifies the "hard" behavior
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 99999"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 88888"
    
    # Verify output messages are the same as the soft version
    assert_output --partial "Process on port 3000 terminated"
    assert_output --partial "Process on port 3001 terminated"
}

@test "provides same user interface as soft version but with immediate termination" {
    create_mock_process "3000" "12121"
    
    run "$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers_hard.sh"
    
    assert_success
    
    # Same UI messages as soft version
    assert_output --partial "Attempting to terminate:"
    assert_output --partial "MySky AppShell on port 3000..."
    assert_output --partial "Terminating current process on port 3000..."
    assert_output --partial "Process on port 3000 terminated"
    
    # But uses SIGKILL instead
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -9 12121"
}