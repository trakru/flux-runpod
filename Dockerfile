FROM runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04
WORKDIR /content

# Define build argument for username (defaulting to original value if not provided)
ARG USERNAME=comfyuser
ARG HF_REPO=pretentioushorsefly/flux-models
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"
ENV MODEL_BASE_URL="https://huggingface.co/${HF_REPO}/resolve/main/models"

# User setup (keeping original permissions)
RUN adduser --disabled-password --gecos '' ${USERNAME} && \
    adduser ${USERNAME} sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R ${USERNAME}:${USERNAME} /content && \
    chmod -R 777 /content && \
    chown -R ${USERNAME}:${USERNAME} /home && \
    chmod -R 777 /home

# Install dependencies (keeping original packages)
RUN apt update -y && add-apt-repository -y ppa:git-core/ppa && apt update -y && apt install -y aria2 git git-lfs unzip ffmpeg

# Switch to user
USER ${USERNAME}

# Install Python packages (keeping original versions)
RUN pip install -q opencv-python imageio imageio-ffmpeg ffmpeg-python av runpod \
    xformers==0.0.25 torchsde==0.2.6 einops==0.8.0 diffusers==0.28.0 transformers==4.41.2 accelerate==0.30.1

# Clone repositories
RUN git clone https://github.com/comfyanonymous/ComfyUI /content/ComfyUI && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager /content/ComfyUI/custom_nodes/ComfyUI-Manager && \
    git clone https://github.com/ciri/comfyui-model-downloader /content/ComfyUI/custom_nodes/comfyui-model-downloader


# Download models
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M ${MODEL_BASE_URL}/unet/flux1-dev.safetensors -d /content/ComfyUI/models/unet -o flux1-dev.safetensors && \
    aria2c --console-log-level=error -c -x 16 -s 16 -k 1M ${MODEL_BASE_URL}/vae/ae.safetensors -d /content/ComfyUI/models/vae -o ae.safetensors && \
    aria2c --console-log-level=error -c -x 16 -s 16 -k 1M ${MODEL_BASE_URL}/clip/clip_l.safetensors -d /content/ComfyUI/models/clip -o clip_l.safetensors && \
    aria2c --console-log-level=error -c -x 16 -s 16 -k 1M ${MODEL_BASE_URL}/clip/t5xxl_fp16.safetensors -d /content/ComfyUI/models/clip -o t5xxl_fp16.safetensors

# Set working directory and command
WORKDIR /content/ComfyUI
CMD python main.py --listen --port 7860