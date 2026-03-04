# Production Dockerfile for rampancy_assault_corps_server
# Multi-stage build for minimal image size

# Build stage
FROM ubuntu:22.04 AS build

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:$PATH"
RUN flutter doctor
RUN flutter config --enable-linux-desktop

# Set up work directory
WORKDIR /app

# Copy models if it exists
COPY rampancy_assault_corps_models/ /rampancy_assault_corps_models/

# Copy server source
COPY rampancy_assault_corps_server/ /app/

# Get dependencies and build
RUN flutter pub get
RUN flutter build linux --release

# Runtime stage
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libgtk-3-0 \
    libblkid1 \
    liblzma5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built binary from build stage
COPY --from=build /app/build/linux/x64/release/bundle/ ./

# Copy service account key
COPY rampancy_assault_corps_server/*.json ./

# Expose port
EXPOSE 8080

# Run the server
CMD ["./rampancy_assault_corps_server"]
