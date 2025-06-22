#!/bin/bash

# Export prompt library entries to Downloads folder
# This script copies all entries from the prompt_library directory to exported-prompts in Downloads

SOURCE_DIR="/Users/user/My stuff/Coding/llm_stuff/prompt_library/prompt_library"
DEST_DIR="/Users/user/Downloads/exported-prompts"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    echo "Creating destination directory: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# Copy all contents from source to destination without subdirectories
echo "Exporting prompt library entries..."
echo "From: $SOURCE_DIR"
echo "To: $DEST_DIR"

# Find all files recursively and copy them to destination directory (flattened)
find "$SOURCE_DIR" -type f -exec cp {} "$DEST_DIR/" \;

if [ $? -eq 0 ]; then
    echo "✅ Successfully exported prompt library entries to $DEST_DIR"
    echo "📁 All files have been copied to a single directory without subdirectories"
else
    echo "❌ Error occurred during export"
    exit 1
fi 