# Multi-stage build for optimal Docker image size
FROM rust:1.81-slim as builder

# Install system dependencies needed for building
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy workspace files
COPY Cargo.toml ./
COPY services/api/Cargo.toml ./services/api/

# Create dummy source files to build dependencies first (for better caching)
RUN mkdir -p services/api/src && \
    echo "fn main() {}" > services/api/src/main.rs

# Build dependencies (this layer will be cached)
RUN cargo build --bin api-gateway --release
RUN rm services/api/src/main.rs

# Copy actual source code
COPY services/api/src ./services/api/src

# Build the actual application
RUN touch services/api/src/main.rs && \
    cargo build --bin api-gateway --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy the binary from builder stage
COPY --from=builder /app/target/release/api-gateway /usr/local/bin/api-gateway

# Change ownership to non-root user
RUN chown appuser:appuser /usr/local/bin/api-gateway

# Switch to non-root user
USER appuser

# Expose the port that the app runs on
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Run the binary
CMD ["api-gateway"]