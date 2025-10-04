#!/bin/bash

# Test script for repository import functionality
# This tests the scripts without actually cloning repositories

set -e

echo "🧪 Testing repository import functionality..."

# Test 1: Fetch starred repositories
echo "📋 Test 1: Fetching starred repositories..."
if ./scripts/fetch-starred-repos.sh 3; then
    echo "✅ Fetch starred repositories: PASSED"
else
    echo "❌ Fetch starred repositories: FAILED"
    exit 1
fi

# Test 2: Check cache file exists and is valid JSON
echo "📋 Test 2: Validating cache file..."
CACHE_FILE=".cache/starred_rust_repos_page_3.json"
if [ -f "$CACHE_FILE" ] && jq empty < "$CACHE_FILE" 2>/dev/null; then
    echo "✅ Cache file validation: PASSED"
    echo "   Found $(jq length < "$CACHE_FILE") repositories"
else
    echo "❌ Cache file validation: FAILED"
    exit 1
fi

# Test 3: Parse repository data
echo "📋 Test 3: Parsing repository data..."
echo "   Repositories that would be imported:"
jq -r '.[] | "   - " + .full_name + " (" + (.description // "No description") + ")"' < "$CACHE_FILE"

# Test 4: Workspace still builds after our changes
echo "📋 Test 4: Testing workspace build..."
if cargo check --quiet; then
    echo "✅ Workspace build: PASSED"
else
    echo "❌ Workspace build: FAILED"
    exit 1
fi

echo "🎉 All tests passed! Repository import functionality is ready."
echo "💡 To actually import repositories, run:"
echo "   ./scripts/import-repos.sh --starred-page 3"