#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
    setup_git_mocks
    create_fake_remote
}

teardown() {
    teardown_test_repo
}

@test "push_new_branch.sh pushes current branch to remote with upstream" {
    # Create and switch to a new branch
    create_branch "new-feature"
    git checkout new-feature
    
    run "$GIT_SCRIPTS_PATH/push_new_branch.sh"
    
    assert_success
    
    # Verify git push was called with correct parameters
    assert_file_exists "$TEST_TEMP_DIR/git_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git push --set-upstream origin new-feature"
}

@test "push_new_branch.sh works from master branch" {
    # Stay on master branch
    git checkout master
    
    run "$GIT_SCRIPTS_PATH/push_new_branch.sh"
    
    assert_success
    
    # Verify git push was called for master
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git push --set-upstream origin master"
}

@test "push_new_branch.sh handles branch names with special characters" {
    # Create branch with special characters
    create_branch "feature/new-ui"
    git checkout "feature/new-ui"
    
    run "$GIT_SCRIPTS_PATH/push_new_branch.sh"
    
    assert_success
    
    # Verify git push was called with properly formatted branch name
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git push --set-upstream origin feature/new-ui"
}

@test "push_new_branch.sh works with long branch names" {
    # Create branch with long name
    local long_branch_name="very-long-branch-name-with-many-words-and-dashes"
    create_branch "$long_branch_name"
    git checkout "$long_branch_name"
    
    run "$GIT_SCRIPTS_PATH/push_new_branch.sh"
    
    assert_success
    
    # Verify git push was called with full branch name
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git push --set-upstream origin $long_branch_name"
}

@test "push_new_branch.sh detects current branch correctly" {
    # Create multiple branches
    create_branch "branch-1"
    create_branch "branch-2"
    create_branch "target-branch"
    
    # Switch to specific branch
    git checkout "target-branch"
    
    run "$GIT_SCRIPTS_PATH/push_new_branch.sh"
    
    assert_success
    
    # Should push the target branch, not any other branch
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git push --set-upstream origin target-branch"
    
    # Should NOT push other branches
    run bash -c "grep 'branch-1\\|branch-2' '$TEST_TEMP_DIR/git_calls.log' || true"
    assert_output ""
}

@test "push_new_branch.sh script is simple and direct" {
    # This test verifies the script's simplicity - it should just get current branch and push
    create_branch "simple-test"
    git checkout "simple-test"
    
    run "$GIT_SCRIPTS_PATH/push_new_branch.sh"
    
    assert_success
    
    # Verify only one git push command was executed
    local push_count
    push_count=$(grep -c "git push" "$TEST_TEMP_DIR/git_calls.log")
    assert_equal "$push_count" "1"
}

@test "push_new_branch.sh uses correct upstream syntax" {
    create_branch "test-upstream"
    git checkout "test-upstream"
    
    run "$GIT_SCRIPTS_PATH/push_new_branch.sh"
    
    assert_success
    
    # Verify the exact command format
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git push --set-upstream origin test-upstream"
    
    # Ensure it doesn't use shortened -u flag (script uses full --set-upstream)
    run bash -c "grep -- '-u ' '$TEST_TEMP_DIR/git_calls.log' || true"
    assert_output ""
}