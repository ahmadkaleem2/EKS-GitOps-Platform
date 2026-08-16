FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

WORKDIR /app

# System libraries required by OpenCV/Ultralytics
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libglib2.0-0 \
        libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Application dependencies
COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

# Worker application
COPY worker.py .

CMD ["python3", "worker.py"]

# FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04

# WORKDIR /app

# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#         python3 \
#         python3-pip \
#         libglib2.0-0 \
#         libgl1 \
#     && rm -rf /var/lib/apt/lists/*

# RUN python3 -m pip install --no-cache-dir \
#     torch==2.11.0 \
#     torchvision==0.26.0 \
#     torchaudio==2.11.0 \
#     --index-url https://download.pytorch.org/whl/cu126

# COPY requirements.txt .

# RUN python3 -m pip install --no-cache-dir \
#     -r requirements.txt

# COPY worker.py .

# CMD ["python3", "worker.py"]