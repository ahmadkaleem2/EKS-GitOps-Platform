# FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime #x86_64
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu22.04

WORKDIR /app

# Python and system libraries required by OpenCV/Ultralytics
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        libglib2.0-0 \
        libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
# RUN python3 -m pip install --upgrade pip

# Install CUDA-enabled PyTorch
RUN pip3 install --no-cache-dir \
    torch==2.11.0 \
    torchvision==0.26.0 \
    torchaudio==2.11.0 \
    --index-url https://download.pytorch.org/whl/cu128

# Install application dependencies
COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

# Worker application
COPY worker.py .

CMD ["python3", "worker.py"]