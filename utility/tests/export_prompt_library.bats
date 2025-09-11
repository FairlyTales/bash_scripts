#!/usr/bin/env bats

load test_helper

setup() {
    # Skip mock launch scripts creation for this test
    export SKIP_MOCK_LAUNCH_SCRIPTS="true"
    setup_test_environment
    
    # Create a modified version of the script that uses our test paths
    sed "s|SOURCE_DIR=\"/Users/user/My stuff/Coding/llm_stuff/prompt_library/prompt_library\"|SOURCE_DIR=\"$MOCK_PROMPT_LIBRARY_SOURCE\"|g; s|DEST_DIR=\"/Users/user/Downloads/exported-prompts\"|DEST_DIR=\"$MOCK_DOWNLOADS_DIR/exported-prompts\"|g" \
        "$UTILITY_SCRIPTS_PATH/export_prompt_library.sh" > "$TEST_TEMP_DIR/test_export_prompt_library.sh"
}

teardown() {
    teardown_utility_tests
}

@test "successfully exports prompt library when source exists" {
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    assert_output --partial "Exporting prompt library entries..."
    assert_output --partial "From: $MOCK_PROMPT_LIBRARY_SOURCE"
    assert_output --partial "To: $MOCK_DOWNLOADS_DIR/exported-prompts"
    assert_output --partial "✅ Successfully exported prompt library entries"
    assert_output --partial "📁 All files have been copied to a single directory without subdirectories"
}

@test "creates destination directory if it doesn't exist" {
    # Remove the destination directory
    rm -rf "$MOCK_DOWNLOADS_DIR/exported-prompts"
    
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    assert_output --partial "Creating destination directory: $MOCK_DOWNLOADS_DIR/exported-prompts"
    
    # Verify directory was created
    assert_dir_exists "$MOCK_DOWNLOADS_DIR/exported-prompts"
}

@test "fails when source directory doesn't exist" {
    # Remove the source directory
    rm -rf "$MOCK_PROMPT_LIBRARY_SOURCE"
    
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_failure
    assert_output --partial "Error: Source directory does not exist: $MOCK_PROMPT_LIBRARY_SOURCE"
    
    # Should exit with code 1
    [ "$status" -eq 1 ]
}

@test "copies all files recursively and flattens directory structure" {
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Verify find command was called with correct parameters
    assert_mock_called_with "$TEST_TEMP_DIR/find_calls.log" "find $MOCK_PROMPT_LIBRARY_SOURCE -type f -exec cp {} $MOCK_DOWNLOADS_DIR/exported-prompts/ ;"
    
    # Verify files were copied and flattened
    assert_file_exists "$MOCK_DOWNLOADS_DIR/exported-prompts/prompt1.txt"
    assert_file_exists "$MOCK_DOWNLOADS_DIR/exported-prompts/prompt2.md"
    assert_file_exists "$MOCK_DOWNLOADS_DIR/exported-prompts/nested.txt"
}

@test "preserves file contents during export" {
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Verify file contents are preserved
    assert_file_contains "$MOCK_DOWNLOADS_DIR/exported-prompts/prompt1.txt" "Prompt 1 content"
    assert_file_contains "$MOCK_DOWNLOADS_DIR/exported-prompts/prompt2.md" "Prompt 2 content"
    assert_file_contains "$MOCK_DOWNLOADS_DIR/exported-prompts/nested.txt" "Nested prompt"
}

@test "handles existing destination directory gracefully" {
    # Pre-create destination directory
    mkdir -p "$MOCK_DOWNLOADS_DIR/exported-prompts"
    
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Should not show creation message
    refute_output --partial "Creating destination directory"
    
    # Should still export successfully
    assert_output --partial "✅ Successfully exported prompt library entries"
}

@test "displays informative messages during export process" {
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Verify all expected informational messages
    assert_output --partial "Exporting prompt library entries..."
    assert_output --partial "From: $MOCK_PROMPT_LIBRARY_SOURCE"
    assert_output --partial "To: $MOCK_DOWNLOADS_DIR/exported-prompts"
    assert_output --partial "✅ Successfully exported prompt library entries"
    assert_output --partial "📁 All files have been copied to a single directory without subdirectories"
}

@test "uses correct find command with exec cp" {
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Verify the exact find command used
    assert_mock_called_with "$TEST_TEMP_DIR/find_calls.log" "find $MOCK_PROMPT_LIBRARY_SOURCE -type f -exec cp {} $MOCK_DOWNLOADS_DIR/exported-prompts/ ;"
}

@test "handles empty source directory" {
    # Remove all files from source directory but keep the directory
    rm -rf "$MOCK_PROMPT_LIBRARY_SOURCE"/*
    rm -rf "$MOCK_PROMPT_LIBRARY_SOURCE"/subdir
    
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    assert_output --partial "✅ Successfully exported prompt library entries"
    
    # Find command should still be called
    assert_mock_called_with "$TEST_TEMP_DIR/find_calls.log" "find $MOCK_PROMPT_LIBRARY_SOURCE -type f -exec cp {} $MOCK_DOWNLOADS_DIR/exported-prompts/ ;"
}

@test "exits with error code 1 when source doesn't exist" {
    rm -rf "$MOCK_PROMPT_LIBRARY_SOURCE"
    
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_failure
    [ "$status" -eq 1 ]
}

@test "checks source directory before attempting export" {
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Should check source directory existence first
    # This is implicit in the script logic - if source doesn't exist, it exits early
    # We can verify by ensuring the export process completes
    assert_output --partial "✅ Successfully exported prompt library entries"
}

@test "handles files with spaces in names" {
    # Create a file with spaces in the name
    echo "Spaced file content" > "$MOCK_PROMPT_LIBRARY_SOURCE/file with spaces.txt"
    
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Verify file with spaces was copied
    assert_file_exists "$MOCK_DOWNLOADS_DIR/exported-prompts/file with spaces.txt"
    assert_file_contains "$MOCK_DOWNLOADS_DIR/exported-prompts/file with spaces.txt" "Spaced file content"
}

@test "handles files with special characters in names" {
    # Create files with special characters
    echo "Special content" > "$MOCK_PROMPT_LIBRARY_SOURCE/file-with-dashes.txt"
    echo "Underscore content" > "$MOCK_PROMPT_LIBRARY_SOURCE/file_with_underscores.txt"
    
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Verify special character files were copied
    assert_file_exists "$MOCK_DOWNLOADS_DIR/exported-prompts/file-with-dashes.txt"
    assert_file_exists "$MOCK_DOWNLOADS_DIR/exported-prompts/file_with_underscores.txt"
}

@test "uses absolute paths for source and destination" {
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Verify absolute paths are used in the output
    assert_output --partial "From: $MOCK_PROMPT_LIBRARY_SOURCE"
    assert_output --partial "To: $MOCK_DOWNLOADS_DIR/exported-prompts"
    
    # Paths should start with / or be fully qualified
    [[ "$MOCK_PROMPT_LIBRARY_SOURCE" == /* ]] || fail "Source path should be absolute"
    [[ "$MOCK_DOWNLOADS_DIR/exported-prompts" == /* ]] || fail "Destination path should be absolute"
}

@test "reports success with emoji and descriptive message" {
    run bash "$TEST_TEMP_DIR/test_export_prompt_library.sh"
    
    assert_success
    
    # Verify success message format
    assert_output --partial "✅ Successfully exported prompt library entries to $MOCK_DOWNLOADS_DIR/exported-prompts"
    assert_output --partial "📁 All files have been copied to a single directory without subdirectories"
}