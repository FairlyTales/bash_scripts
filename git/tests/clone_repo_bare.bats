#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_environment
    setup_bare_clone_mocks
}

teardown() {
    cd "$TEST_TEMP_DIR"
    rm -rf test_*
    rm -rf my_*
    rm -rf demo_*
    rm -rf project_*
    rm -rf .bare
    rm -rf .project_cursorrules
}

# Enhanced setup for bare clone testing
setup_bare_clone_mocks() {
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    # Setup package manager mocks
    setup_package_manager_mocks
    
    # Clear any existing logs
    rm -f "$TEST_TEMP_DIR/git_calls.log"
    rm -f "$TEST_TEMP_DIR/package_manager_calls.log"
    rm -f "$TEST_TEMP_DIR/ide_calls.log"
    
    # Create enhanced git mock that handles bare clone operations
    cat > "$TEST_TEMP_DIR/git" << 'EOF'
#!/usr/bin/env bash

case "$1" in
    "clone")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        
        if [ "$2" = "--bare" ]; then
            # Handle bare clone: git clone --bare URL DIR
            url="$3"
            target_dir="$4"
            
            if [ -n "$target_dir" ]; then
                mkdir -p "$target_dir"
                cd "$target_dir"
            fi
            
            # Initialize bare repository
            /usr/bin/git init --bare
            
            # Create some mock refs to simulate a real remote
            mkdir -p refs/heads refs/remotes/origin
            echo "0000000000000000000000000000000000000000" > refs/heads/master
            echo "0000000000000000000000000000000000000000" > refs/heads/main
            echo "0000000000000000000000000000000000000000" > refs/remotes/origin/master
            echo "0000000000000000000000000000000000000000" > refs/remotes/origin/main
        else
            # Handle regular clone
            url="$2"
            target_dir="$3"
            
            if [ -n "$target_dir" ]; then
                mkdir -p "$target_dir"
                cd "$target_dir"
            fi
            
            /usr/bin/git init
            /usr/bin/git config user.name "Test User"
            /usr/bin/git config user.email "test@example.com"
            echo "# Cloned Repository" > README.md
            /usr/bin/git add README.md
            /usr/bin/git commit -m "Initial commit"
        fi
        exit 0
        ;;
    "fetch")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        exit 0
        ;;
    "worktree")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        if [ "$2" = "add" ]; then
            # Handle worktree add: git worktree add path branch
            worktree_path="$3"
            branch="$4"
            
            # Store current directory to return to it
            original_dir=$(pwd)
            
            # If the worktree path starts with ./ it's relative to current directory
            if [[ "$worktree_path" == ./* ]]; then
                # Remove the ./ prefix and create the directory relative to parent
                relative_path="${worktree_path#./}"
                # Go to parent directory to create the worktree at the right level
                cd ..
                mkdir -p "$relative_path"
                cd "$relative_path"
            else
                # Create absolute or direct path
                mkdir -p "$worktree_path"
                cd "$worktree_path"
            fi
            
            # Initialize git repo in worktree directory
            /usr/bin/git init
            /usr/bin/git config user.name "Test User"
            /usr/bin/git config user.email "test@example.com"
            echo "# Worktree for $branch" > README.md
            /usr/bin/git add README.md
            /usr/bin/git commit -m "Initial commit in worktree"
            
            # Create the branch if it doesn't exist
            /usr/bin/git checkout -b "$branch" 2>/dev/null || /usr/bin/git checkout "$branch"
            
            # Return to original directory
            cd "$original_dir"
        fi
        exit 0
        ;;
    "push")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        exit 0
        ;;
    "pull")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        exit 0
        ;;
    "checkout")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        # Handle checkout command - just log it and succeed
        exit 0
        ;;
    "config")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        # Handle git config commands
        if [ "$2" = "user.name" ] && [ -n "$3" ]; then
            # Set user name - actually call real git config
            /usr/bin/git config user.name "$3"
        elif [ "$2" = "user.email" ] && [ -n "$3" ]; then
            # Set user email - actually call real git config  
            /usr/bin/git config user.email "$3"
        else
            # For other config operations, pass through to real git
            exec /usr/bin/git "$@"
        fi
        exit 0
        ;;
    *)
        # Pass through to real git for other commands
        exec /usr/bin/git "$@"
        ;;
esac
EOF
    chmod +x "$TEST_TEMP_DIR/git"
}

@test "clones bare repo with all parameters provided" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'master\nyarn\ntestuser\ntestuser@example.com' | $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo yarn"
    
    assert_success
    
    # Verify bare clone was called
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git clone --bare https://github.com/test/repo.git test_repo"
    
    # Verify directory structure
    assert_dir_exists "test_repo"
    assert_dir_exists "test_repo/.bare"
    assert_dir_exists "test_repo/.project_cursorrules"
    
    # Verify .git file points to .bare
    assert_file_exists "test_repo/.git"
    run cat "test_repo/.git"
    assert_output "gitdir: ./.bare"
}

@test "prompts for directory name when not provided" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git
        expect \"Specify the directory name:\"
        send \"my_project\\r\"
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"Y\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    assert_output --partial "Specify the directory name:"
    
    # Verify bare clone with user-provided name
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git clone --bare https://github.com/test/repo.git my_project"
    assert_dir_exists "my_project"
    assert_dir_exists "my_project/.bare"
}

@test "configures master branch correctly" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    assert_output --partial "Specify the master branch name"
    assert_output --partial "Default branch is set to: master"
    
    # Verify git config contains branch configuration
    assert_file_exists "test_repo/.bare/config"
    run cat "test_repo/.bare/config"
    assert_output --partial 'fetch = +refs/heads/*:refs/remotes/origin/*'
    assert_output --partial '[branch "master"]'
    assert_output --partial 'remote = origin'
    assert_output --partial 'merge = refs/heads/master'
}

@test "configures main branch when specified" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"main\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    
    # Verify git config contains main branch configuration
    assert_file_exists "test_repo/.bare/config"
    run cat "test_repo/.bare/config"
    assert_output --partial '[branch "main"]'
    assert_output --partial 'merge = refs/heads/main'
    assert_output --partial 'vscode-merge-base = origin/main'
}

@test "uses default master branch when empty input" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    assert_output --partial "Default branch is set to: master"
    
    # Verify worktree creation with master branch
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git worktree add ./test_repo-master origin/master"
}

@test "creates worktree with project name and branch" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'develop\n\ntestuser\ntestuser@example.com' | $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git myproject"
    
    assert_success
    
    # Verify worktree was created with correct naming
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git worktree add ./myproject-develop origin/develop"
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git fetch origin"
}

@test "installs dependencies with yarn when specified" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'master\ntestuser\ntestuser@example.com' | $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo yarn"
    
    assert_success
    
    # Verify yarn install was called
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "yarn install"
}

@test "installs dependencies with npm when specified" {
    cd "$TEST_TEMP_DIR"
    
    run bash -c "echo -e 'master\ntestuser\ntestuser@example.com' | $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo npm"
    
    assert_success
    
    # Verify npm install was called
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "npm install"
}

@test "prompts for package manager when not specified" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"Y\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    assert_output --partial "Specify package manager"
    assert_output --partial "[Y - yarn]"
    assert_output --partial "[N - npm]"
    
    # Verify yarn was called when Y selected
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "yarn install"
}

@test "installs npm when N selected interactively" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"N\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    
    # Verify npm was called when N selected
    assert_mock_called_with "$TEST_TEMP_DIR/package_manager_calls.log" "npm install"
}

@test "skips package installation when Enter pressed" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    
    # Verify no package manager was called
    [ ! -f "$TEST_TEMP_DIR/package_manager_calls.log" ] || [ ! -s "$TEST_TEMP_DIR/package_manager_calls.log" ]
}

@test "configures git user name and email" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"John Doe\\r\"
        expect \"Type user email\"
        send \"john@example.com\\r\"
        expect eof
    "
    
    assert_success
    assert_output --partial "Type user name or press Enter to use global:"
    assert_output --partial "Type user email or press Enter to use global:"
    
    # Check git config in worktree directory
    if [ -d "test_repo-master" ]; then
        cd "test_repo-master"
        # The git config should be set to the user provided values
        # Note: During testing the git config may be set multiple times
        # Check that the config was called with the expected values
        assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git config user.name John Doe"
        assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git config user.email john@example.com"
    else
        # The worktree directory should exist
        fail "Worktree directory test_repo-master was not created"
    fi
}

@test "uses global config when Enter pressed for user info" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"\\r\"
        expect \"Type user email\"
        send \"\\r\"
        expect eof
    "
    
    assert_success
    
    # When empty strings are passed, git config calls are made but with empty values
    # This allows git to fall back to global config
}

@test "creates proper directory structure" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git demo_project
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    
    
    # Verify all required directories exist
    assert_dir_exists "demo_project"
    assert_dir_exists "demo_project/.bare"
    assert_dir_exists "demo_project/.project_cursorrules"
    assert_dir_exists "demo_project-master"
    
    # Verify .git file content
    assert_file_exists "demo_project/.git"
    run cat "demo_project/.git"
    assert_output "gitdir: ./.bare"
}

@test "shows success message with instructions" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    assert_output --partial "Repository successfully cloned"
    assert_output --partial "worktree directory structure created"
    assert_output --partial "master branch created and set to remote"
    assert_output --partial "You need to manually add cursorrules and aider config"
}

@test "handles project name with interactive directory input" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git
        expect \"Specify the directory name:\"
        send \"custom_name\\r\"
        expect \"Specify the master branch name\"
        send \"master\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    
    # Verify worktree was created with the interactive directory name
    assert_mock_called_with "$TEST_TEMP_DIR/git_calls.log" "git worktree add ./custom_name-master origin/master"
    assert_dir_exists "custom_name"
    assert_dir_exists "custom_name-master"
}

@test "appends git config correctly to bare repository" {
    cd "$TEST_TEMP_DIR"
    
    run expect -c "
        spawn $GIT_SCRIPTS_PATH/clone_repo_bare.sh https://github.com/test/repo.git test_repo
        expect \"Specify the master branch name\"
        send \"develop\\r\"
        expect \"Specify package manager:\"
        send \"\\r\"
        expect \"Type user name\"
        send \"testuser\\r\"
        expect \"Type user email\"
        send \"testuser@example.com\\r\"
        expect eof
    "
    
    assert_success
    
    # Verify the git config file has the correct structure
    assert_file_exists "test_repo/.bare/config"
    run cat "test_repo/.bare/config"
    assert_output --partial 'fetch = +refs/heads/*:refs/remotes/origin/*'
    assert_output --partial '[branch "develop"]'
    assert_output --partial 'remote = origin'
    assert_output --partial 'merge = refs/heads/develop'
    assert_output --partial 'vscode-merge-base = origin/develop'
}