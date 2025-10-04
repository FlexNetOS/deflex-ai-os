#!/bin/bash

# Test script for the complete import functionality
# This will import ONE starred repository as proof of concept

set -e

echo "🧪 Testing complete import functionality with one repository..."

# Create a minimal cache with just one repository for testing
mkdir -p .cache
cat > .cache/starred_rust_repos_page_3.json << 'EOF'
[
  {
    "name": "once_cell",
    "full_name": "matklad/once_cell",
    "description": "Rust library for single assignment cells and lazy values",
    "clone_url": "https://github.com/matklad/once_cell.git",
    "html_url": "https://github.com/matklad/once_cell",
    "default_branch": "master",
    "size": 128,
    "stargazers_count": 1800
  }
]
EOF

echo "📦 Testing import with one repository: matklad/once_cell"

# Create directories if they don't exist
mkdir -p external

# Function to add a submodule (copied from import-repos.sh)
add_submodule() {
    local repo=$1
    local path=$2
    
    if [ ! -d "$path" ]; then
        echo "Adding submodule: $repo -> $path"
        git submodule add "https://github.com/$repo.git" "$path"
    else
        echo "Submodule already exists: $path"
    fi
}

# Import just the test repository
echo "🌟 Importing starred repository..."
jq -r '.[] | "\(.full_name) \(.default_branch // "main")"' .cache/starred_rust_repos_page_3.json | while read -r repo branch; do
    repo_name=$(basename "$repo")
    path="external/starred-$repo_name"
    
    echo "📦 Importing starred repo: $repo"
    add_submodule "$repo" "$path"
    
    # Initialize the submodule to test it works
    echo "🔄 Initializing submodule..."
    git submodule update --init "$path"
    
    # Check if it has expected content
    if [ -f "$path/Cargo.toml" ]; then
        echo "✅ Repository content verified"
        echo "📋 Repository info:"
        head -5 "$path/Cargo.toml"
    else
        echo "❌ Repository content not found"
        exit 1
    fi
    
    echo "🧹 Cleaning up test import..."
    git submodule deinit -f "$path"
    git rm -f "$path"
    rm -rf ".git/modules/$path"
    
    echo "✅ Complete import functionality test: PASSED"
done

# Clean up cache file
rm -f .cache/starred_rust_repos_page_3.json