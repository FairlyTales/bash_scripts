#!/usr/bin/env bash

# Load bats helper libraries
load "../../test/bats-helpers/bats-support/load"
load "../../test/bats-helpers/bats-assert/load"
load "../../test/bats-helpers/bats-file/load"

# Set paths
export ROOT_SCRIPTS_PATH="/Users/user/bash_scripts"
export IDE_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/ide"
export TEST_TEMP_DIR="$BATS_TEST_TMPDIR"

# Create mock IDE commands
setup_ide_mocks() {
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    # Clear any existing logs
    rm -f "$TEST_TEMP_DIR/ide_calls.log"
    
    # Create mock cursor command
    cat > "$TEST_TEMP_DIR/cursor" << 'EOF'
#!/usr/bin/env bash
echo "cursor $@" >> "$TEST_TEMP_DIR/ide_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/cursor"
    
    # Create mock webstorm command
    cat > "$TEST_TEMP_DIR/webstorm" << 'EOF'
#!/usr/bin/env bash
echo "webstorm $@" >> "$TEST_TEMP_DIR/ide_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/webstorm"
}

# Create failing mock IDE commands for error testing
setup_failing_ide_mocks() {
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    # Clear any existing logs
    rm -f "$TEST_TEMP_DIR/ide_calls.log"
    
    # Create failing mock cursor command
    cat > "$TEST_TEMP_DIR/cursor" << 'EOF'
#!/usr/bin/env bash
echo "cursor $@" >> "$TEST_TEMP_DIR/ide_calls.log"
echo "Error: Failed to launch Cursor" >&2
exit 1
EOF
    chmod +x "$TEST_TEMP_DIR/cursor"
    
    # Create failing mock webstorm command
    cat > "$TEST_TEMP_DIR/webstorm" << 'EOF'
#!/usr/bin/env bash
echo "webstorm $@" >> "$TEST_TEMP_DIR/ide_calls.log"
echo "Error: Failed to launch WebStorm" >&2
exit 1
EOF
    chmod +x "$TEST_TEMP_DIR/webstorm"
}

# Assert that mock IDE was called with specific arguments
assert_ide_called_with() {
    local expected_call="$1"
    local mock_log="$TEST_TEMP_DIR/ide_calls.log"
    
    if [ ! -f "$mock_log" ]; then
        echo "IDE mock log file '$mock_log' does not exist"
        return 1
    fi
    
    if ! grep -q "$expected_call" "$mock_log"; then
        echo "Expected IDE call '$expected_call' not found in mock log:"
        cat "$mock_log"
        return 1
    fi
}

# Assert that no IDE calls were made
assert_no_ide_calls() {
    local mock_log="$TEST_TEMP_DIR/ide_calls.log"
    
    if [ -f "$mock_log" ] && [ -s "$mock_log" ]; then
        echo "Expected no IDE calls, but found:"
        cat "$mock_log"
        return 1
    fi
}

# Create test directory with special characters for path testing
create_special_path_test_dir() {
    local test_dir="$TEST_TEMP_DIR/test dir with spaces & special chars"
    mkdir -p "$test_dir"
    echo "$test_dir"
}

# Clean up test environment
teardown_ide_test() {
    # Clean up any test directories
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -f "$TEST_TEMP_DIR/ide_calls.log"
        rm -f "$TEST_TEMP_DIR/cursor"
        rm -f "$TEST_TEMP_DIR/webstorm"
    fi
}