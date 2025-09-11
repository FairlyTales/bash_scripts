#!/usr/bin/env bash

# Load bats helper libraries
load "../../test/bats-helpers/bats-support/load"
load "../../test/bats-helpers/bats-assert/load"
load "../../test/bats-helpers/bats-file/load"

# Set paths
export ROOT_SCRIPTS_PATH="/Users/user/bash_scripts"
export UTILITY_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/utility"
export TEST_TEMP_DIR="$BATS_TEST_TMPDIR"

# Mock directories for MySky projects
export MOCK_MYSKY_ROOT="$TEST_TEMP_DIR/Mysky"
export MOCK_APPSHELL_DIR="$MOCK_MYSKY_ROOT/projects/mysky_app_shell"
export MOCK_SPEND_DIR="$MOCK_MYSKY_ROOT/projects/_spend_front/master"
export MOCK_DOWNLOADS_DIR="$TEST_TEMP_DIR/Downloads"
export MOCK_PROMPT_LIBRARY_SOURCE="$TEST_TEMP_DIR/My stuff/Coding/llm_stuff/prompt_library/prompt_library"

# Create mock MySky project structure
create_mock_mysky_projects() {
    mkdir -p "$MOCK_APPSHELL_DIR"
    mkdir -p "$MOCK_SPEND_DIR"
    mkdir -p "$MOCK_DOWNLOADS_DIR"
    mkdir -p "$MOCK_PROMPT_LIBRARY_SOURCE"
    
    # Create mock .env.local files
    echo "REACT_APP_API_URL=https://dev1.mysky.com/api" > "$MOCK_APPSHELL_DIR/.env.local"
    echo "REACT_APP_API_URL=https://dev1.mysky.com/api" > "$MOCK_SPEND_DIR/.env.local"
    
    # Create mock prompt library files
    echo "Prompt 1 content" > "$MOCK_PROMPT_LIBRARY_SOURCE/prompt1.txt"
    echo "Prompt 2 content" > "$MOCK_PROMPT_LIBRARY_SOURCE/prompt2.md"
    mkdir -p "$MOCK_PROMPT_LIBRARY_SOURCE/subdir"
    echo "Nested prompt" > "$MOCK_PROMPT_LIBRARY_SOURCE/subdir/nested.txt"
}

# Setup mock commands for system tools
setup_utility_mocks() {
    export PATH="$TEST_TEMP_DIR:$PATH"
    export KILL_CMD="$TEST_TEMP_DIR/kill"
    
    # Clear existing logs
    rm -f "$TEST_TEMP_DIR/lsof_calls.log"
    rm -f "$TEST_TEMP_DIR/kill_calls.log"
    rm -f "$TEST_TEMP_DIR/yarn_calls.log"
    rm -f "$TEST_TEMP_DIR/sed_calls.log"
    rm -f "$TEST_TEMP_DIR/find_calls.log"
    rm -f "$TEST_TEMP_DIR/cp_calls.log"
    
    # Mock lsof command
    cat > "$TEST_TEMP_DIR/lsof" << 'EOF'
#!/usr/bin/env bash
echo "lsof $*" >> "$TEST_TEMP_DIR/lsof_calls.log"

# Parse arguments to simulate lsof behavior
case "$*" in
    "-ti:"*)
        # Extract port number from -ti:PORT
        port="${*//*-ti:/}"
        port="${port// */}"
        if [ -f "$TEST_TEMP_DIR/mock_process_${port}" ]; then
            cat "$TEST_TEMP_DIR/mock_process_${port}"
        fi
        ;;
    "-Pi :"*" -sTCP:LISTEN -t")
        # Extract port number from -Pi :PORT -sTCP:LISTEN -t
        # The port is in $2 as ":PORT", so remove the leading colon
        args_array=($*)
        port="${args_array[1]#:}"
        if [ -f "$TEST_TEMP_DIR/mock_process_${port}" ]; then
            cat "$TEST_TEMP_DIR/mock_process_${port}"
        fi
        ;;
esac
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/lsof"
    
    # Mock kill command
    cat > "$TEST_TEMP_DIR/kill" << 'EOF'
#!/usr/bin/env bash
echo "kill $*" >> "$TEST_TEMP_DIR/kill_calls.log"

# Simulate kill behavior
case "$1" in
    "-15"|"-TERM")
        # Remove the process file to simulate termination
        if [ -n "$2" ] && [ -f "$TEST_TEMP_DIR/mock_process_by_pid_$2" ]; then
            rm "$TEST_TEMP_DIR/mock_process_by_pid_$2"
        fi
        ;;
    "-9"|"-KILL")
        # Remove the process file to simulate immediate termination
        if [ -n "$2" ] && [ -f "$TEST_TEMP_DIR/mock_process_by_pid_$2" ]; then
            rm "$TEST_TEMP_DIR/mock_process_by_pid_$2"
        fi
        ;;
    "-s")
        # kill -s 0 PID checks if process exists
        if [ "$2" = "0" ] && [ -n "$3" ]; then
            if [ -f "$TEST_TEMP_DIR/mock_process_by_pid_$3" ]; then
                exit 0
            else
                exit 1
            fi
        fi
        ;;
esac
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/kill"
    
    # Mock yarn command
    cat > "$TEST_TEMP_DIR/yarn" << 'EOF'
#!/usr/bin/env bash
echo "yarn $* (pwd: $(pwd))" >> "$TEST_TEMP_DIR/yarn_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/yarn"
    
    # Mock sed command
    cat > "$TEST_TEMP_DIR/sed" << EOF
#!/usr/bin/env bash
# Log normalized sed call (remove empty string argument if present)
normalized_args="\$*"
# Remove -i '' and replace with -i 
if [[ "\$normalized_args" == *"-i ''"* ]]; then
    normalized_args="\${normalized_args/-i ''/-i }"
fi
echo "sed \$normalized_args" >> "$TEST_TEMP_DIR/sed_calls.log"

# Handle the specific sed pattern used in change_dev_server script
if [[ "\$*" == *"s/dev[0-9]/dev"* ]]; then
    # Extract the file path (last argument)
    file="\${*##* }"
    new_server="\${*#*dev}"
    new_server="\${new_server%% *}"
    
    # Mock the replacement if file exists
    if [ -f "\$file" ]; then
        # Create a backup and modify the file for testing
        /usr/bin/sed "s/dev[0-9]/dev\${new_server}/g" "\$file" > "\${file}.tmp" && mv "\${file}.tmp" "\$file"
    fi
# Handle export_prompt_library sed patterns - pass through to real sed
elif [[ "\$*" == *"SOURCE_DIR="* ]] || [[ "\$*" == *"DEST_DIR="* ]]; then
    exec /usr/bin/sed "\$@"
fi
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/sed"
    
    # Mock find command
    cat > "$TEST_TEMP_DIR/find" << 'EOF'
#!/usr/bin/env bash
echo "find $*" >> "$TEST_TEMP_DIR/find_calls.log"

# Handle find command for export_prompt_library
if [[ "$*" == *"-type f -exec cp {} "* ]]; then
    # Parse arguments manually
    args=("$@")
    source_dir="${args[0]}"
    
    # Find the destination after "-exec cp {} "
    for i in "${!args[@]}"; do
        if [[ "${args[i]}" == "cp" && "${args[i+1]}" == "{}" ]]; then
            dest_dir="${args[i+2]}"
            dest_dir="${dest_dir%/}"
            break
        fi
    done
    
    if [ -d "$source_dir" ]; then
        # Copy all files recursively, flattening the structure
        /usr/bin/find "$source_dir" -type f -exec /bin/cp {} "$dest_dir/" \;
    fi
fi
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/find"
    
    # Mock cp command  
    cat > "$TEST_TEMP_DIR/cp" << 'EOF'
#!/usr/bin/env bash
echo "cp $*" >> "$TEST_TEMP_DIR/cp_calls.log"
# Pass through to real cp
exec /bin/cp "$@"
EOF
    chmod +x "$TEST_TEMP_DIR/cp"
}

# Create a mock process on a specific port
create_mock_process() {
    local port="$1"
    local pid="$2"
    
    if [ -z "$port" ] || [ -z "$pid" ]; then
        echo "Error: create_mock_process requires port and pid"
        return 1
    fi
    
    echo "$pid" > "$TEST_TEMP_DIR/mock_process_${port}"
    echo "active" > "$TEST_TEMP_DIR/mock_process_by_pid_${pid}"
}

# Remove mock process from a specific port
remove_mock_process() {
    local port="$1"
    local pid="$2"
    
    if [ -n "$port" ]; then
        rm -f "$TEST_TEMP_DIR/mock_process_${port}"
    fi
    if [ -n "$pid" ]; then
        rm -f "$TEST_TEMP_DIR/mock_process_by_pid_${pid}"
    fi
}

# Check if mock was called with specific arguments
assert_mock_called_with() {
    local mock_log="$1"
    local expected_call="$2"
    
    if [ ! -f "$mock_log" ]; then
        echo "Mock log file '$mock_log' does not exist"
        return 1
    fi
    
    if ! grep -q "$expected_call" "$mock_log"; then
        echo "Expected call '$expected_call' not found in mock log:"
        cat "$mock_log" 2>/dev/null || echo "Log file is empty or doesn't exist"
        return 1
    fi
}

# Assert that no mock calls were made
assert_no_mock_calls() {
    local mock_log="$1"
    
    if [ -f "$mock_log" ] && [ -s "$mock_log" ]; then
        echo "Expected no calls to mock, but found:"
        cat "$mock_log"
        return 1
    fi
}

# Simulate interactive user input
simulate_user_input() {
    local input="$1"
    echo "$input"
}

# Clean up after tests
teardown_utility_tests() {
    # Clean up mock files
    rm -f "$TEST_TEMP_DIR/mock_process_"*
    rm -f "$TEST_TEMP_DIR/"*.log
    
    # Clean up mock project directories
    rm -rf "$MOCK_MYSKY_ROOT"
    rm -rf "$MOCK_DOWNLOADS_DIR"
    rm -rf "$TEST_TEMP_DIR/My stuff"
}

# Create a script mock that can be used to simulate other scripts
create_script_mock() {
    local script_name="$1"
    local script_path="$TEST_TEMP_DIR/$script_name"
    
    cat > "$script_path" << 'EOF'
#!/usr/bin/env bash
echo "$0 $@" >> "$TEST_TEMP_DIR/script_calls.log"
exit 0
EOF
    chmod +x "$script_path"
    echo "$script_path"
}

# Assert file contains expected content
assert_file_contains() {
    local file="$1"
    local expected_content="$2"
    
    if [ ! -f "$file" ]; then
        echo "File '$file' does not exist"
        return 1
    fi
    
    if ! grep -q "$expected_content" "$file"; then
        echo "File '$file' does not contain expected content: '$expected_content'"
        echo "Actual file contents:"
        cat "$file"
        return 1
    fi
}

# Create test copies of launch scripts that use mocked paths
create_mock_launch_scripts() {
    # Copy the real launch_appshell_dev_server.sh to test directory and modify paths
    cp "$UTILITY_SCRIPTS_PATH/launch_appshell_dev_server.sh" "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    # Replace the hardcoded path with our mock path
    sed -i '' "s|/Users/user/Mysky/projects/mysky_app_shell|$MOCK_APPSHELL_DIR|g" "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    # Replace kill builtin with external command to use our mock
    perl -i -pe 's/kill -/command kill -/g' "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"
    
    chmod +x "$TEST_TEMP_DIR/launch_appshell_dev_server.sh"

    # Copy the real launch_spend_dev_server.sh to test directory and modify paths
    cp "$UTILITY_SCRIPTS_PATH/launch_spend_dev_server.sh" "$TEST_TEMP_DIR/launch_spend_dev_server.sh"
    
    # Replace the hardcoded path with our mock path
    sed -i '' "s|/Users/user/Mysky/projects/_spend_front/master|$MOCK_SPEND_DIR|g" "$TEST_TEMP_DIR/launch_spend_dev_server.sh"
    
    # Replace kill builtin with external command to use our mock
    perl -i -pe 's/kill -/command kill -/g' "$TEST_TEMP_DIR/launch_spend_dev_server.sh"
    
    chmod +x "$TEST_TEMP_DIR/launch_spend_dev_server.sh"
}

# Create test environment with all mocks
setup_test_environment() {
    create_mock_mysky_projects
    setup_utility_mocks
    
    # Only create mock launch scripts if not disabled
    if [ "$SKIP_MOCK_LAUNCH_SCRIPTS" != "true" ]; then
        create_mock_launch_scripts
    fi
}