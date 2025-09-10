#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_environment
}

teardown() {
    teardown_utility_tests
}

@test "terminates process on specified port successfully" {
    # Create a mock process on port 3000
    create_mock_process "3000" "12345"
    
    run "$UTILITY_SCRIPTS_PATH/killport.sh" 3000
    
    assert_success
    assert_output --partial "Process on port 3000 terminated"
    
    # Verify lsof was called to find the process
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -ti:3000"
    
    # Verify kill was called with SIGTERM (-15)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 12345"
}

@test "reports no process when port is empty" {
    # Don't create any mock process
    
    run "$UTILITY_SCRIPTS_PATH/killport.sh" 8080
    
    assert_success
    assert_output --partial "No process on port 8080"
    
    # Verify lsof was called
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -ti:8080"
    
    # Verify kill was not called
    assert_no_mock_calls "$TEST_TEMP_DIR/kill_calls.log"
}

@test "handles multiple processes on same port" {
    # Create multiple PIDs for the same port (simulate multiple processes)
    echo -e "12345\n67890" > "$TEST_TEMP_DIR/mock_process_3000"
    echo "active" > "$TEST_TEMP_DIR/mock_process_by_pid_12345"
    echo "active" > "$TEST_TEMP_DIR/mock_process_by_pid_67890"
    
    run "$UTILITY_SCRIPTS_PATH/killport.sh" 3000
    
    assert_success
    assert_output --partial "Process on port 3000 terminated"
    
    # Verify lsof was called
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -ti:3000"
    
    # Should attempt to kill the first PID found
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 12345"
}

@test "works with standard web development ports" {
    create_mock_process "3000" "11111"
    
    run "$UTILITY_SCRIPTS_PATH/killport.sh" 3000
    
    assert_success
    assert_output --partial "Process on port 3000 terminated"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 11111"
}

@test "works with port 3001" {
    create_mock_process "3001" "22222"
    
    run "$UTILITY_SCRIPTS_PATH/killport.sh" 3001
    
    assert_success
    assert_output --partial "Process on port 3001 terminated"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 22222"
}

@test "works with high port numbers" {
    create_mock_process "8080" "33333"
    
    run "$UTILITY_SCRIPTS_PATH/killport.sh" 8080
    
    assert_success
    assert_output --partial "Process on port 8080 terminated"
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 33333"
}

@test "handles invalid port argument gracefully" {
    # The script doesn't validate port numbers, so this should still work
    # but lsof will return nothing
    
    run "$UTILITY_SCRIPTS_PATH/killport.sh" "invalid"
    
    assert_success
    assert_output --partial "No process on port invalid"
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -ti:invalid"
}

@test "requires port argument" {
    run "$UTILITY_SCRIPTS_PATH/killport.sh"
    
    assert_success
    assert_output --partial "No process on port"
    
    # Should still call lsof but with empty port
    assert_mock_called_with "$TEST_TEMP_DIR/lsof_calls.log" "lsof -ti:"
}

@test "uses SIGTERM signal for graceful termination" {
    create_mock_process "4000" "44444"
    
    run "$UTILITY_SCRIPTS_PATH/killport.sh" 4000
    
    assert_success
    
    # Verify it uses -15 (SIGTERM) not -9 (SIGKILL)
    assert_mock_called_with "$TEST_TEMP_DIR/kill_calls.log" "kill -15 44444"
    
    # Ensure it's not using SIGKILL
    if grep -q "kill -9" "$TEST_TEMP_DIR/kill_calls.log" 2>/dev/null; then
        fail "Script should use SIGTERM (-15), not SIGKILL (-9)"
    fi
}