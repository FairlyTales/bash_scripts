#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
    setup_test_environment
    setup_mocks_for_remote_worktree
    create_test_env_files "$TEST_REPO_DIR"
    create_fake_remote
}

teardown() {
    teardown_test_repo
}

@test "fetches and creates worktree from remote branch" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # Verify git fetch was called
    assert_file_exists "$TEST_TEMP_DIR/git_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git fetch"
    
    # Verify worktree directory was created
    assert_dir_exists "$TEST_REPO_DIR/$branch_name"
    
    # Verify default package manager (yarn) was used
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "yarn install"
}

@test "uses specified package manager" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name npm"
    
    assert_success
    
    # Verify npm was used instead of yarn
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "npm install"
}

@test "copies environment files" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # Check that environment files were copied
    assert_file_exists "$TEST_REPO_DIR/$branch_name/.env.auth"
    assert_file_exists "$TEST_REPO_DIR/$branch_name/.env.local"
    assert_file_exists "$TEST_REPO_DIR/$branch_name/.env"
    assert_dir_exists "$TEST_REPO_DIR/$branch_name/.gemini"
    assert_file_exists "$TEST_REPO_DIR/$branch_name/.aider.conf.yml"
    
    # Verify content of copied files
    run cat "$TEST_REPO_DIR/$branch_name/.env.auth"
    assert_output "AUTH_TOKEN=test_auth"
}

@test "launches IDE after setup" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # Verify IDE launcher was called
    assert_file_exists "$TEST_TEMP_DIR/ide_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/ide_calls.log" "mock IDE launcher called"
}

@test "handles branch names with special characters" {
    local branch_name="feature/remote-ui"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh '$branch_name'"
    
    assert_success
    
    # Verify worktree was created with correct name
    assert_dir_exists "$TEST_REPO_DIR/$branch_name"
}

@test "shows package manager message" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name npm"
    
    assert_success
    assert_output --partial "Using npm to install dependencies..."
}

@test "shows default package manager message" {
    local branch_name="remote-feature"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    assert_output --partial "Package manager not specified, using yarn to install dependencies..."
}

@test "runs from repository root" {
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

@test "creates worktree for existing remote branch" {
    local branch_name="existing-remote"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    # The script assumes the branch exists on remote after fetch
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_success
    
    # The git worktree add command should be attempted
    # In our mock environment, this will succeed
    assert_dir_exists "$TEST_REPO_DIR/$branch_name"
}

@test "fails when remote branch does not exist" {
    local branch_name="non-existent-branch"
    
    # Do NOT create the remote branch
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_failure
    assert_output --partial "Branch 'non-existent-branch' not found on remote repository"
    assert_output --partial "Please check the branch name or create the branch on remote first"
    
    # Verify worktree directory was NOT created
    assert_dir_not_exists "$TEST_REPO_DIR/$branch_name"
}

@test "fails when worktree already exists" {
    local branch_name="duplicate-worktree"
    
    # Create the remote branch first
    create_remote_branch "$branch_name"
    
    # Create the worktree directory with content to simulate conflict
    mkdir -p "$TEST_REPO_DIR/$branch_name"
    echo "existing content" > "$TEST_REPO_DIR/$branch_name/existing_file.txt"
    
    run bash -c "cd $TEST_REPO_DIR && $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_failure
    assert_output --partial "Failed to create worktree for branch '$branch_name'"
}

@test "handles git fetch failure" {
    local branch_name="test-branch"
    
    # Mock git to fail on fetch
    cat > "$TEST_TEMP_DIR/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "fetch" ]]; then
    exit 1
fi
# For other git commands, use the real git
exec /usr/bin/git "$@"
EOF
    chmod +x "$TEST_TEMP_DIR/git"
    
    run bash -c "cd $TEST_REPO_DIR && PATH=$TEST_TEMP_DIR:\$PATH $GIT_SCRIPTS_PATH/worktree_add_remote.sh $branch_name"
    
    assert_failure
    assert_output --partial "Failed to fetch from remote repository"
}