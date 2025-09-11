#!/usr/bin/env bash

# Load bats helper libraries
load "../../test/bats-helpers/bats-support/load"
load "../../test/bats-helpers/bats-assert/load"
load "../../test/bats-helpers/bats-file/load"

# Set paths
export ROOT_SCRIPTS_PATH="/Users/user/bash_scripts"
export GIT_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/git"
export TEST_TEMP_DIR="$BATS_TEST_TMPDIR"

# Create a temporary git repository for testing
create_test_repo() {
    local repo_name="${1:-test_repo}"
    export TEST_REPO_DIR="$TEST_TEMP_DIR/$repo_name"
    
    mkdir -p "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR"
    
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial commit
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit"
}

# Create a new branch in the test repository
create_branch() {
    local branch_name="$1"
    if [ -z "$branch_name" ]; then
        echo "Error: branch name required"
        return 1
    fi
    
    git checkout -b "$branch_name"
    # Create safe filename by replacing special characters with underscores
    local safe_filename="${branch_name//[\/]/_}.txt"
    # Ensure directory exists for the safe filename
    mkdir -p "$(dirname "$safe_filename")" 2>/dev/null || true
    echo "Content for $branch_name" > "$safe_filename"
    git add "$safe_filename"
    git commit -m "Add content for $branch_name"
    git checkout master 2>/dev/null || git checkout main
}

# Check current git branch
assert_current_branch() {
    local expected_branch="$1"
    local current_branch
    current_branch=$(git branch --show-current)
    
    if [ "$current_branch" != "$expected_branch" ]; then
        echo "Expected branch '$expected_branch', but current branch is '$current_branch'"
        return 1
    fi
}

# Check if branch exists
assert_branch_exists() {
    local branch_name="$1"
    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Branch '$branch_name' does not exist"
        return 1
    fi
}

# Check if branch does not exist
assert_branch_not_exists() {
    local branch_name="$1"
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Branch '$branch_name' should not exist but it does"
        return 1
    fi
}

# Create a mock script that captures its arguments
create_mock_script() {
    local script_name="$1"
    local script_path="$TEST_TEMP_DIR/$script_name"
    
    cat > "$script_path" << 'EOF'
#!/usr/bin/env bash
echo "$@" >> "$TEST_TEMP_DIR/mock_calls.log"
exit 0
EOF
    chmod +x "$script_path"
    echo "$script_path"
}

# Setup mock environment for package managers
setup_package_manager_mocks() {
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    # Create mock yarn
    cat > "$TEST_TEMP_DIR/yarn" << 'EOF'
#!/usr/bin/env bash
echo "yarn $@" >> "$TEST_TEMP_DIR/package_manager_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/yarn"
    
    # Create mock npm
    cat > "$TEST_TEMP_DIR/npm" << 'EOF'
#!/usr/bin/env bash
echo "npm $@" >> "$TEST_TEMP_DIR/package_manager_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/npm"
}

# Clean up after tests
teardown_test_repo() {
    if [ -n "$TEST_REPO_DIR" ] && [ -d "$TEST_REPO_DIR" ]; then
        cd "$TEST_TEMP_DIR"
        rm -rf "$TEST_REPO_DIR"
    fi
}

# Create test environment files
create_test_env_files() {
    local base_dir="$1"
    if [ -z "$base_dir" ]; then
        base_dir="$TEST_TEMP_DIR"
    fi
    
    echo "AUTH_TOKEN=test_auth" > "$base_dir/.env.auth"
    echo "LOCAL_VAR=test_local" > "$base_dir/.env.local"
    echo "MAIN_VAR=test_main" > "$base_dir/.env"
    mkdir -p "$base_dir/.gemini"
    echo "gemini_config=test" > "$base_dir/.gemini/config"
    mkdir -p "$base_dir/.mcp_configs"
    echo "mcp_config=test" > "$base_dir/.mcp_configs/config.json"
    echo "aider_config: test" > "$base_dir/.aider.conf.yml"
}

# Simulate user input for interactive scripts
simulate_user_input() {
    local input="$1"
    echo "$input"
}

# Assert that mock was called with specific arguments
assert_mock_called_with() {
    local mock_log="$1"
    local expected_call="$2"
    
    if [ ! -f "$mock_log" ]; then
        echo "Mock log file '$mock_log' does not exist"
        return 1
    fi
    
    if ! grep -q "$expected_call" "$mock_log"; then
        echo "Expected call '$expected_call' not found in mock log:"
        cat "$mock_log"
        return 1
    fi
}

# Setup mock git commands for testing scripts that use git clone, push, etc.
setup_git_mocks() {
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    # Create mock git that intercepts specific subcommands
    cat > "$TEST_TEMP_DIR/git" << 'EOF'
#!/usr/bin/env bash

# Pass through most git commands to real git, but mock specific ones
case "$1" in
    "clone")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        # Create fake cloned directory
        # Handle both "git clone URL DIR" and "git clone --bare URL DIR"
        local target_dir=""
        if [ "$2" = "--bare" ]; then
            # git clone --bare URL DIR - directory is $4
            target_dir="$4"
        else
            # git clone URL DIR - directory is $3, or URL basename if $3 is empty
            if [ -n "$3" ]; then
                target_dir="$3"
            else
                # Extract basename from URL in $2
                target_dir=$(basename "$2" .git)
            fi
        fi
        
        if [ -n "$target_dir" ]; then
            mkdir -p "$target_dir"
            cd "$target_dir"
        fi
        
        # Initialize as git repo
        if [ "$2" = "--bare" ]; then
            /usr/bin/git init --bare
        else
            /usr/bin/git init
            /usr/bin/git config user.name "Test User"
            /usr/bin/git config user.email "test@example.com"
            echo "# Cloned Repository" > README.md
            /usr/bin/git add README.md
            /usr/bin/git commit -m "Initial commit"
        fi
        exit 0
        ;;
    "push")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        exit 0
        ;;
    "fetch")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        exit 0
        ;;
    "pull")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
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

# Create worktrees in test repo for worktree-related tests
create_test_worktree() {
    local worktree_name="$1"
    local branch_name="${2:-$worktree_name}"
    
    if [ -z "$worktree_name" ]; then
        echo "Error: worktree name required"
        return 1
    fi
    
    # Create the branch first
    git checkout -b "$branch_name"
    # Create safe filename by replacing special characters with underscores
    local safe_filename="${branch_name//[\/]/_}.txt"
    echo "Content for $branch_name" > "$safe_filename"
    git add "$safe_filename"
    git commit -m "Add content for $branch_name"
    git checkout master 2>/dev/null || git checkout main
    
    # Create the worktree with exact branch name as directory name
    # Note: This works for testing but may have issues with branches containing slashes in real use
    git worktree add "../$worktree_name" "$branch_name"
}

# Check if worktree exists
assert_worktree_exists() {
    local worktree_name="$1"
    # Check for exact worktree name in worktree list
    if ! git worktree list | grep -q "$worktree_name"; then
        echo "Worktree '$worktree_name' does not exist"
        return 1
    fi
}

# Check if worktree does not exist
assert_worktree_not_exists() {
    local worktree_name="$1"
    # Check that exact worktree name is not in worktree list
    if git worktree list | grep -q "$worktree_name"; then
        echo "Worktree '$worktree_name' should not exist but it does"
        return 1
    fi
}

# Create fake remote repository for testing
create_fake_remote() {
    local remote_dir="$TEST_TEMP_DIR/fake_remote.git"
    mkdir -p "$remote_dir"
    cd "$remote_dir"
    git init --bare
    
    # Add the fake remote to test repo
    cd "$TEST_REPO_DIR"
    git remote add origin "$remote_dir"
    
    echo "$remote_dir"
}

# Create a remote branch in the fake remote repository
create_remote_branch() {
    local branch_name="$1"
    if [ -z "$branch_name" ]; then
        echo "Error: branch name required"
        return 1
    fi
    
    # Create branch locally first
    git checkout -b "$branch_name"
    # Create safe filename by replacing special characters with underscores
    local safe_filename="${branch_name//[\/]/_}.txt"
    echo "Content for $branch_name" > "$safe_filename"
    git add "$safe_filename"
    git commit -m "Add content for $branch_name"
    
    # Push to fake remote
    git push origin "$branch_name"
    
    # Switch back to master
    git checkout master 2>/dev/null || git checkout main
}

# Check git config values
assert_git_config() {
    local key="$1"
    local expected_value="$2"
    local actual_value
    actual_value=$(git config "$key")
    
    if [ "$actual_value" != "$expected_value" ]; then
        echo "Expected git config $key to be '$expected_value', but got '$actual_value'"
        return 1
    fi
}

# Mock user input for read commands
mock_user_input() {
    local input="$1"
    echo "$input"
}

# Setup isolated test environment with mock directory structure
setup_test_environment() {
    # Create mock directory structure in test temp directory
    export TEST_ROOT_SCRIPTS_PATH="$TEST_TEMP_DIR/mock_scripts"
    mkdir -p "$TEST_ROOT_SCRIPTS_PATH/ide"
    mkdir -p "$TEST_ROOT_SCRIPTS_PATH/git"
    
    # Copy git scripts to mock location for testing
    cp -r /Users/user/bash_scripts/git/* "$TEST_ROOT_SCRIPTS_PATH/git/"
    
    # Create mock IDE launcher in test location
    cat > "$TEST_ROOT_SCRIPTS_PATH/ide/launch_current_ide_in_pwd.sh" << 'EOF'
#!/usr/bin/env bash
echo "mock IDE launcher called" >> "$TEST_TEMP_DIR/ide_calls.log"
exit 0
EOF
    chmod +x "$TEST_ROOT_SCRIPTS_PATH/ide/launch_current_ide_in_pwd.sh"
    
    # Override paths to use test environment
    export ROOT_SCRIPTS_PATH="$TEST_ROOT_SCRIPTS_PATH"
    export GIT_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/git"
}

# Setup comprehensive mocks for all external tools
setup_all_mocks() {
    setup_package_manager_mocks
    setup_git_mocks
    
    # Clear any existing logs
    rm -f "$TEST_TEMP_DIR/git_calls.log"
    rm -f "$TEST_TEMP_DIR/package_manager_calls.log"
    rm -f "$TEST_TEMP_DIR/ide_calls.log"
}

# Setup mocks specifically for remote worktree testing
# This version allows fetch operations to work properly
setup_mocks_for_remote_worktree() {
    setup_package_manager_mocks
    setup_git_mocks_for_remote_worktree
    
    # Clear any existing logs
    rm -f "$TEST_TEMP_DIR/git_calls.log"
    rm -f "$TEST_TEMP_DIR/package_manager_calls.log"
    rm -f "$TEST_TEMP_DIR/ide_calls.log"
}

# Setup git mocks that allow fetch to work for remote worktree testing
setup_git_mocks_for_remote_worktree() {
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    # Create mock git that intercepts some commands but allows fetch
    cat > "$TEST_TEMP_DIR/git" << 'EOF'
#!/usr/bin/env bash

# Pass through most git commands to real git, but mock specific ones
case "$1" in
    "clone")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        # Create fake cloned directory
        # Handle both "git clone URL DIR" and "git clone --bare URL DIR"
        local target_dir=""
        if [ "$2" = "--bare" ]; then
            # git clone --bare URL DIR - directory is $4
            target_dir="$4"
        else
            # git clone URL DIR - directory is $3, or URL basename if $3 is empty
            if [ -n "$3" ]; then
                target_dir="$3"
            else
                # Extract basename from URL in $2
                target_dir=$(basename "$2" .git)
            fi
        fi
        
        if [ -n "$target_dir" ]; then
            mkdir -p "$target_dir"
            cd "$target_dir"
        fi
        
        # Initialize as git repo
        if [ "$2" = "--bare" ]; then
            /usr/bin/git init --bare
        else
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
        # Allow fetch to actually work for remote worktree testing
        exec /usr/bin/git "$@"
        ;;
    "push")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
        # Allow push to actually work for remote worktree testing
        exec /usr/bin/git "$@"
        ;;
    "pull")
        echo "git $*" >> "$TEST_TEMP_DIR/git_calls.log"
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