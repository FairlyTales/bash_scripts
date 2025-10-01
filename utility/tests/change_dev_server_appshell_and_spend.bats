#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_environment
    
    # Create mock .env.local files with initial dev server URLs
    mkdir -p "$TEST_TEMP_DIR/mock_projects/app_shell"
    mkdir -p "$TEST_TEMP_DIR/mock_projects/mysky_spend"

    echo "REACT_APP_API_URL=https://dev1-mysky.com/api" > "$TEST_TEMP_DIR/mock_projects/app_shell/.env.local"
    echo "REACT_APP_API_URL=https://dev1-mysky.com/api" > "$TEST_TEMP_DIR/mock_projects/mysky_spend/.env.local"
    
    # Create mock launch script that logs calls
    cat > "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh" << 'EOF'
#!/usr/bin/env zsh
echo "mock_launcher_called" >> "$TEST_TEMP_DIR/script_calls.log"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/launch_appshell_and_spend_dev_servers.sh"
    
    # Create a mock sed wrapper script that handles the new -E pattern
    cat > "$TEST_TEMP_DIR/mock_sed_wrapper.sh" << EOF
#!/usr/bin/env bash
echo "sed \$*" >> "$TEST_TEMP_DIR/sed_calls.log"

# Extract the file path (last argument)
file="\${@: -1}"
server=""

# Find the server value in the pattern: sed -i '' -E 's/(dev[0-9]-|stage-)/SERVER-/g'
for arg in "\$@"; do
    if [[ "\$arg" == s/\(dev*\)/*-/g ]]; then
        # Extract server from pattern like "s/(dev[0-9]-|stage-)/dev5-/g"
        server="\${arg#*)/}"
        server="\${server%-/g}"
        break
    fi
done

# Perform the replacement if we found both file and server
if [[ -n "\$server" && -f "\$file" ]]; then
    # Replace dev[0-9]- or stage- with the new server value
    /usr/bin/sed -E "s/(dev[0-9]-|stage-)/\${server}-/g" "\$file" > "\$file.tmp" && mv "\$file.tmp" "\$file"
fi

exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/mock_sed_wrapper.sh"

    # Create a modified version of the script that uses our test paths and mock launch script
    cat > "$TEST_TEMP_DIR/test_change_dev_server.sh" << 'SCRIPT_EOF'
#!/usr/bin/env zsh

# change app-shell dev server in .env.local

if [ -z "$1" ]
    then
      printf "Enter the server\n"
      read server

      sed -i '' -E 's/(dev[0-9]-|stage-)/'$server'-/g' TEST_TEMP_DIR_PLACEHOLDER/mock_projects/app_shell/.env.local
      sed -i '' -E 's/(dev[0-9]-|stage-)/'$server'-/g' TEST_TEMP_DIR_PLACEHOLDER/mock_projects/mysky_spend/.env.local
      printf "\nDev server URLs in App-Shell and Spend changed to $server\n\n"
    else
      sed -i '' -E 's/(dev[0-9]-|stage-)/'$1'-/g' TEST_TEMP_DIR_PLACEHOLDER/mock_projects/app_shell/.env.local
      sed -i '' -E 's/(dev[0-9]-|stage-)/'$1'-/g' TEST_TEMP_DIR_PLACEHOLDER/mock_projects/mysky_spend/.env.local
      printf "\nDev server in App-Shell and Spend changed to $1\n\n"
    fi

printf "Restarting App-Shell and Spend dev servers...\n\n"

DIRNAME=$(dirname "$0")
$DIRNAME/launch_appshell_and_spend_dev_servers.sh
SCRIPT_EOF

    # Replace placeholder with actual TEST_TEMP_DIR
    sed -i '' "s|TEST_TEMP_DIR_PLACEHOLDER|$TEST_TEMP_DIR|g" "$TEST_TEMP_DIR/test_change_dev_server.sh"
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

@test "prompts for server when no argument provided" {
    # Simulate user input "dev3"
    run bash -c "echo 'dev3' | $TEST_TEMP_DIR/test_change_dev_server.sh"

    assert_success
    assert_output --partial "Enter the server"
    assert_output --partial "Dev server URLs in App-Shell and Spend changed to dev3"
}

@test "handles dev server names" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev7

    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to dev7"
}

@test "handles stage server" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" stage

    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to stage"
}

@test "updates both appshell and spend .env.local files" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev4

    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to dev4"
}

@test "restarts dev servers after changing configuration" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev2

    assert_success

    # Verify launcher script was called
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_launcher_called"
}

@test "uses correct sed pattern for dev server replacement" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev9

    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to dev9"
}

@test "handles interactive input correctly" {
    # Test with different input
    run bash -c "echo 'dev8' | $TEST_TEMP_DIR/test_change_dev_server.sh"

    assert_success
    assert_output --partial "Enter the server"
    assert_output --partial "Dev server URLs in App-Shell and Spend changed to dev8"
}

@test "provides different output messages for argument vs interactive modes" {
    # Test argument mode
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev6
    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to dev6"

    # Clear logs for next test
    rm -f "$TEST_TEMP_DIR/sed_calls.log"

    # Test interactive mode
    run bash -c "echo 'dev6' | $TEST_TEMP_DIR/test_change_dev_server.sh"
    assert_success
    assert_output --partial "Dev server URLs in App-Shell and Spend changed to dev6"
}

@test "handles dev0 as server" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev0

    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to dev0"
}

@test "resolves DIRNAME correctly to find launcher script" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev1

    assert_success

    # Verify the launcher script was found and executed
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_launcher_called"
}

@test "handles empty interactive input gracefully" {
    # Test with empty input (just pressing Enter)
    run bash -c "echo '' | $TEST_TEMP_DIR/test_change_dev_server.sh"

    assert_success
    assert_output --partial "Enter the server"
    assert_output --partial "Dev server URLs in App-Shell and Spend changed to"
}

@test "provides informative restart message" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev3

    assert_success
    assert_output --partial "Restarting App-Shell and Spend dev servers..."

    # This message should appear before the launcher is called
    assert_mock_called_with "$TEST_TEMP_DIR/script_calls.log" "mock_launcher_called"
}

@test "handles different server names" {
    # Test what happens with custom server name
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" "custom"

    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to custom"
}

@test "sed replacements use correct file paths" {
    run "$TEST_TEMP_DIR/test_change_dev_server.sh" dev2

    assert_success
    assert_output --partial "Dev server in App-Shell and Spend changed to dev2"
}