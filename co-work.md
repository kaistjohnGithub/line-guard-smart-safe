# Co-Work Coordination — Smart Safe Guardian
> **Claude Code** writes tasks here. **Codex** reads this file and executes them.
> Last updated by: Claude Code | 2026-03-17

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  PROJECT 1 — Frontend (React)                           │
│  smart-safe-guardian-react/  :5173                      │
└────────────────────┬────────────────────────────────────┘
                     │ REST / WebSocket
┌────────────────────▼────────────────────────────────────┐
│  PROJECT 2 — Backend (FastAPI)                          │
│  smart-safe-guardian-react/backend/  :8000              │
└──────────┬──────────────────────────┬───────────────────┘
           │ POST /vlm/infer           │ POST /vision/analyze
┌──────────▼──────────┐   ┌───────────▼───────────────────┐
│  VLM Service        │   │  PROJECT 3 — DINOv3 Service   │
│  Qwen2.5-VL  :8001  │   │  3_dinov3/  :8002             │
│  (video → text)     │   │  (frame → dense features,     │
│  vila-safety-poc/   │   │   zone detection, anomaly)    │
└─────────────────────┘   └───────────────────────────────┘
```

---

## Project Context

**App:** Smart Safe Guardian — DENSO Smart Factory Safety Web App
**Stack:** HTML + React (CDN Babel, no build tool) + FastAPI backend
**Root files:**
- `index.html` — entry point
- `src/app.js` — React app (all components)
- `src/data/mock-data.js` — all mock data (`window.SSG_DATA`)
- `src/styles.css` — CSS variables + layout
- `backend/app/main.py` — FastAPI server
- `smart-safe-guardian-react.html` — original full UI template (reference only)

**Reference video files (for mock camera feeds):**
```
../vila-safety-poc/demo_videos/sample_forklift_safety.mp4
../vila-safety-poc/demo_videos/synthetic_factory.mp4
```

---

## Division of Responsibilities

| Responsibility | Owner |
|---|---|
| Architecture decisions, data schemas, task writing | **Claude Code** |
| File scaffolding, code generation, boilerplate | **Codex** |
| Logic review, bug fixing, integration | **Claude Code** |
| Style / CSS additions | **Codex** |

---

## Task Queue

> **Codex: work top-to-bottom. One task at a time. Mark status when done.**

---

### TASK-01 — Expand mock-data.js with full dataset
**Status:** `[x] DONE - 2026-03-17`
**Assigned to:** Codex
**File:** `src/data/mock-data.js`

Replace `window.SSG_DATA` with the full dataset below. Keep the existing `window.SSG_DATA =` pattern.

#### Cameras (8 total)
```js
cameras: [
  { id:'CAM-A01', name:'Press Machine 1',    process:'Assembly / Press',     station:'Station 01', status:'critical', fps:15, alerts:3, risk:'CRITICAL', videoSrc:'../vila-safety-poc/demo_videos/sample_forklift_safety.mp4' },
  { id:'CAM-A02', name:'Press Machine 2',    process:'Assembly / Press',     station:'Station 02', status:'online',   fps:14, alerts:0, risk:'LOW',      videoSrc:null },
  { id:'CAM-A03', name:'Operator Check',     process:'Assembly / Sampling',  station:'Station 03', status:'delay',    fps:3,  alerts:1, risk:'MED',      videoSrc:'../vila-safety-poc/demo_videos/synthetic_factory.mp4' },
  { id:'CAM-A04', name:'Packing Area',       process:'Assembly / Packing',   station:'Station 04', status:'offline',  fps:0,  alerts:0, risk:'N/A',      videoSrc:null },
  { id:'CAM-B01', name:'Welding Station',    process:'Assembly B / Welding', station:'Station 01', status:'online',   fps:15, alerts:0, risk:'LOW',      videoSrc:null },
  { id:'CAM-B02', name:'QC Inspection',      process:'Assembly B / QC',      station:'Station 02', status:'online',   fps:15, alerts:0, risk:'LOW',      videoSrc:null },
  { id:'CAM-C01', name:'Robot Arm Zone A',   process:'Assembly C / Robot',   station:'Station 01', status:'online',   fps:15, alerts:1, risk:'HIGH',     videoSrc:null },
  { id:'CAM-C02', name:'Conveyor Line B',    process:'Assembly C / Conveyor',station:'Station 02', status:'online',   fps:12, alerts:0, risk:'LOW',      videoSrc:null },
]
```

#### SOP Library (6 SOPs)
```js
sops: [
  { id:'SOP-001', name:'Press Machine Operation — Station 01', process:'Assembly / Press',     ver:'v1.3', status:'published', updated:'10 Mar 2026', by:'K.Somsak' },
  { id:'SOP-002', name:'Welding Operation Safety',             process:'Assembly B / Welding', ver:'v2.1', status:'published', updated:'05 Mar 2026', by:'P.Naree' },
  { id:'SOP-003', name:'Sampling & QC Procedure',             process:'Assembly / Sampling',  ver:'v1.0', status:'draft',     updated:'12 Mar 2026', by:'K.Somsak' },
  { id:'SOP-004', name:'Robot Arm Zone Entry',                 process:'Assembly C / Robot',   ver:'v3.2', status:'published', updated:'01 Mar 2026', by:'T.Chai' },
  { id:'SOP-005', name:'Emergency Shutdown Procedure',         process:'All',                  ver:'v4.0', status:'published', updated:'15 Feb 2026', by:'Admin' },
  { id:'SOP-006', name:'PPE Check & Donning',                  process:'All / Entry',          ver:'v1.2', status:'review',    updated:'08 Mar 2026', by:'K.Somsak' },
]
```

#### SOP Steps for SOP-001 (Press Machine)
```js
sopSteps: [
  { step:1, text:'Employee scans barcode at station entry point',                        risk:'high',     ppe:['Gloves'] },
  { step:2, text:'Check machine status light — Green = ready, Red = Stop',              risk:'critical', ppe:['Gloves','Face Shield'] },
  { step:3, text:'Confirm full machine stop before opening cover (dual confirmation)',   risk:'critical', ppe:['Gloves','Face Shield'] },
  { step:4, text:'Verify guard door is physically closed and locked',                   risk:'critical', ppe:['Gloves'] },
  { step:5, text:'Sample inspection per standard inspection sheet',                     risk:'low',      ppe:['Gloves'] },
  { step:6, text:'Record result in system within 2 minutes',                            risk:'low',      ppe:[] },
]
```

#### Safety Rules
```js
rules: {
  action: [
    { id:'R-001', text:'Operator must not enter press zone while machine cycle is active',       sev:'critical', source:'AI-Generated', process:'Assembly/Press' },
    { id:'R-002', text:'Machine guard must be confirmed closed before approaching equipment',    sev:'critical', source:'Manual',        process:'Assembly/Press' },
    { id:'R-003', text:'Barcode scan is mandatory before any machine operation',                 sev:'high',     source:'Manual',        process:'All' },
    { id:'R-004', text:'Face shield required during all sampling activities',                    sev:'high',     source:'Manual',        process:'Assembly/Sampling' },
    { id:'R-005', text:'Two-person rule applies when entering robot arm operational zone',       sev:'high',     source:'AI-Generated', process:'Assembly C/Robot' },
  ],
  condition: [
    { id:'R-010', text:'Oil spills must be cleaned within 15 minutes of detection',             sev:'high',     source:'Manual',        process:'All' },
    { id:'R-011', text:'Guard doors must remain closed during all machine operations',           sev:'critical', source:'Manual',        process:'All' },
    { id:'R-012', text:'Walkway must remain obstacle-free (min 1.2m clearance)',                sev:'medium',   source:'AI-Generated', process:'All' },
    { id:'R-013', text:'Lighting level at inspection station must exceed 500 lux',              sev:'medium',   source:'Manual',        process:'Assembly/Sampling' },
  ],
  nearmiss: [
    { id:'R-020', text:'Any near-miss requires immediate machine shutdown and supervisor notification', sev:'critical', source:'Manual',        process:'All' },
    { id:'R-021', text:'Hand+machine near-miss = mandatory corrective action report within 2 hours',   sev:'critical', source:'AI-Generated', process:'Assembly/Press' },
  ],
  pending: [
    { id:'R-030', text:'Install proximity sensor alarm within 1.5m of press zone',              sev:'high',     source:'AI-Generated', process:'Assembly/Press' },
    { id:'R-031', text:'Dual-lock mechanism: operator badge + machine stop confirmation',       sev:'critical', source:'AI-Generated', process:'Assembly/Press' },
    { id:'R-032', text:'Add conveyor auto-stop if person detected within 0.8m',                sev:'high',     source:'AI-Generated', process:'Assembly C/Conveyor' },
  ],
}
```

#### Prompt Library (7 prompts)
```js
prompts: [
  {
    id:'P-01', name:'General Safety Monitoring', type:'SAFETY', typeColor:'#1d6ef5',
    text:`Analyze this video for industrial workplace safety. Describe:\n1. What the operator is doing\n2. Equipment involved\n3. Any unsafe action detected\n4. Any unsafe condition\n5. Near-miss risks\n6. Safety recommendations\n7. Overall risk level: LOW / MEDIUM / HIGH / CRITICAL`
  },
  {
    id:'P-02', name:'SOP Compliance Check', type:'SOP', typeColor:'#0891b2',
    text:`Compare observed actions with the defined SOP.\nIdentify:\n1. Steps followed correctly\n2. Steps skipped or missed\n3. Out-of-order actions\n4. Safety impact of each deviation\n5. Overall compliance score (0–100%)`
  },
  {
    id:'P-03', name:'Unsafe Action Detection', type:'UNSAFE-ACT', typeColor:'#e53e3e',
    text:`Detect all unsafe actions in this video.\nFor each unsafe action:\n- Actor description\n- Exact action performed\n- Risk level (Low/Med/High/Critical)\n- Body zone involved\n- Recommended countermeasure`
  },
  {
    id:'P-04', name:'PPE Compliance Check', type:'PPE', typeColor:'#16a34a',
    text:`Verify PPE compliance for each visible worker.\nCheck for: helmet, gloves, face shield, safety shoes, high-vis vest.\nFor each worker: position, PPE present, PPE missing, severity of violation.`
  },
  {
    id:'P-05', name:'Near-Miss Explanation', type:'NEAR-MISS', typeColor:'#d97706',
    text:`Identify near-miss situations.\nFor each near-miss:\n1. Who is involved\n2. Dangerous interaction occurred\n3. Why it is risky\n4. Severity if actual incident\n5. Prevention recommendations`
  },
  {
    id:'P-06', name:'Generate Safety Rule', type:'RULE-GEN', typeColor:'#7c3aed',
    text:`Generate safety rules from observed risks.\nSeparate into:\n- Unsafe Actions (operator behavior rules)\n- Unsafe Conditions (environment/equipment rules)\n- Preventive Rules\n- Supervisor Recommendations`
  },
  {
    id:'P-07', name:'Custom Prompt', type:'CUSTOM', typeColor:'#64748b',
    text:''
  },
]
```

#### Alerts (5)
```js
alerts: [
  { id:'ALT-001', sev:'critical', title:'Critical Near-Miss — CAM-A01',          cam:'CAM-A01', sub:'Press Machine 1 · Assembly / Press',         time:'14:22:19', tags:['Near-Miss','Hand Zone'],    unread:true },
  { id:'ALT-002', sev:'critical', title:'Machine Guard Open During Operation',    cam:'CAM-A01', sub:'CAM-A01 · Press Station 01',                  time:'14:20:05', tags:['Guard Open','SOP Violation'],unread:true },
  { id:'ALT-003', sev:'high',     title:'No Face Shield — CAM-A03',              cam:'CAM-A03', sub:'Operator Check Station · Sampling',            time:'13:45:11', tags:['PPE','Face Shield'],        unread:false },
  { id:'ALT-004', sev:'high',     title:'Operator Skipped SOP Step 3',           cam:'CAM-A01', sub:'CAM-A01 · Press Station 01',                  time:'13:30:00', tags:['SOP','Barcode Skip'],       unread:false },
  { id:'ALT-005', sev:'medium',   title:'Oil Spill Detected — CAM-B01',          cam:'CAM-B01', sub:'Welding Station · Assembly B',                 time:'12:10:34', tags:['Unsafe Condition'],         unread:false },
]
```

#### Events (7)
```js
events: [
  { ts:'14:22:19', cam:'CAM-A01', stn:'Press 01',     sev:'critical', type:'Near-Miss',      desc:'Machine running + hand in danger zone',   status:'Open' },
  { ts:'14:22:11', cam:'CAM-A01', stn:'Press 01',     sev:'high',     type:'Unsafe Action',  desc:'Hand approaching moving part',             status:'Open' },
  { ts:'14:22:01', cam:'CAM-A01', stn:'Press 01',     sev:'medium',   type:'Zone Violation', desc:'Operator standing in restricted zone',     status:'Open' },
  { ts:'14:20:05', cam:'CAM-A01', stn:'Press 01',     sev:'critical', type:'SOP Violation',  desc:'Guard opened before machine confirmed stop',status:'Ack' },
  { ts:'13:45:11', cam:'CAM-A03', stn:'Sampling 03',  sev:'high',     type:'PPE Violation',  desc:'No face shield during sampling task',      status:'Ack' },
  { ts:'13:30:00', cam:'CAM-A01', stn:'Press 01',     sev:'medium',   type:'SOP Skip',       desc:'Entry barcode scan step was bypassed',     status:'Resolved' },
  { ts:'12:10:34', cam:'CAM-B01', stn:'Welding 01',   sev:'medium',   type:'Unsafe Condition','desc':'Oil spill found near welding station',  status:'Resolved' },
]
```

---

### TASK-02 — Add camera feed section to CameraDetail view in app.js
**Status:** `[ ] TODO` _(start after TASK-01 is done)_
**Assigned to:** Codex
**File:** `src/app.js`

When user clicks on a camera card (in Monitoring section), show a detail view with:

1. **If `camera.videoSrc` is not null** → render `<video>` element:
```jsx
<video
  src={camera.videoSrc}
  controls autoPlay muted loop
  style={{ width:'100%', borderRadius:8, background:'#000', maxHeight:320 }}
/>
```

2. **If `camera.videoSrc` is null** → render `<MockFeed>` canvas component that:
   - Draws dark `#0a1628` background
   - Draws a light grid overlay (lines every 40px, rgba(255,255,255,0.04))
   - Animates a small white dot moving on a random walk path (setInterval 80ms)
   - Shows camera ID text in top-left (green monospace, 11px)
   - Shows live timestamp in bottom-right
   - Shows a red `● REC` blink in top-right

3. Below the video/feed, show:
   - Risk badge (`camera.risk`) colored by severity
   - FPS indicator
   - Alert count

Use `useState` + `useEffect` for the canvas animation. Use `useRef` for the canvas element.

---

### TASK-03 — Wire navigation to real sections in app.js
**Status:** `[ ] TODO` _(start after TASK-02 is done)_
**Assigned to:** Codex
**File:** `src/app.js`

Replace the current flat panel grid with proper section routing. Each `nav-item` click should show only its section:

| Nav key | Component to render |
|---|---|
| `dashboard` | `<DashboardSection>` — KPI cards + recent alerts |
| `monitoring` | `<MonitoringSection>` — camera grid, click → detail |
| `alerts` | `<AlertsSection>` — alert list from `SSG_DATA.alerts` |
| `sop` | `<SOPSection>` — SOP table + step viewer |
| `rules` | `<RulesSection>` — tabbed: action / condition / near-miss / pending |
| `prompts` | `<PromptsSection>` — prompt cards with copy button |
| `events` | `<EventsSection>` — event table with status badge |

Each section component reads from `window.SSG_DATA`. No routing library needed — just `activeSection` state in `App`.

---

### TASK-04 — Style: add severity-critical and risk badge styles to styles.css
**Status:** `[ ] TODO`
**Assigned to:** Codex
**File:** `src/styles.css`

Add these CSS classes (append to end of file):

```css
/* Risk / Severity badges */
.risk-badge {
  display: inline-flex; align-items: center;
  padding: 3px 10px; border-radius: 6px;
  font-size: 11px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase;
}
.risk-CRITICAL { background: var(--red-soft);   color: var(--red); }
.risk-HIGH     { background: #ffe8df;            color: #c05b18; }
.risk-MED      { background: var(--amber-soft);  color: var(--amber); }
.risk-LOW      { background: var(--green-soft);  color: var(--green); }
.risk-NA       { background: var(--border);      color: var(--text-soft); }

/* Camera grid */
.camera-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 14px;
}
.camera-card {
  border: 1px solid var(--border);
  border-radius: 16px;
  background: var(--surface-strong);
  overflow: hidden;
  cursor: pointer;
  transition: box-shadow 0.18s;
}
.camera-card:hover { box-shadow: 0 8px 28px rgba(29,95,209,0.13); }
.camera-card-body  { padding: 12px 14px; }

/* Prompt card */
.prompt-card {
  border: 1px solid var(--border);
  border-radius: 16px;
  background: var(--surface-strong);
  padding: 16px;
  display: flex; flex-direction: column; gap: 10px;
}
.prompt-type-badge {
  display: inline-flex; align-items: center;
  padding: 2px 8px; border-radius: 4px;
  font-size: 10px; font-weight: 700; letter-spacing: 0.07em;
  background: var(--surface-soft); color: var(--blue);
}
.prompt-body {
  font-size: 12px; color: var(--text-soft); white-space: pre-wrap;
  background: var(--surface-soft); border-radius: 8px;
  padding: 10px 12px; line-height: 1.6;
}

/* SOP table */
.sop-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.sop-table th { text-align: left; padding: 8px 12px; font-size: 11px; text-transform: uppercase; letter-spacing: 0.07em; color: var(--text-soft); border-bottom: 1px solid var(--border); }
.sop-table td { padding: 10px 12px; border-bottom: 1px solid var(--border); }
.sop-table tr:last-child td { border-bottom: none; }
.sop-table tr:hover td { background: var(--surface-soft); }

/* Event table */
.event-table { width: 100%; border-collapse: collapse; font-size: 12px; }
.event-table th { text-align:left; padding:8px 10px; font-size:10px; text-transform:uppercase; letter-spacing:0.07em; color:var(--text-soft); border-bottom:1px solid var(--border); }
.event-table td { padding:9px 10px; border-bottom:1px solid var(--border); vertical-align:middle; }
.event-table tr:last-child td { border-bottom:none; }

/* Status chips */
.chip { display:inline-flex; align-items:center; padding:2px 9px; border-radius:999px; font-size:10px; font-weight:700; }
.chip-open     { background:var(--red-soft);   color:var(--red); }
.chip-ack      { background:var(--amber-soft); color:var(--amber); }
.chip-resolved { background:var(--green-soft); color:var(--green); }

/* Rules tabs */
.tab-bar { display:flex; gap:6px; margin-bottom:16px; }
.tab-btn { padding:5px 14px; border-radius:8px; border:1px solid var(--border); background:var(--surface-strong); font-size:12px; cursor:pointer; }
.tab-btn.active { background:var(--blue); color:#fff; border-color:var(--blue); }
```

---

---

## PROJECT 3 — DINOv3 Vision Service

> **Source repo:** `d:/3.KMITL_ai/projects/3_dinov3/dinov3/`
> **Role in system:** Dense visual feature extraction + zone anomaly detection (runs alongside VLM)
> **Port:** `:8002`
> **Available via HuggingFace:** `facebook/dinov3-base` (transformers >= 4.56.0)

### What DINOv3 does in Smart Safe Guardian

| Use Case | DINOv3 Role |
|---|---|
| **Danger zone detection** | Compute cosine similarity between frame patches and reference "danger zone" crops |
| **PPE feature matching** | Match helmet/vest patch features against reference PPE images (zero-shot) |
| **Anomaly heatmap** | Per-patch distance from "normal" baseline → highlight unusual regions |
| **Person proximity alert** | Dense patch features → detect person patches near machine zone patches |

### DINOv3 Service File Structure

Create this at: `d:/3.KMITL_ai/projects/3_dinov3/`

```
dinov3-service/
├── server.py               ← FastAPI app — POST /analyze, GET /health
├── analyzer.py             ← DINOv3 inference wrapper (HF Transformers)
├── zone_detector.py        ← danger zone logic using patch similarity
├── ppe_matcher.py          ← PPE reference matching (helmet, vest, gloves)
├── anomaly_scorer.py       ← frame-vs-baseline anomaly score
├── reference_crops/        ← reference images for PPE matching
│   ├── helmet.jpg
│   ├── vest.jpg
│   └── gloves.jpg
├── config.py               ← model ID, device, thresholds
└── requirements.txt        ← transformers>=4.56.0, torch, pillow, fastapi, uvicorn
```

---

### TASK-05 — Scaffold DINOv3 service files
**Status:** `[ ] TODO`
**Assigned to:** Codex
**Root:** `d:/3.KMITL_ai/projects/3_dinov3/dinov3-service/`

#### `config.py`
```python
MODEL_ID   = "facebook/dinov3-base"   # or dinov3-small for faster PoC
DEVICE     = "cuda"                    # falls back to cpu if unavailable
IMAGE_SIZE = 518                       # DINOv3 native resolution
PATCH_SIZE = 14

# Similarity thresholds
ZONE_ALERT_THRESHOLD  = 0.72   # cosine sim: person patch near danger zone
PPE_MATCH_THRESHOLD   = 0.68   # cosine sim: PPE detected
ANOMALY_ALERT_SCORE   = 0.55   # anomaly score above this = WARNING
```

#### `analyzer.py`
```python
"""
DINOv3 feature extractor.
Loads model once (lazy), exposes:
  extract_features(pil_image) -> patch_features (N, D) numpy array
  extract_cls(pil_image)      -> cls token (D,) numpy array
"""
import numpy as np
from PIL import Image
import torch

_model = None
_processor = None

def load():
    global _model, _processor
    if _model is not None:
        return
    from transformers import AutoImageProcessor, AutoModel
    from config import MODEL_ID, DEVICE
    _processor = AutoImageProcessor.from_pretrained(MODEL_ID)
    _model = AutoModel.from_pretrained(MODEL_ID).to(DEVICE).eval()

def extract_features(image: Image.Image):
    """Returns (patch_features, cls_token) as numpy arrays."""
    load()
    from config import DEVICE
    inputs = _processor(images=image, return_tensors="pt").to(DEVICE)
    with torch.no_grad():
        outputs = _model(**inputs)
    patch_features = outputs.last_hidden_state[0, 1:].cpu().numpy()  # skip CLS
    cls_token       = outputs.last_hidden_state[0, 0].cpu().numpy()
    return patch_features, cls_token
```

#### `zone_detector.py`
```python
"""
Danger zone detection:
Given a query frame and a reference danger zone crop,
compute per-patch cosine similarity map.
Returns: similarity_map (H_patches, W_patches), alert (bool), max_sim (float)
"""
import numpy as np
from PIL import Image
from analyzer import extract_features
from config import ZONE_ALERT_THRESHOLD, IMAGE_SIZE, PATCH_SIZE

def check_zone(frame: Image.Image, zone_crop: Image.Image):
    frame_patches, _ = extract_features(frame)
    _, zone_cls       = extract_features(zone_crop)

    # Cosine similarity between each frame patch and the zone CLS token
    norms  = np.linalg.norm(frame_patches, axis=1, keepdims=True) * np.linalg.norm(zone_cls)
    sims   = (frame_patches @ zone_cls) / (norms.squeeze() + 1e-8)

    h = w = IMAGE_SIZE // PATCH_SIZE
    sim_map  = sims.reshape(h, w)
    max_sim  = float(sim_map.max())
    alert    = max_sim >= ZONE_ALERT_THRESHOLD
    return {"sim_map": sim_map.tolist(), "max_sim": max_sim, "alert": alert}
```

#### `ppe_matcher.py`
```python
"""
PPE compliance check using DINOv3 feature similarity.
For each PPE category (helmet, vest, gloves):
  - load reference crop
  - compare CLS token of frame against reference CLS
  - if similarity < threshold → PPE MISSING
"""
import os
import numpy as np
from PIL import Image
from analyzer import extract_features
from config import PPE_MATCH_THRESHOLD

PPE_REFS = {
    "helmet": "reference_crops/helmet.jpg",
    "vest":   "reference_crops/vest.jpg",
    "gloves": "reference_crops/gloves.jpg",
}

def check_ppe(frame: Image.Image) -> dict:
    _, frame_cls = extract_features(frame)
    results = {}
    for ppe, ref_path in PPE_REFS.items():
        if not os.path.exists(ref_path):
            results[ppe] = {"status": "no_reference"}
            continue
        ref_img = Image.open(ref_path).convert("RGB")
        _, ref_cls = extract_features(ref_img)
        sim = float(np.dot(frame_cls, ref_cls) /
                    (np.linalg.norm(frame_cls) * np.linalg.norm(ref_cls) + 1e-8))
        results[ppe] = {"similarity": round(sim, 4),
                        "status": "present" if sim >= PPE_MATCH_THRESHOLD else "missing"}
    return results
```

#### `anomaly_scorer.py`
```python
"""
Anomaly detection: compare current frame CLS against a stored baseline.
Baseline is computed from a set of "normal operation" reference frames.
"""
import numpy as np
from PIL import Image
from analyzer import extract_features
from config import ANOMALY_ALERT_SCORE

_baseline_cls = None  # mean CLS of normal frames

def set_baseline(normal_frames: list):
    """Call once at startup with list of PIL Images of normal operation."""
    global _baseline_cls
    cls_list = [extract_features(f)[1] for f in normal_frames]
    _baseline_cls = np.mean(cls_list, axis=0)
    _baseline_cls /= np.linalg.norm(_baseline_cls)

def score_frame(frame: Image.Image) -> dict:
    if _baseline_cls is None:
        return {"score": None, "alert": False, "reason": "no baseline set"}
    _, cls = extract_features(frame)
    cls_norm = cls / (np.linalg.norm(cls) + 1e-8)
    dist  = float(1.0 - np.dot(cls_norm, _baseline_cls))  # 0=normal, 1=anomaly
    alert = dist >= ANOMALY_ALERT_SCORE
    return {"score": round(dist, 4), "alert": alert}
```

#### `server.py`
```python
"""
DINOv3 Vision Service
POST /analyze  → run zone + PPE + anomaly checks on uploaded frame
GET  /health   → service status
"""
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import io, json

from zone_detector  import check_zone
from ppe_matcher    import check_ppe
from anomaly_scorer import score_frame

app = FastAPI(title="DINOv3 Vision Service")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/health")
def health():
    return {"status": "ok", "service": "dinov3-vision"}

@app.post("/analyze")
async def analyze(
    frame: UploadFile = File(...),
    mode: str = Form("full"),          # "full" | "ppe" | "zone" | "anomaly"
    zone_crop: UploadFile = File(None),
):
    img_bytes = await frame.read()
    pil_frame = Image.open(io.BytesIO(img_bytes)).convert("RGB")

    result = {"camera": frame.filename, "checks": {}}

    if mode in ("full", "ppe"):
        result["checks"]["ppe"] = check_ppe(pil_frame)

    if mode in ("full", "anomaly"):
        result["checks"]["anomaly"] = score_frame(pil_frame)

    if mode in ("full", "zone") and zone_crop:
        zone_bytes = await zone_crop.read()
        pil_zone   = Image.open(io.BytesIO(zone_bytes)).convert("RGB")
        result["checks"]["zone"] = check_zone(pil_frame, pil_zone)

    return result
```

#### `requirements.txt`
```
fastapi>=0.111
uvicorn[standard]
transformers>=4.56.0
torch>=2.2
pillow>=10.0
numpy>=1.26
python-multipart
```

**Run command:**
```bash
cd d:/3.KMITL_ai/projects/3_dinov3/dinov3-service
uvicorn server:app --host 0.0.0.0 --port 8002 --reload
```

---

### TASK-06 — Connect DINOv3 to Backend API
**Status:** `[ ] TODO` _(after TASK-05)_
**Assigned to:** Codex
**File:** `smart-safe-guardian-react/backend/app/api/routes/vision.py` _(create new)_

Add a new route file that proxies requests to the DINOv3 service:

```python
"""
Backend route: /api/vision/analyze
Forwards frame to DINOv3 service at :8002, returns unified result.
"""
from fastapi import APIRouter, UploadFile, File
import httpx

router = APIRouter(prefix="/vision", tags=["vision"])
DINOV3_URL = "http://localhost:8002"

@router.post("/analyze")
async def analyze_frame(frame: UploadFile = File(...)):
    async with httpx.AsyncClient(timeout=30) as client:
        files  = {"frame": (frame.filename, await frame.read(), frame.content_type)}
        data   = {"mode": "full"}
        resp   = await client.post(f"{DINOV3_URL}/analyze", files=files, data=data)
    return resp.json()

@router.get("/health")
async def dinov3_health():
    async with httpx.AsyncClient(timeout=5) as client:
        resp = await client.get(f"{DINOV3_URL}/health")
    return resp.json()
```

Also add to `backend/app/main.py`:
```python
from app.api.routes.vision import router as vision_router
app.include_router(vision_router, prefix="/api")
```

---

### TASK-07 — Add DINOv3 status card to Frontend (Settings / Integration page)
**Status:** `[ ] TODO` _(after TASK-06)_
**Assigned to:** Codex
**File:** `src/app.js`

In the Integration section, add a service status row for DINOv3:
- Show green dot if `GET /api/vision/health` returns `{"status":"ok"}`
- Show red dot + "offline" if fetch fails
- Use `useEffect` with 10-second polling interval

---

---

## DEPLOYMENT — ให้ app ทำงานออนไลน์ได้สมบูรณ์

> **เป้าหมาย:** app ทำงานได้ครบ 100% จาก mock data ไม่ต้องการ backend
> **Deploy target:** Netlify (drag & drop) หรือ GitHub Pages
> **ไม่มี build step** — static HTML อย่างเดียว

### วิดีโอ mock feed
วิดีโอถูก copy เข้า project แล้วที่ `src/videos/`
path ใน mock-data.js อัปเดตเป็น `./src/videos/` แล้ว (Claude ทำแล้ว)

```
src/videos/
  sample_forklift_safety.mp4   ← CAM-A01 (9.5 MB)
  synthetic_factory.mp4        ← CAM-A03 (304 KB)
```

กล้องอื่นที่ `videoSrc: null` → ใช้ `<MockFeed>` canvas animation แทน

---

### TASK-08 — Port full UI จาก template → app.js (สำคัญที่สุด)
**Status:** `[x] DONE - 2026-03-17`
**Assigned to:** Codex
**File:** `src/app.js`

นี่คืองานหลักที่ทำให้ app ทำงานได้สมบูรณ์
**Reference file:** `smart-safe-guardian-react.html` (อ่านได้ — ไม่ต้องแก้)

ให้ port ทุก component จาก `smart-safe-guardian-react.html` มาที่ `src/app.js` โดย:

1. **ใช้ data จาก `window.SSG_DATA`** แทน hardcoded const ใน template
2. **แต่ละ section navigation** render component แยกกัน:
   - `dashboard` → KPI cards (cameras online, critical alerts, events today, compliance %) + recent alerts list
   - `monitoring` → camera grid 8 ตัว + click เพิ่ด detail (video + analysis panel)
   - `alerts` → alert list พร้อม severity badge + ack button
   - `sop` → SOP table + เลือก SOP แล้วดู steps ด้านขวา
   - `rules` → tabs: Unsafe Actions / Conditions / Near-Miss / Pending Review
   - `prompts` → prompt cards พร้อม copy-to-clipboard button
   - `events` → event table + filter by severity/status

3. **MockFeed canvas component** สำหรับกล้องที่ไม่มี videoSrc:
```jsx
function MockFeed({ camId, status }) {
  const ref = React.useRef(null);
  React.useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let dot = { x: 120, y: 80 };
    let frame = 0;
    const tick = () => {
      // background
      ctx.fillStyle = '#0a1628';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      // grid
      ctx.strokeStyle = 'rgba(255,255,255,0.04)';
      ctx.lineWidth = 1;
      for (let x = 0; x < canvas.width; x += 40) { ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,canvas.height); ctx.stroke(); }
      for (let y = 0; y < canvas.height; y += 40) { ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(canvas.width,y); ctx.stroke(); }
      // moving dot (person)
      dot.x += (Math.random()-0.5)*4; dot.y += (Math.random()-0.5)*3;
      dot.x = Math.max(10, Math.min(canvas.width-10, dot.x));
      dot.y = Math.max(10, Math.min(canvas.height-10, dot.y));
      ctx.fillStyle = status === 'critical' ? '#ef4444' : '#22c55e';
      ctx.beginPath(); ctx.arc(dot.x, dot.y, 5, 0, Math.PI*2); ctx.fill();
      // cam id
      ctx.fillStyle = '#22c55e'; ctx.font = "11px 'IBM Plex Mono',monospace";
      ctx.fillText(camId, 8, 16);
      // timestamp
      ctx.fillStyle = 'rgba(255,255,255,0.5)'; ctx.font = "10px 'IBM Plex Mono',monospace";
      ctx.fillText(new Date().toLocaleTimeString(), canvas.width-72, canvas.height-6);
      // REC blink
      if (Math.floor(frame/15)%2===0) { ctx.fillStyle='#ef4444'; ctx.beginPath(); ctx.arc(canvas.width-10,10,4,0,Math.PI*2); ctx.fill(); }
      frame++;
    };
    const id = setInterval(tick, 80);
    return () => clearInterval(id);
  }, [camId, status]);
  return <canvas ref={ref} width={320} height={200} style={{width:'100%',borderRadius:6,display:'block'}} />;
}
```

4. **Video player** สำหรับกล้องที่มี videoSrc:
```jsx
<video src={cam.videoSrc} autoPlay muted loop controls
  style={{width:'100%',borderRadius:6,background:'#000',maxHeight:240}} />
```

5. **Sidebar** ใช้ design ใกล้เคียง template: dark navy background, nav items, user footer, live clock
6. **Topbar** บน dashboard: filter dropdowns, search bar, LIVE indicator
7. **ต้องไม่มี import / require** — ใช้แค่ React จาก window และ window.SSG_DATA

---

### TASK-09 — สร้าง netlify.toml และ .gitignore
**Status:** `[ ] TODO`
**Assigned to:** Codex

#### `netlify.toml` (ที่ root ของ `smart-safe-guardian-react/`)
```toml
[build]
  publish = "."

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "SAMEORIGIN"
    X-Content-Type-Options = "nosniff"

[[headers]]
  for = "/src/videos/*"
  [headers.values]
    Cache-Control = "public, max-age=86400"
```

#### `.gitignore`
```
backend/__pycache__/
backend/app/__pycache__/
backend/app/api/routes/__pycache__/
backend/app/services/__pycache__/
*.pyc
*.pyo
node_modules/
.env
```

---

### TASK-10 — ทดสอบ app ก่อน deploy
**Status:** `[ ] TODO`
**Assigned to:** Codex

เปิดไฟล์ `index.html` ใน browser โดยตรง (file://) แล้วตรวจว่า:
- [ ] Sidebar navigate ได้ทุก section
- [ ] Dashboard แสดง KPI cards
- [ ] Monitoring แสดงกล้อง 8 ตัว
- [ ] กล้อง CAM-A01 เล่นวิดีโอได้
- [ ] กล้องที่ videoSrc=null แสดง canvas animation
- [ ] Alerts แสดง 5 รายการ
- [ ] SOP แสดงตาราง 6 รายการ + step detail
- [ ] Rules มี tabs 4 tabs
- [ ] Prompts แสดง 7 cards + copy button ทำงาน
- [ ] Events แสดงตาราง 7 รายการ

หากผ่านทั้งหมด → อัปเดต status เป็น `[x] DONE` แล้วแจ้งใน `co-work-chat.md`

---

## Completed Tasks

_(moved here when done)_

---

## Notes for Codex

- **Do not** modify `smart-safe-guardian-react.html` — it is reference only.
- **Do not** add a build system (no npm, no Vite). Files load via `<script type="text/babel">` tags in `index.html`.
- All components go in `src/app.js`. All data goes in `src/data/mock-data.js`.
- Video paths use `../vila-safety-poc/demo_videos/` relative to `index.html`.
- When a task is done, change its status line from `[ ] TODO` to `[x] DONE — <date>`.
