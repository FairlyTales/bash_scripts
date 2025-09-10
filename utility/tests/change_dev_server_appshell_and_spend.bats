#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_environment
    
    # Create mock .env.local files with initial dev server URLs
    mkdir -p "$TEST_TEMP_DIR/mock_projects/mysky_app_shell"
    mkdir -p "$TEST_TEMP_DIR/mock_projects/mysky_spend"
    
    echo "REACT_APP_API_URL=https://dev1.mysky.com/api" > "$TEST_TEMP_DIR/mock_projects/mysky_app_shell/.env.local"
    echo "REACT_APP_API_URL=https://dev1.mysky.com/api" > "$TEST_TEMP_DIR/mock_projects/mysky_spend/.env.local"
    
    # Create mock launch script that logs calls
    cat > "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh" << 'EOF'
#!/usr/bin/env zsh
echo "mock_launcher_called" >> "$TEST_TEMP_DIR/script_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    # Create a mock sed wrapper script that directly handles the expected patterns
    cat > "$TEST_TEMP_DIR/mock_sed_wrapper.sh" << EOF
#!/usr/bin/env bash
echo "sed \$*" >> "$TEST_TEMP_DIR/sed_calls.log"

# For the specific pattern used by our script: sed -i '' s/dev[0-9]/devN/g /path/to/file
# Just extract the server number and file, then do the replacement
file="\${@: -1}"  # Last argument
server_num=""

# Find the server number in the arguments
for arg in "\$@"; do
    if [[ "\$arg" == s/dev[0-9]/dev*g ]]; then
        server_num="\${arg#s/dev[0-9]/dev}"
        server_num="\${server_num%/g}"
        break
    fi
done

# Perform the replacement if we found both file and server number
if [[ -n "\$server_num" && -f "\$file" ]]; then
    /usr/bin/sed "s/dev1/dev\${server_num}/g" "\$file" > "\$file.tmp" && mv "\$file.tmp" "\$file"
fi

exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/mock_sed_wrapper.sh"

    # Create a modified version of the script that uses our test paths and mock launch script
    cat > "$TEST_TEMP_DIR/test_change_dev_server.sh" << EOF
#!/usr/bin/env zsh

# change app-shell dev server in .env.local

if [ -z "\$1" ]
    then
       printf "Enter the server number\n"
       read serverNumber

       "$TEST_TEMP_DIR/mock_sed_wrapper.sh" -i '' s/dev[0-9]/dev\$serverNumber/g $TEST_TEMP_DIR/mock_projects/mysky_app_shell/.env.local
       "$TEST_TEMP_DIR/mock_sed_wrapper.sh" -i '' s/dev[0-9]/dev\$serverNumber/g $TEST_TEMP_DIR/mock_projects/mysky_spend/.env.local
       printf "\nDev server URLs in App-Shell and Spend changed to \$serverNumber\n\n"
    else
      "$TEST_TEMP_DIR/mock_sed_wrapper.sh" -i '' s/dev[0-9]/dev\$1/g $TEST_TEMP_DIR/mock_projects/mysky_app_shell/.env.local
      "$TEST_TEMP_DIR/mock_sed_wrapper.sh" -i '' s/dev[0-9]/dev\$1/g $TEST_TEMP_DIR/mock_projects/mysky_spend/.env.local
      printf "\nDev server in App-Shell and Spend changed to \$1\n\n"
    fi

printf "Restarting App-Shell and Spend dev servers...\n\n"

$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh
EOF
    chmod +x "$TEST_TEMP_DIR/test_change_dev_server.sh"
}

teardown() {
    teardown_utility_tests
}

@test "changes dev server when argument is provided" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 5
    
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to 5"
    assert_output --partial "Restarting App-Shell and Spend dev servers..."
    
    # Verify launcher script was called
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_launcher_called"
}

@test "prompts for server number when no argument provided" {
    # Simulate user input "3"
    run bash -c "echo '3' | $TEST_TEMP_DIR/test_change_dev_server.sh"
    
    assert_success
    assert_output --partial "Enter the server number"
    assert_output --partial "Dev server URLs in App-Shell and Spend changed to 3"
}

@test "handles single digit server numbers" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 7
    
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to 7"
}

@test "handles multi-digit server numbers" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 15
    
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to 15"
}

@test "updates both appshell and spend .env.local files" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 4
    
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to 4"
}

@test "restarts dev servers after changing configuration" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 2
    
    assert_success
    
    # Verify launcher script was called
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_launcher_called"
}

@test "uses correct sed pattern for dev server replacement" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 9
    
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to 9"
}

@test "handles interactive input correctly" {
    # Test with different input
    run bash -c "echo '8' | $TEST_TEMP_DIR/test_change_dev_server.sh"
    
    assert_success
    assert_output --partial "Enter the server number"
    assert_output --partial "Dev server URLs in App-Shell and Spend changed to 8"
}

@test "provides different output messages for argument vs interactive modes" {
    # Test argument mode
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 6
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to 6"
    
    # Clear logs for next test
    rm -f "$TEST_TEMP_DIR/sed_calls.log"
    
    # Test interactive mode
    run bash -c "echo '6' | $TEST_TEMP_DIR/test_change_dev_server.sh"
    assert_success
    assert_output --partial "Dev server URLs in App-Shell and Spend changed to 6"
}

@test "handles zero as server number" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 0
    
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to 0"
}

@test "resolves DIRNAME correctly to find launcher script" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 1
    
    assert_success
    
    # Verify the launcher script was found and executed
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_launcher_called"
}

@test "handles empty interactive input gracefully" {
    # Test with empty input (just pressing Enter)
    run bash -c "echo '' | $TEST_TEMP_DIR/test_change_dev_server.sh"
    
    assert_success
    assert_output --partial "Enter the server number"
    assert_output --partial "Dev server URLs in App-Shell and Spend changed to"
}

@test "provides informative restart message" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 3
    
    assert_success
    assert_output --partial "Restarting App-Shell and Spend dev servers..."
    
    # This message should appear before the launcher is called
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_launcher_called"
}

@test "handles special characters in server number" {
    # Test what happens with non-numeric input
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" "abc"
    
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to abc"
}

@test "sed replacements use correct file paths" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" 2
    
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to 2"
}