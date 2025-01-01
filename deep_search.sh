#!/bin/bash

# Define the root directory to search
ROOT_DIR="/Users/sagi/Desktop/terraform/git/ecs_auto_deployment-"

# Search for files critical for Buildpack detection
echo "Searching for Buildpack-related files in: $ROOT_DIR"

# List of Buildpack detection files/extensions
declare -a FILE_PATTERNS=("package.json" "requirements.txt" "Gemfile" "*.py" "*.js" "*.go" "*.rb")

# Loop through the patterns and search
for pattern in "${FILE_PATTERNS[@]}"; do
    echo "Searching for: $pattern"
    find "$ROOT_DIR" -type f -name "$pattern"
done

