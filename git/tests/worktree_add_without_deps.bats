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

@test "creates worktree without installing dependencies" {
    local worktree_name="feature-no-deps"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_deps.sh $worktree_name"
    
    assert_success
    
    # Verify worktree directory was created
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name"
    
    # Verify NO package manager was called
    [ ! -f "$TEST_TEMP_DIR/package_manager_calls.log" ] || [ ! -s "$TEST_TEMP_DIR/package_manager_calls.log" ]
}

@test "copies environment files" {
    local worktree_name="feature-no-deps"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_deps.sh $worktree_name"
    
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

@test "launches IDE after setup" {
    local worktree_name="feature-no-deps"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_deps.sh $worktree_name"
    
    assert_success
    
    # Verify IDE launcher was called
    assert_file_exists "$TEST_TEMP_DIR/ide_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/ide_calls.log" "mock IDE launcher called"
}

@test "creates git worktree successfully" {
    local worktree_name="feature-no-deps"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_deps.sh $worktree_name"
    
    assert_success
    
    # Verify the git worktree was created
    run bash -c "cd $TEST_REPO_DIR && git worktree list"
    assert_output --partial "$worktree_name"
    
    # Verify we can see the branch
    run bash -c "cd $TEST_REPO_DIR/../$worktree_name && git branch --show-current"
    assert_output "$worktree_name"
}

@test "handles branch names with special characters" {
    local worktree_name="feature/no-deps-ui"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_deps.sh '$worktree_name'"
    
    assert_success
    
    # Verify worktree was created with correct name
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name"
}

@test "skips package installation completely" {
    local worktree_name="feature-no-deps"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_deps.sh $worktree_name"
    
    assert_success
    
    # Verify output does not contain package manager messages
    run bash -c "echo '$output' | grep -i 'install\\|yarn\\|npm' || true"
    assert_output ""
    
    # Verify no package manager logs were created
    [ ! -f "$TEST_TEMP_DIR/package_manager_calls.log" ] || [ ! -s "$TEST_TEMP_DIR/package_manager_calls.log" ]
}

@test "copies gemini directory recursively" {
    local worktree_name="feature-no-deps"
    
    # Add content to gemini directory
    mkdir -p "$TEST_REPO_DIR/../.gemini/subdir"
    echo "gemini sub content" > "$TEST_REPO_DIR/../.gemini/subdir/file.txt"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_deps.sh $worktree_name"
    
    assert_success
    
    # Verify gemini directory and subdirectories were copied
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name/.gemini"
    assert_dir_exists "$TEST_REPO_DIR/../$worktree_name/.gemini/subdir"
    assert_file_exists "$TEST_REPO_DIR/../$worktree_name/.gemini/subdir/file.txt"
    
    # Verify content was preserved
    run cat "$TEST_REPO_DIR/../$worktree_name/.gemini/subdir/file.txt"
    assert_output "gemini sub content"
}

@test "is faster than regular worktree_add" {
    local worktree_name="feature-no-deps"
    
    # This test conceptually verifies that the script skips time-consuming operations
    local start_time=$(date +%s)
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_without_deps.sh $worktree_name"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    assert_success
    
    # Should complete quickly since no package installation
    # This is a conceptual test - in practice, duration will vary
    [ "$duration" -lt 10 ]  # Should take less than 10 seconds
}