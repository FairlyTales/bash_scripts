#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
}

teardown() {
    teardown_test_repo
}

@test "shows message when no worktrees exist" {
    # Only master branch, no worktrees
    run "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh"
    
    assert_success
    assert_output --partial "There are no worktrees"
}

@test "lists existing worktrees" {
    # Create some branches and worktrees
    create_test_worktree "feature-1"
    create_test_worktree "feature-2"
    
    run "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh"
    
    assert_success
    # Should list the worktrees (branches that have worktrees)
    assert_output --partial "feature-1"
    assert_output --partial "feature-2"
}

@test "excludes master branch" {
    # Create some branches and worktrees
    create_test_worktree "feature-1"
    create_test_worktree "master-like"  # Has 'master' in name but should be included
    
    run "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh"
    
    assert_success
    # Should list non-master worktrees
    assert_output --partial "feature-1"
    assert_output --partial "master-like"
    
    # Should NOT list actual master branch
    run bash -c "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh | grep -c '^master$' || true"
    assert_output "0"
}

@test "handles branches without worktrees" {
    # Create branches but no worktrees for them
    create_branch "no-worktree-1"
    create_branch "no-worktree-2"
    
    # Create one worktree
    create_test_worktree "has-worktree"
    
    run "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh"
    
    assert_success
    # Should only show branches that have worktrees
    assert_output --partial "has-worktree"
    # Should NOT show branches without worktrees
    run bash -c "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh | grep 'no-worktree' || true"
    assert_output ""
}

@test "formats output correctly" {
    create_test_worktree "test-worktree"
    
    run "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh"
    
    assert_success
    # Should contain the worktree name
    assert_output --partial "test-worktree"
    # Output should start with a newline (script starts with printf "\n")
    assert_line --index 0 "test-worktree"
}

@test "handles multiple worktrees correctly" {
    # Create several worktrees
    create_test_worktree "worktree-1"
    create_test_worktree "worktree-2"
    create_test_worktree "worktree-3"
    
    run "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh"
    
    assert_success
    
    # Count the number of worktrees listed (trim whitespace)
    local worktree_count
    worktree_count=$(echo "$output" | grep -E "^worktree-[0-9]$" | wc -l | xargs)
    assert_equal "$worktree_count" "3"
}

@test "handles worktrees with special characters" {
    # Create worktrees with various naming patterns
    create_test_worktree "feature/new-ui"
    create_test_worktree "fix-bug-123"
    create_test_worktree "release-v1.0"
    
    run "$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh"
    
    assert_success
    assert_output --partial "feature/new-ui"
    assert_output --partial "fix-bug-123" 
    assert_output --partial "release-v1.0"
}