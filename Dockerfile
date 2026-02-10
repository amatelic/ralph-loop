# Multi-runtime base image with both Node.js and Python
FROM node:20-bullseye

# Install Python 3.12
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic links for python/python3
RUN ln -s /usr/bin/python3.12 /usr/bin/python

# Install GLM-4.7 CLI tool
RUN npm install -g @zhipuai/glm-cli

# Set working directory
WORKDIR /workspace

# Default command
CMD ["bash", "/workspace/loop.sh"]
