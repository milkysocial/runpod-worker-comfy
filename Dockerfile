# Stage 1: Base image with common dependencies
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 AS base
# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1 \
    && ln -sf /usr/bin/python3.10 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install comfy-cli
RUN pip install comfy-cli

# Install ComfyUI
RUN /usr/bin/yes | comfy --workspace /comfyui install --cuda-version 11.8 --nvidia --version 0.2.7

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install runpod
RUN pip install runpod requests

# Copy additional configuration and scripts
ADD src/extra_model_paths.yaml ./src/extra_model_paths.yaml
ADD src/install_custom_nodes.py ./src/install_custom_nodes.py
ADD src/start.sh ./start.sh
ADD src/rp_handler.py ./rp_handler.py
ADD test_input.json ./test_input.json
ADD src/custom_nodes_essentials_pack.json ./src/custom_nodes_essentials_pack.json

RUN chmod +x ./start.sh

# Debug: List files in /comfyui/src to ensure everything is copied
RUN ls -la ./src

# Install custom nodes
RUN python src/install_custom_nodes.py

# Set the default command to start the container
CMD ["/start.sh"]
