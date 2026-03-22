# Line Guard Smart Safe

ระบบ AI Safety Monitoring สำหรับโรงงานอุตสาหกรรม
วิเคราะห์วิดีโอจากกล้อง CCTV ด้วย Qwen2.5-VL Vision Language Model
แจ้งเตือน PPE, SOP Violation, และ Near-miss แบบ Real-time

---

## สถาปัตยกรรม

```
Browser (port 5173)
    │
    ▼
nginx (Docker)          ← Frontend: React + static files
    │  /api/            ← Proxy to FastAPI
    │  /media/          ← Static files (video, images, thumbnails)
    ▼
FastAPI (Docker, port 8000)   ← Backend API + PostgreSQL ORM
    │
    ▼
PostgreSQL (Docker, port 5432)

    ┌──────────────────────────────────────┐
    │  Qwen VLM Service (port 8001)        │
    │  รันบน Host (ไม่ใช่ Docker)           │
    │  ต้องการ NVIDIA GPU + CUDA           │
    └──────────────────────────────────────┘
```

---

## ความต้องการของระบบ

### ขั้นต่ำ
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 / 24.04 |
| GPU | RTX 2060 (6 GB VRAM) | RTX 3080+ (10 GB+) |
| RAM | 16 GB | 32 GB |
| Storage | 30 GB free | 50 GB+ |
| CUDA | 11.8 | 12.1+ |
| Docker | 24.0+ | latest |

### VRAM ต่อ Model

| GPU VRAM | Model ที่ใช้ได้ | Flash Attn | หมายเหตุ |
|----------|----------------|------------|---------|
| 6 GB | Qwen2.5-VL-3B (4-bit) | ✗ | ช้า, frames ต่อครั้ง |
| 8 GB | Qwen2.5-VL-3B (4-bit) | ✓ | แนะนำขั้นต่ำ |
| 12 GB | Qwen2.5-VL-3B (4-bit) | ✓ | เร็ว, หลาย frames |
| 16 GB | Qwen2.5-VL-7B (4-bit) | ✓ | ผลลัพธ์ดีกว่า |
| 24 GB | Qwen2.5-VL-7B (4-bit) | ✓ | เร็วมาก |

### Flash Attention 2 ต่อ GPU Architecture

| GPU Series | Architecture | Flash Attn 2 | CUDA |
|------------|-------------|-------------|------|
| RTX 20xx | Turing (sm_75) | ✓ | 11.8+ |
| RTX 30xx | Ampere (sm_86) | ✓ | 11.8+ |
| RTX 40xx | Ada Lovelace (sm_89) | ✓ | 12.1+ |
| RTX 50xx | Blackwell (sm_100) | ✓ | 12.6+ |

---

## ขั้นตอนติดตั้ง

### 1. ติดตั้ง Prerequisites

```bash
# ติดตั้ง Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# ติดตั้ง NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# ตรวจสอบ GPU
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

### 2. Clone และ Config

```bash
git clone https://github.com/kaistjohnGithub/line-guard-smart-safe.git
cd line-guard-smart-safe

# สร้าง .env จาก template
cp .env.example .env
```

แก้ไข `.env`:

```bash
nano .env
```

```env
# PostgreSQL
POSTGRES_DB=ssg_db
POSTGRES_USER=ssg
POSTGRES_PASSWORD=ssg123        # ← เปลี่ยน password บน production

# Backend
DATABASE_URL=postgresql://ssg:ssg123@db:5432/ssg_db
MEDIA_ROOT=/app/media

# Qwen VLM — ชี้ไปที่ host machine
# Linux native: ใช้ IP ของ docker bridge
QWEN_SERVICE_URL=http://172.17.0.1:8001

# Model (เลือกตาม VRAM)
QWEN_MODEL=Qwen/Qwen2.5-VL-3B-Instruct    # สำหรับ 6-12 GB VRAM
# QWEN_MODEL=Qwen/Qwen2.5-VL-7B-Instruct  # สำหรับ 16 GB+ VRAM

# Ports
FRONTEND_PORT=5173
BACKEND_PORT=8000
DB_PORT=5432
```

> **หมายเหตุ IP สำหรับ QWEN_SERVICE_URL:**
> ```bash
> # หา docker bridge IP
> ip route | grep docker
> # หรือ
> docker network inspect bridge | grep Gateway
> ```

### 3. Start Web App (Docker)

```bash
# Build และ start ทุก service
make up

# หรือ
docker compose up -d --build

# ตรวจสอบสถานะ
make ps
make logs
```

เข้าใช้งาน: **http://localhost:5173**

---

## ติดตั้ง Qwen VLM Service

Qwen รันบน **Host** (ไม่ใช่ Docker) เพื่อให้ access GPU โดยตรง

### วิธีที่ 1: Python venv (แนะนำ)

```bash
# ติดตั้ง Python 3.10+
sudo apt install -y python3.10 python3.10-venv python3-pip

# สร้าง virtual environment
python3 -m venv ~/qwen-env
source ~/qwen-env/bin/activate

# ติดตั้ง PyTorch ตาม CUDA version
# --- RTX 20xx/30xx (CUDA 11.8) ---
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# --- RTX 30xx/40xx (CUDA 12.1) ---
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# --- RTX 40xx/50xx (CUDA 12.4+) ---
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu124

# ติดตั้ง dependencies
pip install \
    transformers==4.47.1 \
    qwen-vl-utils \
    fastapi \
    uvicorn \
    opencv-python-headless \
    pillow \
    requests \
    accelerate \
    bitsandbytes \
    sentencepiece
```

### Flash Attention 2 (ถ้า GPU support)

```bash
# ตรวจสอบ CUDA version
nvcc --version
python3 -c "import torch; print(torch.version.cuda)"

# ติดตั้ง Flash Attention
pip install flash-attn --no-build-isolation

# ถ้า build นานหรือ error — ใช้ pre-built wheel
# RTX 30xx (CUDA 12.1, Python 3.10, PyTorch 2.x)
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1+cu12torch2.5cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

# RTX 40xx (CUDA 12.4, Python 3.10, PyTorch 2.x)
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1+cu12torch2.5cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
```

> หา wheel ที่ตรงกับ CUDA/Python/PyTorch version:
> https://github.com/Dao-AILab/flash-attention/releases

### วิธีที่ 2: Micromamba (สำหรับ WSL2)

```bash
# ติดตั้ง micromamba
"${SHELL}" <(curl -L micro.mamba.pm/install.sh)

# สร้าง environment
micromamba create -n vila-safety python=3.10 -y -c conda-forge

# ติดตั้ง PyTorch + dependencies
micromamba run -n vila-safety pip install torch torchvision \
    --index-url https://download.pytorch.org/whl/cu121
micromamba run -n vila-safety pip install \
    transformers==4.47.1 qwen-vl-utils fastapi uvicorn \
    opencv-python-headless pillow requests accelerate \
    bitsandbytes sentencepiece flash-attn --no-build-isolation
```

---

## Start Qwen Service

### แบบ Foreground (ทดสอบ)

```bash
# activate environment
source ~/qwen-env/bin/activate
cd /path/to/line-guard-smart-safe

# Start โดยไม่ Flash Attention
python tools/qwen_service.py

# Start พร้อม Flash Attention (RTX 20xx+)
USE_FLASH_ATTN=1 python tools/qwen_service.py
```

### แบบ Background (production)

```bash
# Start background + log
source ~/qwen-env/bin/activate
cd /path/to/line-guard-smart-safe

nohup env USE_FLASH_ATTN=1 PYTHONUNBUFFERED=1 HF_HUB_DISABLE_XET=1 \
    python tools/qwen_service.py \
    > /tmp/qwen.log 2>&1 &

echo "Qwen PID: $!"

# ดู log
tail -f /tmp/qwen.log
```

### ตรวจสอบว่า service พร้อมใช้งาน

```bash
curl http://localhost:8001/health
```

ผลลัพธ์ที่ถูกต้อง:
```json
{
  "status": "ok",
  "model": "Qwen/Qwen2.5-VL-3B-Instruct",
  "cuda": true,
  "gpu": "NVIDIA GeForce RTX 3080",
  "flash_attn": true
}
```

### systemd service (start อัตโนมัติเมื่อ boot)

```bash
sudo nano /etc/systemd/system/qwen.service
```

```ini
[Unit]
Description=Qwen VLM Service
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/path/to/line-guard-smart-safe
Environment="USE_FLASH_ATTN=1"
Environment="PYTHONUNBUFFERED=1"
Environment="HF_HUB_DISABLE_XET=1"
ExecStart=/home/YOUR_USERNAME/qwen-env/bin/python tools/qwen_service.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable qwen
sudo systemctl start qwen
sudo systemctl status qwen

# ดู log
journalctl -u qwen -f
```

---

## Model Download

ครั้งแรกที่ start Qwen service จะ download model อัตโนมัติ (~6 GB):

```
Qwen/Qwen2.5-VL-3B-Instruct   → ~6 GB
Qwen/Qwen2.5-VL-7B-Instruct   → ~15 GB
```

Model จะ cache ไว้ที่ `./model/hub/` (ตาม `HF_HUB_CACHE` ใน qwen_service.py)

### Copy model จากเครื่องอื่น (ประหยัดเวลา)

```bash
# จากเครื่อง Windows/WSL ที่มี model แล้ว
rsync -av ./model/ user@linux-server:/path/to/line-guard-smart-safe/model/

# หรือ set environment variable ชี้ไปที่ cache ที่มีอยู่แล้ว
export HF_HUB_CACHE=/path/to/existing/model/hub
```

---

## Makefile Commands

```bash
make up           # Build + start ทุก service
make start        # Start โดยไม่ rebuild
make down         # Stop ทุก service
make restart      # Restart ทุก service
make build        # Rebuild images (no cache)
make clean        # Stop + ลบ volumes (⚠ ลบข้อมูล DB)
make logs         # ดู logs ทุก service
make logs-backend # ดู logs เฉพาะ backend
make ps           # ดูสถานะ containers
make db-shell     # เข้า PostgreSQL shell
make up-tools     # Start พร้อม pgAdmin (port 5050)
```

---

## Port และ Services

| Service | Port | URL |
|---------|------|-----|
| Web App (nginx) | 5173 | http://localhost:5173 |
| Backend API | 8000 | http://localhost:8000/docs |
| PostgreSQL | 5432 | postgresql://localhost:5432/ssg_db |
| Qwen VLM | 8001 | http://localhost:8001/health |
| pgAdmin (optional) | 5050 | http://localhost:5050 |

---

## Troubleshooting

### Qwen service ไม่ response

```bash
# เช็ค service
curl http://localhost:8001/health

# เช็ค GPU
nvidia-smi

# เช็ค VRAM
nvidia-smi --query-gpu=memory.used,memory.free --format=csv

# ดู log
tail -100 /tmp/qwen.log
```

### CUDA out of memory

```bash
# ใช้ model ขนาดเล็กลง
QWEN_MODEL=Qwen/Qwen2.5-VL-3B-Instruct python tools/qwen_service.py

# ปิด Flash Attention (ใช้ VRAM น้อยกว่า)
USE_FLASH_ATTN=0 python tools/qwen_service.py

# ลด resolution และ max_frames ใน Prompt Library → VLM Settings
```

### Docker ไม่เห็น GPU

```bash
# ตรวจสอบ nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# ทดสอบ
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

### Flash Attention build error

```bash
# ดู CUDA/PyTorch version
python3 -c "import torch; print(torch.__version__, torch.version.cuda)"

# ติดตั้ง build dependencies
pip install packaging ninja

# Build ใหม่
pip install flash-attn --no-build-isolation --force-reinstall

# หรือใช้ pre-built wheel จาก releases page
# https://github.com/Dao-AILab/flash-attention/releases
```

### Video ไม่ play ใน browser

backend ใช้ ffmpeg transcode วิดีโอเป็น H.264 + faststart อัตโนมัติเมื่อ upload
ถ้า video เก่าที่ upload ก่อน v2 เล่นไม่ได้ ให้ upload ใหม่

### Firewall / LAN access

```bash
# เปิด port 5173 สำหรับ network ที่ต้องการ
sudo ufw allow from 192.168.1.0/24 to any port 5173
sudo ufw reload
```

---

## Project Structure

```
line-guard-smart-safe/
├── docker-compose.yml      # Service definitions
├── nginx.conf              # Frontend + media serving
├── Makefile                # Shortcut commands
├── .env.example            # Environment template
├── index.html              # React app entry
├── src/
│   ├── app.js              # React app (CDN Babel)
│   └── styles.css
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       ├── main.py         # FastAPI app + media upload + ffmpeg transcode
│       ├── models.py       # SQLAlchemy ORM
│       ├── database.py
│       └── api/routes/
│           ├── cameras.py  # Camera Fleet API
│           ├── processes.py # SOP / Process API
│           ├── prompts.py  # Prompt Library + VLM test
│           ├── vlm.py      # Qwen health + flash attn toggle
│           └── analyze.py  # Video analysis jobs
├── db/
│   ├── init.sql            # Initial schema
│   └── migrations/         # Schema migrations
├── tools/
│   ├── qwen_service.py     # Qwen VLM FastAPI service (run on host)
│   ├── setup_wsl.sh        # WSL2 environment setup
│   └── start_qwen_wsl.sh   # Start Qwen on WSL2
└── media/                  # Uploaded files (gitignored)
    ├── videos/
    ├── images/
    └── thumbnails/
```

---

## GPU Performance Guide

| GPU | VRAM | 3B 4-bit | Flash Attn | ~Time/frame |
|-----|------|----------|------------|------------|
| RTX 2060 | 6 GB | ✓ | ✓ | ~25s |
| RTX 2080 Ti | 11 GB | ✓ | ✓ | ~18s |
| RTX 3070 | 8 GB | ✓ | ✓ | ~15s |
| RTX 3080 | 10 GB | ✓ | ✓ | ~12s |
| RTX 3090 | 24 GB | ✓ | ✓ | ~8s |
| RTX 4070 | 12 GB | ✓ | ✓ | ~10s |
| RTX 4080 | 16 GB | ✓ | ✓ | ~7s |
| RTX 4090 | 24 GB | ✓ | ✓ | ~5s |
