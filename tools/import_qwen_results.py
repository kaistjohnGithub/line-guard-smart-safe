"""
Import Qwen JSON results into Line Guard web app.

Usage:
    # Import existing results_qwen JSON file
    python tools/import_qwen_results.py --json results_qwen/sample_forklift_safety_qwen_descriptions.json --camera CAM-A04

    # Run Qwen then import automatically
    python tools/import_qwen_results.py --video demo_videos/sample.mp4 --camera CAM-A04 --run-qwen

Options:
    --json      Path to existing Qwen JSON output file
    --video     Path to video (used with --run-qwen)
    --camera    Camera ID (e.g. CAM-A04)
    --api       Backend API URL (default: http://localhost:8000)
    --run-qwen  Run describe_video_qwen.py first, then import
    --model     Qwen model variant (default: 3b-4bit)
    --interval  Frame interval in seconds (default: 3)
"""
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

import requests


def load_json(json_path: str) -> dict:
    with open(json_path, encoding="utf-8") as f:
        return json.load(f)


def run_qwen(video_path: str, model: str, interval: float, output_dir: str) -> str:
    """Run describe_video_qwen.py and return path to output JSON."""
    script = Path(__file__).parent.parent.parent / "vila-safety-poc" / "describe_video_qwen.py"
    if not script.exists():
        # fallback: assume in PATH
        script = "describe_video_qwen.py"

    video_name = Path(video_path).stem
    out_json = Path(output_dir) / f"{video_name}_qwen_descriptions.json"

    cmd = [
        sys.executable, str(script),
        "--video", video_path,
        "--model", model,
        "--interval", str(interval),
        "--save-frames",
        "--output", output_dir,
    ]
    print(f"Running: {' '.join(cmd)}\n")
    subprocess.run(cmd, check=True)
    return str(out_json)


def import_to_api(data: dict, camera_id: str, api_url: str) -> dict:
    """POST Qwen results to /api/analyze/import."""
    payload = {
        "camera_id": camera_id,
        "video": data.get("video", ""),
        "model": data.get("model", "Qwen/Qwen2.5-VL-3B-Instruct"),
        "interval_sec": data.get("interval_sec", 3.0),
        "frames": [
            {
                "timestamp_str": f.get("timestamp_str", ""),
                "timestamp_sec": f.get("timestamp_sec", 0.0),
                "frame_idx": f.get("frame_idx", 0),
                "description": f.get("description", ""),
                "latency_ms": f.get("latency_ms", 0),
            }
            for f in data.get("frames", [])
        ],
    }

    url = f"{api_url.rstrip('/')}/api/analyze/import"
    print(f"Importing {len(payload['frames'])} frames -> {url}")
    resp = requests.post(url, json=payload)
    resp.raise_for_status()
    return resp.json()


def main():
    parser = argparse.ArgumentParser(description="Import Qwen results into Line Guard")
    parser.add_argument("--json",      help="Path to Qwen JSON output file")
    parser.add_argument("--video",     help="Video path (use with --run-qwen)")
    parser.add_argument("--camera",    required=True, help="Camera ID (e.g. CAM-A04)")
    parser.add_argument("--api",       default="http://localhost:8000", help="Backend API URL")
    parser.add_argument("--run-qwen",  action="store_true", help="Run Qwen before importing")
    parser.add_argument("--model",     default="3b-4bit", help="Qwen model variant")
    parser.add_argument("--interval",  type=float, default=3.0, help="Frame interval (sec)")
    args = parser.parse_args()

    if args.run_qwen:
        if not args.video:
            print("ERROR: --video required with --run-qwen")
            sys.exit(1)
        with tempfile.TemporaryDirectory() as tmpdir:
            json_path = run_qwen(args.video, args.model, args.interval, tmpdir)
            data = load_json(json_path)
    elif args.json:
        data = load_json(args.json)
    else:
        print("ERROR: provide --json or use --run-qwen --video")
        sys.exit(1)

    result = import_to_api(data, args.camera, args.api)

    print("\n[OK] Import successful!")
    print(f"  Job ID     : {result['job_id']}")
    print(f"  Camera     : {result['camera_id']}")
    print(f"  Frames     : {result['total_frames']}")
    print(f"  DANGER     : {result['summary']['DANGER']}")
    print(f"  WARNING    : {result['summary']['WARNING']}")
    print(f"  SAFE       : {result['summary']['SAFE']}")
    print(f"\n  View results at: {args.api.rstrip('/')}/api/analyze/{result['job_id']}")


if __name__ == "__main__":
    main()
