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

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Go back to the root
WORKDIR /


# Add scripts
ADD src/start.sh src/restore_snapshot.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh /restore_snapshot.sh

# Optionally copy the snapshot file
#ADD *snapshot*.json /
#ADD impact-pack-essentials_snapshot.json /

# Restore the snapshot to install custom nodes

RUN python src/install_custom_nodes.py
#RUN /restore_snapshot.sh
# Start container
CMD ["/start.sh"]

# Stage 2: Download models
#FROM base AS downloader

#ARG HUGGINGFACE_ACCESS_TOKEN
#ARG MODEL_TYPE

# Change working directory to ComfyUI
#WORKDIR /comfyui
# lance commande python pour executer le fichier src/install_custom_nodes.json
#RUN python -c "from comfyui import download_model; download_model('huggingface', 'facebook/bart-large-cnn', '/comfyui/models')"

# Stage 3: Final image
#FROM base AS final

# Copy models from stage 2 to the final image
#COPY --from=downloader /comfyui/models /comfyui/models

# Start container
#CMD ["/start.sh"]

