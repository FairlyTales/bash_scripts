#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
    setup_all_mocks
    create_test_env_files "$TEST_REPO_DIR/.."
    create_fake_remote
}

teardown() {
    teardown_test_repo
    # Clean up mock IDE launcher
    [ -f "$ROOT_SCRIPTS_PATH/ide/launch_current_ide_in_pwd.sh" ] && rm -f "$ROOT_SCRIPTS_PATH/ide/launch_current_ide_in_pwd.sh"
}

@test "worktree_add_remote.sh fetches and creates worktree from remote branch" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # Verify git fetch was called
    assert_file_exists "$TEST_TEMP_DIR/git_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git fetch"
    
    # Verify worktree directory was created
    assert_dir_exists "$TEST_REPO_DIR/../$branch_name"
    
    # Verify default package manager (yarn) was used
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "yarn install"
}

@test "worktree_add_remote.sh uses specified package manager" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name npm"
    
    assert_success
    
    # Verify npm was used instead of yarn
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "npm install"
}

@test "worktree_add_remote.sh copies environment files" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # Check that environment files were copied
    assert_file_exists "$TEST_REPO_DIR/../$branch_name/.env.auth"
    assert_file_exists "$TEST_REPO_DIR/../$branch_name/.env.local"
    assert_file_exists "$TEST_REPO_DIR/../$branch_name/.env"
    assert_dir_exists "$TEST_REPO_DIR/../$branch_name/.gemini"
    assert_file_exists "$TEST_REPO_DIR/../$branch_name/.aider.conf.yml"
    
    # Verify content of copied files
    run cat "$TEST_REPO_DIR/../$branch_name/.env.auth"
    assert_output "AUTH_TOKEN=test_auth"
}

@test "worktree_add_remote.sh launches IDE after setup" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # Verify IDE launcher was called
    assert_file_exists "$TEST_TEMP_DIR/ide_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/ide_calls.log" "mock IDE launcher called"
}

@test "worktree_add_remote.sh handles branch names with special characters" {
    local branch_name="feature/remote-ui"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh '$branch_name'"
    
    assert_success
    
    # Verify worktree was created with correct name
    assert_dir_exists "$TEST_REPO_DIR/../$branch_name"
}

@test "worktree_add_remote.sh shows package manager message" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name npm"
    
    assert_success
    assert_output --partial "Using npm to install dependencies..."
}

@test "worktree_add_remote.sh shows default package manager message" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    assert_output --partial "Package manager not specified, using yarn to install dependencies..."
}

@test "worktree_add_remote.sh runs from repository root" {
    # This script should be run from repository root, not from master worktree
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # The script should work when run from the repository root
    # Verify the basic operations succeeded
    assert_file_exists "$TEST_TEMP_DIR/git_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git fetch"
}

@test "worktree_add_remote.sh creates worktree for existing remote branch" {
    local branch_name="existing-remote"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    # The script assumes the branch exists on remote after fetch
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # The git worktree add command should be attempted
    # In our mock environment, this will succeed
    assert_dir_exists "$TEST_REPO_DIR/../$branch_name"
}