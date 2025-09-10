#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
    setup_test_environment
    setup_all_mocks
    create_test_env_files "$TEST_REPO_DIR/.."
}

teardown() {
    teardown_test_repo
}

@test "worktree_add.sh creates worktree with default package manager" {
    local worktree_name="feature-branch"
    
    # Mock the relative path to ide script
    export PATH="$TEST_TEMP_DIR/..:$PATH"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add.sh $worktree_name"
    
    assert_success
    
    # Check that worktree directory was created
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name"
    
    # Check that yarn was called (default package manager)
    assert_file_exists "$TEST_TEMP_DIR/package_manager_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "yarn install"
}

@test "worktree_add.sh creates worktree with specified package manager" {
    local worktree_name="feature-branch"
    
    # Mock the relative path to ide script  
    export PATH="$TEST_TEMP_DIR/..:$PATH"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add.sh $worktree_name npm"
    
    assert_success
    
    # Check that worktree directory was created
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name"
    
    # Check that npm was called
    assert_file_exists "$TEST_TEMP_DIR/package_manager_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "npm install"
}

@test "worktree_add.sh copies environment files" {
    local worktree_name="feature-branch"
    
    # Mock the relative path to ide script
    export PATH="$TEST_TEMP_DIR/..:$PATH"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add.sh $worktree_name"
    
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

@test "worktree_add.sh launches IDE" {
    local worktree_name="feature-branch"
    
    # Mock the relative path to ide script
    export PATH="$TEST_TEMP_DIR/..:$PATH"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add.sh $worktree_name"
    
    assert_success
    
    # Check that IDE launcher was called
    assert_file_exists "$TEST_TEMP_DIR/ide_calls.log"
    run cat "$TEST_TEMP_DIR/ide_calls.log"
    assert_output "mock IDE launcher called"
}

@test "worktree_add.sh creates git worktree successfully" {
    local worktree_name="feature-branch"
    
    # Mock the relative path to ide script
    export PATH="$TEST_TEMP_DIR/..:$PATH"
    
    run bash -c "cd $TEST_REPO_DIR && echo '' | $GIT_SCRIPTS_PATH/worktree_add.sh $worktree_name"
    
    assert_success
    
    # Verify the git worktree was created
    run bash -c "cd $TEST_REPO_DIR && git worktree list"
    assert_output --partial "$worktree_name"
    
    # Verify we can see the branch
    run bash -c "cd $TEST_REPO_DIR/../$worktree_name && git branch --show-current"
    assert_output "$worktree_name"
}