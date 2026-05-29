#!/usr/bin/env python3
from __future__ import annotations

import importlib
import json
import platform
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = [
    ROOT / "models.json",
    ROOT / "server" / "sherpa_streaming_server.py",
    ROOT / "server" / "sherpa_streaming_client.py",
    ROOT / "server" / "sherpa_streaming_infer.py",
]


def main() -> int:
    print(f"python: {sys.version.split()[0]}")
    print(f"platform: {platform.platform()}")
    ok = True

    for name in ["numpy", "websockets", "soundfile", "librosa", "sherpa_onnx"]:
        try:
            module = importlib.import_module(name)
            version = getattr(module, "__version__", "unknown")
            print(f"package {name}: ok ({version})")
        except Exception as exc:
            ok = False
            print(f"package {name}: missing ({exc})")

    for path in REQUIRED_FILES:
        if path.is_file():
            print(f"file {path.relative_to(ROOT)}: ok")
        else:
            ok = False
            print(f"file {path.relative_to(ROOT)}: missing")

    registry_path = ROOT / "models.json"
    if registry_path.is_file():
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
        default_model = registry.get("default_model")
        models = registry.get("models", {})
        print(f"default_model: {default_model}")
        if default_model and default_model not in models:
            ok = False
            print("registry default_model: invalid")
        if not models:
            print("registry models: empty; add one with scripts/add_model.sh")
        for model_id, item in models.items():
            model_dir = ROOT / item["model_dir"]
            for key in ["tokens", "encoder", "decoder", "joiner"]:
                path = model_dir / item[key]
                if path.is_file():
                    print(f"registry {model_id}.{key}: ok")
                else:
                    ok = False
                    print(f"registry {model_id}.{key}: missing ({path})")

    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
