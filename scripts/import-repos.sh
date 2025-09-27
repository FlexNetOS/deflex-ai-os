#!/bin/bash

# Import starred repositories script
# Usage: ./scripts/import-repos.sh [--starred-page PAGE]

set -e

echo "🚀 Starting repository import process..."

# Create directories if they don't exist
mkdir -p vendor external

# Parse command line arguments
IMPORT_STARRED=false
STARRED_PAGE=3

while [[ $# -gt 0 ]]; do
    case $1 in
        --starred-page)
            IMPORT_STARRED=true
            STARRED_PAGE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to add a subtree
add_subtree() {
    local repo=$1
    local path=$2
    local branch=${3:-main}
    
    if [ ! -d "$path" ]; then
        echo "Adding subtree: $repo -> $path"
        git subtree add --prefix="$path" "https://github.com/$repo.git" "$branch" --squash
    else
        echo "Subtree already exists: $path"
    fi
}

# Function to add a submodule
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

# Function to import starred repositories
import_starred_repos() {
    local page=$1
    local cache_file=".cache/starred_rust_repos_page_${page}.json"
    
    if [ ! -f "$cache_file" ]; then
        echo "📡 Fetching starred repositories for page $page..."
        ./scripts/fetch-starred-repos.sh "$page"
    fi
    
    if [ ! -f "$cache_file" ]; then
        echo "❌ Failed to fetch starred repositories"
        return 1
    fi
    
    echo "🌟 Importing starred Rust repositories from page $page..."
    
    # Read repositories from cache file and import them
    jq -r '.[] | "\(.full_name) \(.default_branch // "main")"' "$cache_file" | while read -r repo branch; do
        # Determine if it should be a subtree or submodule based on size or other criteria
        # For now, we'll use submodules for starred repos to keep them separate
        local repo_name=$(basename "$repo")
        local path="external/starred-$repo_name"
        
        echo "📦 Importing starred repo: $repo"
        add_submodule "$repo" "$path"
    done
}

# Import starred repositories if requested
if [ "$IMPORT_STARRED" = true ]; then
    import_starred_repos "$STARRED_PAGE"
fi

# Priority imports - Core infrastructure
echo "📦 Importing core infrastructure..."
add_subtree "cloudflare/pingora" "vendor/pingora" "main"
add_subtree "modelcontextprotocol/rust-sdk" "vendor/mcp-rust" "main"

# ML/AI frameworks
echo "🤖 Importing ML/AI frameworks..."
add_submodule "huggingface/candle" "external/candle"
add_submodule "tracel-ai/burn" "external/burn"
add_submodule "ggml-org/llama.cpp" "external/llama-cpp"

# Agent frameworks
echo "🎯 Importing agent frameworks..."
add_submodule "letta-ai/letta" "external/letta"
add_submodule "browser-use/browser-use" "external/browser-use"
add_submodule "All-Hands-AI/OpenHands" "external/openhands"

# Data tools
echo "💾 Importing data tools..."
add_subtree "apache/datafusion" "vendor/datafusion" "main"
add_submodule "duckdb/duckdb" "external/duckdb"
add_submodule "qdrant/rust-client" "external/qdrant-client"

# Development tools
echo "🛠️ Importing development tools..."
add_submodule "Aider-AI/aider" "external/aider"
add_submodule "firecrawl/firecrawl" "external/firecrawl"

echo "✅ Repository import complete!"
echo "Run 'git submodule update --init --recursive' to initialize all submodules"