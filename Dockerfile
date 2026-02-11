# Multi-runtime base image with both Node.js and Python
FROM node:20-bookworm-slim

# Install build dependencies for Python
RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.12 from source
RUN wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz \
    && tar -xzf Python-3.12.0.tgz \
    && cd Python-3.12.0 \
    && ./configure --enable-optimizations \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf Python-3.12.0 Python-3.12.0.tgz

# Create symbolic links for python/python3
RUN ln -sf /usr/local/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 \
    && ln -sf /usr/local/bin/pip3.12 /usr/local/bin/pip \
    && ln -sf /usr/local/bin/pip3.12 /usr/local/bin/pip3

# Set working directory
WORKDIR /workspace

# Default command
CMD ["bash", "/workspace/loop.sh"]
