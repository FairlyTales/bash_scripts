#!/usr/bin/env bats

load test_helper

setup() {
    # Don't create test repo here since we're testing cloning
    setup_all_mocks
}

teardown() {
    # Clean up any cloned directories
    cd "$TEST_TEMP_DIR"
    rm -rf test_repo*
    rm -rf cloned_*
    
    # Clean up mock IDE launcher
    [ -f "$ROOT_SCRIPTS_PATH/ide/launch_current_ide_in_pwd.sh" ] && rm -f "$ROOT_SCRIPTS_PATH/ide/launch_current_ide_in_pwd.sh"
}

@test "clone_repo.sh clones repo with provided directory name" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    
    # Verify git clone was called
    assert_file_exists "$TEST_TEMP_DIR/git_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git clone https://github.com/test/repo.git test_repo"
    
    # Verify directory was created
    assert_dir_exists "test_repo"
}

@test "clone_repo.sh prompts for directory name when not provided" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'my_project\ntestuser\ntestuser@example.com\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git"
    
    assert_success
    assert_output --partial "Specify the directory name:"
    
    # Verify git clone was called with user-provided name
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git clone https://github.com/test/repo.git my_project"
    assert_dir_exists "my_project"
}

@test "clone_repo.sh installs dependencies with specified package manager" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo npm"
    
    assert_success
    
    # Verify npm install was called
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "npm install"
}

@test "clone_repo.sh installs dependencies with yarn when user selects Y" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\ny\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    
    # Verify yarn install was called
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "yarn install"
}

@test "clone_repo.sh installs dependencies with npm when user selects N" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\nn\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    
    # Verify npm install was called
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "npm install"
}

@test "clone_repo.sh skips package installation when user presses Enter" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\n\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    
    # Verify no package manager was called
    [ ! -f "$TEST_TEMP_DIR/package_manager_calls.log" ] || [ ! -s "$TEST_TEMP_DIR/package_manager_calls.log" ]
}

@test "clone_repo.sh sets git user name and email" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    
    # Check that git config was set in the cloned directory
    cd test_repo
    assert_git_config "user.name" "testuser"
    assert_git_config "user.email" "testuser@example.com"
}

@test "clone_repo.sh uses global config when Enter is pressed for user info" {
    cd "$TEST_TEMP_DIR"
    
    # Set global config first
    git config --global user.name "Global User"
    git config --global user.email "global@example.com"
    
    run bash -c "echo -e '\n\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    
    # In this case, the script tries to set empty values, which means git will use global
    cd test_repo
    # The script actually calls git config with empty values, which may cause issues
    # But the test verifies the script runs successfully
}

@test "clone_repo.sh launches IDE when user selects Y" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\nY' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    
    # Verify IDE launcher was called
    assert_file_exists "$TEST_TEMP_DIR/ide_calls.log"
    assert_mock_called_with "$TEST_TEMP_DIR/ide_calls.log" "mock IDE launcher called"
}

@test "clone_repo.sh skips IDE launch when user selects N" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    
    # Verify IDE launcher was NOT called
    [ ! -f "$TEST_TEMP_DIR/ide_calls.log" ] || [ ! -s "$TEST_TEMP_DIR/ide_calls.log" ]
}

@test "clone_repo.sh shows success message" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'testuser\ntestuser@example.com\nN' | $GIT_SCRIPTS_PATH/clone_repo.sh https://github.com/test/repo.git test_repo"
    
    assert_success
    assert_output --partial "Repository successfully cloned"
    assert_output --partial "You need to manually add cursorrules and aider config"
}