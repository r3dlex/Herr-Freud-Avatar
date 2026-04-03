#!/bin/bash
# Manually process a file through Herr Freud
# Usage: ./scripts/process-input.sh <file_path>

FILE_PATH="${1:-}"

if [ -z "$FILE_PATH" ]; then
    echo "Usage: $0 <file_path>"
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi

echo "Processing: $FILE_PATH"

# Copy to input directory
INPUT_DIR="./data/input"
mkdir -p "$INPUT_DIR"

cp "$FILE_PATH" "$INPUT_DIR/"

echo "Copied to $INPUT_DIR/"
echo "Input.Watcher will process it within 2 seconds"
