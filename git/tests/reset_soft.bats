#!/usr/bin/env bats

load test_helper

setup() {
    create_test_repo
}

teardown() {
    teardown_test_repo
}

@test "resets 1 commit by default" {
    # Create additional commits
    echo "second commit" > file2.txt
    git add file2.txt
    git commit -m "Second commit"
    
    echo "third commit" > file3.txt
    git add file3.txt
    git commit -m "Third commit"
    
    # Get commit count before reset
    local commits_before=$(git rev-list --count HEAD)
    
    # Run the script
    run "$GIT_SCRIPTS_PATH/reset_soft.sh"
    
    assert_success
    
    # Check that we have one less commit
    local commits_after=$(git rev-list --count HEAD)
    assert_equal $((commits_before - 1)) $commits_after
    
    # Check that files are still staged
    run git status --porcelain
    assert_output --partial "A  file3.txt"
}

@test "resets specified number of commits" {
    # Create additional commits
    for i in {2..4}; do
        echo "commit $i" > "file$i.txt"
        git add "file$i.txt"
        git commit -m "Commit $i"
    done
    
    local commits_before=$(git rev-list --count HEAD)
    
    # Reset 2 commits
    run "$GIT_SCRIPTS_PATH/reset_soft.sh" 2
    
    assert_success
    
    # Check that we have 2 less commits
    local commits_after=$(git rev-list --count HEAD)
    assert_equal $((commits_before - 2)) $commits_after
    
    # Check that files are staged
    run git status --porcelain
    assert_output --partial "A  file3.txt"
    assert_output --partial "A  file4.txt"
}

@test "fails with invalid argument" {
    run "$GIT_SCRIPTS_PATH/reset_soft.sh" "abc"
    
    assert_failure
    assert_output --partial "Error: Argument must be a positive integer."
}

@test "fails with negative number" {
    run "$GIT_SCRIPTS_PATH/reset_soft.sh" "-1"
    
    assert_failure
    assert_output --partial "Error: Argument must be a positive integer."
}

@test "fails with zero" {
    run "$GIT_SCRIPTS_PATH/reset_soft.sh" "0"
    
    assert_failure
    assert_output --partial "Error: Argument must be a positive integer."
}

@test "works with multiple digit numbers" {
    # Create 15 commits
    for i in {2..16}; do
        echo "commit $i" > "file$i.txt"
        git add "file$i.txt"
        git commit -m "Commit $i"
    done
    
    local commits_before=$(git rev-list --count HEAD)
    
    # Reset 10 commits
    run "$GIT_SCRIPTS_PATH/reset_soft.sh" 10
    
    assert_success
    
    # Check that we have 10 less commits
    local commits_after=$(git rev-list --count HEAD)
    assert_equal $((commits_before - 10)) $commits_after
}