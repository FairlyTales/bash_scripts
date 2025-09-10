#!/usr/bin/env bats

load test_helper

setup() {
    setup_ide_mocks
}

teardown() {
    teardown_ide_test
}

@test "calls launch_cursor_in_pwd.sh" {
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_current_ide_in_pwd.sh"
    
    assert_success
    assert_output --partial "Launching Cursor in $TEST_TEMP_DIR"
    assert_ide_called_with "cursor $TEST_TEMP_DIR"
}

@test "resolves path correctly" {
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_current_ide_in_pwd.sh"
    
    assert_success
    # Should ultimately call cursor through the launch_cursor_in_pwd.sh script
    assert_ide_called_with "cursor $TEST_TEMP_DIR"
}

@test "passes through exit code on success" {
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_current_ide_in_pwd.sh"
    
    assert_success
}

@test "passes through exit code on failure" {
    setup_failing_ide_mocks
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_current_ide_in_pwd.sh"
    
    assert_failure
}

@test "works from different working directories" {
    # Create a different directory to run the script from
    local other_dir="$TEST_TEMP_DIR/other"
    mkdir -p "$other_dir"
    cd "$other_dir"
    
    run "$IDE_SCRIPTS_PATH/launch_current_ide_in_pwd.sh"
    
    assert_success
    assert_output --partial "Launching Cursor in $other_dir"
    assert_ide_called_with "cursor $other_dir"
}

@test "passes through output from cursor script" {
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_current_ide_in_pwd.sh"
    
    assert_success
    # Should show the output from launch_cursor_in_pwd.sh
    assert_output --partial "Launching Cursor in"
    assert_output --partial "$TEST_TEMP_DIR"
}