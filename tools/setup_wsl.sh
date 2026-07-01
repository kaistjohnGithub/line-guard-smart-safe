#!/bin/bash
set -e

MAMBA="/tmp/bin/micromamba"
ENV_NAME="vila-safety-wsl"
PROJECT="/mnt/d/3.KMITL_ai/projects/4_Denso Smart Factory Smart Safety/line-guard-smart-safe"

echo "=== Step 1: Create environment ==="
$MAMBA create -n $ENV_NAME python=3.10 -y -c conda-forge

echo "=== Step 2: Install PyTorch (CUDA 12.1) ==="
$MAMBA run -n $ENV_NAME pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

echo "=== Step 3: Install project dependencies ==="
$MAMBA run -n $ENV_NAME pip install \
  transformers==4.47.1 \
  qwen-vl-utils \
  fastapi \
  uvicorn \
  opencv-python \
  pillow \
  requests \
  accelerate \
  bitsandbytes \
  sentencepiece

echo "=== Step 4: Install flash-attn ==="
$MAMBA run -n $ENV_NAME pip install flash-attn --no-build-isolation

echo "=== Done! Test with: ==="
echo "USE_FLASH_ATTN=1 $MAMBA run -n $ENV_NAME python '$PROJECT/tools/qwen_service.py'"
