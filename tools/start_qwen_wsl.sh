#!/bin/bash
PYTHON="/home/ubuntu/.local/share/mamba/envs/vila-safety-wsl/bin/python"
PROJECT="/mnt/d/3.KMITL_ai/projects/4_Denso Smart Factory Smart Safety/line-guard-smart-safe"

export USE_FLASH_ATTN=1
export PYTHONUNBUFFERED=1
export HF_HUB_DISABLE_XET=1

cd "$PROJECT"
nohup "$PYTHON" tools/qwen_service.py > /tmp/qwen_wsl.log 2>&1 &
echo "Qwen PID: $!"
sleep 5
echo "=== Log ==="
cat /tmp/qwen_wsl.log
