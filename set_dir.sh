#!/bin/bash

# Define the parent directory where subdirectories will be created
parent_dir="$HOME/learning"
echo "Creates a directory : $parent_dir" 

# Check if pyenv is installed
if ! command -v pyenv &> /dev/null
then
    echo "Error: pyenv is not installed. Please install pyenv first."
    exit 1
fi

# Check if Python 3.11 is installed with pyenv
if ! pyenv versions --bare | grep -q "3.11"
then
    echo "Python 3.11 is not installed with pyenv. Attempting to install..."
    pyenv install 3.11
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Python 3.11. Please check your pyenv setup."
        exit 1
    fi
fi

# Create the parent directory if it doesn't exist
mkdir -p "$parent_dir"

# Read names from input, one per line
echo "Enter directory names (one per line). Press Ctrl+D when finished:"
while IFS= read -r name; do
    if [ -z "$name" ]; then
        continue # Skip empty lines
    fi

    # Create the subdirectory
    subdir="$parent_dir/$name"
    mkdir -p "$subdir"
    echo "Created directory: $subdir"

    # Navigate into the subdirectory
    cd "$subdir" || { echo "Error: Could not navigate to $subdir"; continue; }

    # Set Python 3.11 locally using pyenv
    pyenv local 3.11
    echo "Set Python 3.11 locally for $subdir"

    # Create the virtual environment with the same name as the directory
    python -m venv "$name"
    if [ $? -eq 0 ]; then
        echo "Created virtual environment: $name in $subdir"
    else
        echo "Error: Failed to create virtual environment in $subdir"
    fi

    # Navigate back to the script's starting directory
    cd - > /dev/null || exit 1

done

echo "Script finished."