#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
    setup_all_mocks
    create_test_env_files "$TEST_REPO_DIR/.."
}

teardown() {
    teardown_test_repo
}

@test "worktree_add_without_ide.sh creates worktree with default package manager" {
    local worktree_name="feature-no-ide"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name"
    
    assert_success
    
    # Verify worktree directory was created
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name"
    
    # Verify yarn was called (default package manager)
    assert_file_exists "$TEST_TEMP_DIR/package_manager_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "yarn install"
}

@test "worktree_add_without_ide.sh creates worktree with specified package manager" {
    local worktree_name="feature-no-ide"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name npm"
    
    assert_success
    
    # Verify npm was called
    assert_file_exists "$TEST_TEMP_DIR/package_manager_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "npm install"
}

@test "worktree_add_without_ide.sh copies environment files" {
    local worktree_name="feature-no-ide"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name"
    
    assert_success
    
    # Check that environment files were copied
    assert_file_exists "$TEST_REPO_DIR/../$worktree_name/.env.auth"
    assert_file_exists "$TEST_REPO_DIR/../$worktree_name/.env.local"
    assert_file_exists "$TEST_REPO_DIR/../$worktree_name/.env"
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name/.gemini"
    assert_file_exists "$TEST_REPO_DIR/../$worktree_name/.aider.conf.yml"
    
    # Verify content of copied files
    run cat "$TEST_REPO_DIR/../$worktree_name/.env.auth"
    assert_output "AUTH_TOKEN=test_auth"
}

@test "worktree_add_without_ide.sh does NOT launch IDE" {
    local worktree_name="feature-no-ide"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name"
    
    assert_success
    
    # Verify IDE launcher was NOT called
    [ ! -f "$TEST_TEMP_DIR/ide_calls.log" ] || [ ! -s "$TEST_TEMP_DIR/ide_calls.log" ]
}

@test "worktree_add_without_ide.sh creates git worktree successfully" {
    local worktree_name="feature-no-ide"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name"
    
    assert_success
    
    # Verify the git worktree was created
    run bash -c "cd $TEST_REPO_DIR && git worktree list"
    assert_output --partial "$worktree_name"
    
    # Verify we can see the branch
    run bash -c "cd $TEST_REPO_DIR/../$worktree_name && git branch --show-current"
    assert_output "$worktree_name"
}

@test "worktree_add_without_ide.sh shows package manager messages" {
    local worktree_name="feature-no-ide"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name npm"
    
    assert_success
    assert_output --partial "Using npm to install dependencies..."
}

@test "worktree_add_without_ide.sh shows default package manager message" {
    local worktree_name="feature-no-ide"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name"
    
    assert_success
    assert_output --partial "Package manager not specified, using yarn to install dependencies..."
}

@test "worktree_add_without_ide.sh handles branch names with special characters" {
    local worktree_name="feature/no-ide-ui"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh '$worktree_name'"
    
    assert_success
    
    # Verify worktree was created with correct name
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name"
}

@test "worktree_add_without_ide.sh installs dependencies but skips IDE" {
    local worktree_name="feature-no-ide"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name yarn"
    
    assert_success
    
    # Verify yarn install was called
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "yarn install"
    
    # Verify IDE was NOT called
    [ ! -f "$TEST_TEMP_DIR/ide_calls.log" ] || [ ! -s "$TEST_TEMP_DIR/ide_calls.log" ]
}

@test "worktree_add_without_ide.sh script ends without IDE launch" {
    local worktree_name="feature-no-ide"
    
    # The script should end cleanly without trying to launch IDE
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add_without_ide.sh $worktree_name"
    
    assert_success
    
    # Script should complete successfully
    # (The actual script ends after copying aider config, no IDE launch line)
    
    # Verify all expected operations completed
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name"
    assert_file_exists "$TEST_REPO_DIR/../$worktree_name/.aider.conf.yml"
}