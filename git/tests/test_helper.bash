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
    # Create safe filename by replacing special characters
    local safe_filename="${branch_name//[\/]/_}.txt"
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