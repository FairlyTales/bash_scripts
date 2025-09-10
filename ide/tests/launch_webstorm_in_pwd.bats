#!/usr/bin/env bats

load test_helper

setup() {
    setup_ide_mocks
}

teardown() {
    teardown_ide_test
}

@test "successfully launches WebStorm with current directory" {
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_webstorm_in_pwd.sh"
    
    assert_success
    assert_output --partial "Launching WebStorm in $TEST_TEMP_DIR"
    assert_ide_called_with "webstorm $TEST_TEMP_DIR"
}

@test "outputs correct launch message" {
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_webstorm_in_pwd.sh"
    
    assert_success
    assert_output --partial "Launching WebStorm in"
    assert_output --partial "$TEST_TEMP_DIR"
}

@test "works with special characters in directory path" {
    local special_dir=$(create_special_path_test_dir)
    cd "$special_dir"
    
    run "$IDE_SCRIPTS_PATH/launch_webstorm_in_pwd.sh"
    
    assert_success
    assert_output --partial "Launching WebStorm in $special_dir"
    assert_ide_called_with "webstorm $special_dir"
}

@test "handles webstorm command failure" {
    setup_failing_ide_mocks
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_webstorm_in_pwd.sh"
    
    assert_failure
    assert_output --partial "Launching WebStorm in $TEST_TEMP_DIR"
    assert_ide_called_with "webstorm $TEST_TEMP_DIR"
}

@test "passes quoted path to webstorm command" {
    cd "$TEST_TEMP_DIR"
    
    run "$IDE_SCRIPTS_PATH/launch_webstorm_in_pwd.sh"
    
    assert_success
    # Verify the webstorm command receives the path in quotes
    assert_ide_called_with "webstorm $TEST_TEMP_DIR"
}