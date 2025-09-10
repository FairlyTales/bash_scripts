#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
}

teardown() {
    teardown_test_repo
}

@test "shows message when no branches exist" {
    # Remove all branches except current (should be master/main)
    # This test runs on a fresh repo which only has master/main
    local current_branch=$(git branch --show-current)
    
    # Create new repo with no additional branches
    rm -rf "$TEST_REPO_DIR"
    create_test_repo
    
    # Delete the master branch by creating orphan branch and deleting master
    git checkout --orphan temp
    git branch -D master 2>/dev/null || git branch -D main 2>/dev/null || true
    git checkout --orphan master
    
    run "$GIT_SCRIPTS_PATH/branch_checkout.sh" <<< ""
    
    assert_success
    assert_output --partial "No branches to checkout."
}

@test "lists available branches" {
    create_branch "feature-1"
    create_branch "feature-2" 
    create_branch "bugfix-1"
    
    run "$GIT_SCRIPTS_PATH/branch_checkout.sh" <<< ""
    
    assert_success
    assert_output --partial "List of branches to checkout:"
    # Note: git for-each-ref orders branches alphabetically, so:
    # bugfix-1, feature-1, feature-2, master
    assert_output --partial "[1] bugfix-1"
    assert_output --partial "[2] feature-1" 
    assert_output --partial "[3] feature-2"
    assert_output --partial "[4] master"
}

@test "cancels when Enter is pressed" {
    create_branch "feature-1"
    
    run "$GIT_SCRIPTS_PATH/branch_checkout.sh" <<< ""
    
    assert_success
    assert_output --partial "Cancelled."
}

@test "checks out selected branch" {
    create_branch "feature-1"
    create_branch "feature-2"
    
    # Select branch 2 (feature-1, since branches are alphabetical: feature-1, feature-2, master)
    run bash -c "echo '2' | $GIT_SCRIPTS_PATH/branch_checkout.sh"
    
    assert_success
    # After checkout, we should be on feature-2
    assert_current_branch "feature-2"
}

@test "checks out master branch" {
    create_branch "feature-1"
    create_branch "feature-2"
    
    # Switch to feature-1 first
    git checkout feature-1
    
    # Now test checking out master (should be index 3: feature-1, feature-2, master)
    run bash -c "echo '3' | $GIT_SCRIPTS_PATH/branch_checkout.sh"
    
    assert_success
    assert_current_branch "master"
}

@test "fails with invalid index - non-numeric" {
    create_branch "feature-1"
    
    run bash -c "echo 'abc' | $GIT_SCRIPTS_PATH/branch_checkout.sh"
    
    assert_failure
    assert_output --partial "Error. Invalid index."
}

@test "fails with invalid index - too low" {
    create_branch "feature-1"
    
    run bash -c "echo '0' | $GIT_SCRIPTS_PATH/branch_checkout.sh"
    
    assert_failure
    assert_output --partial "Error. Invalid index."
}

@test "fails with invalid index - too high" {
    create_branch "feature-1"
    
    # There should be 2 branches (feature-1 and master), so index 5 is too high
    run bash -c "echo '5' | $GIT_SCRIPTS_PATH/branch_checkout.sh"
    
    assert_failure
    assert_output --partial "Error. Invalid index."
}

@test "handles branch names with special characters" {
    create_branch "feature/new-ui"
    create_branch "fix-bug-#123"
    
    # Select first branch (feature/new-ui)
    run bash -c "echo '1' | $GIT_SCRIPTS_PATH/branch_checkout.sh"
    
    assert_success
    assert_current_branch "feature/new-ui"
}