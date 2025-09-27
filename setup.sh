#!/bin/bash

echo "🚀 Setting up FlexNetOS/star-mono repository..."

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ] || [ ! -d "services" ]; then
    echo "❌ Please run this script from the root of the star-mono repository"
    exit 1
fi

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "📦 Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "✅ Rust toolchain found"
fi

# Build the workspace
echo "🔨 Building workspace..."
cargo build --workspace

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    exit 1
fi

# Test the API service
echo "🧪 Testing API service..."
cargo run --bin api-gateway &
API_PID=$!
sleep 3

# Test health endpoint
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ API service is working!"
else
    echo "⚠️  API service test failed (this is normal if port 3000 is busy)"
fi

# Stop the API service
kill $API_PID 2>/dev/null

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run './scripts/import-repos.sh' to import external repositories"
echo "2. Run 'cargo run --bin api-gateway' to start the API service"
echo "3. Test with: curl http://localhost:3000/health"
echo ""
echo "For more information, see README.md"