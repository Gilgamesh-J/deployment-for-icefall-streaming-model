#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import shlex
import shutil
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = ROOT / "models.json"
MODEL_ID_RE = re.compile(r"^[A-Za-z0-9_.-]+$")


def load_registry() -> dict[str, Any]:
    if not REGISTRY_PATH.is_file():
        return {"default_model": "", "models": {}}
    return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))


def save_registry(registry: dict[str, Any]) -> None:
    REGISTRY_PATH.write_text(
        json.dumps(registry, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def validate_model_id(model_id: str) -> None:
    if not MODEL_ID_RE.match(model_id):
        raise SystemExit(
            "model id can only contain letters, digits, underscore, dash, and dot"
        )


def find_one(source_dir: Path, explicit: str | None, patterns: tuple[str, ...], label: str) -> Path:
    if explicit:
        path = source_dir / explicit
        if not path.is_file():
            raise SystemExit(f"{label} file not found: {path}")
        return path

    candidates: list[Path] = []
    for pattern in patterns:
        candidates.extend(sorted(source_dir.glob(pattern)))
    candidates = [path for path in candidates if path.is_file()]
    if not candidates:
        raise SystemExit(f"could not find {label} in {source_dir}")
    if len(candidates) > 1:
        print(f"[info] multiple {label} candidates found; using {candidates[0].name}")
    return candidates[0]


def rel(path: Path) -> str:
    return str(path.resolve().relative_to(ROOT.resolve()))


def resolve_model(registry: dict[str, Any], model_id: str | None) -> tuple[str, dict[str, Any]]:
    if not model_id:
        model_id = registry.get("default_model")
    if not model_id:
        raise SystemExit("no model id provided and no default_model is set")
    models = registry.get("models", {})
    if model_id not in models:
        known = ", ".join(sorted(models)) or "(none)"
        raise SystemExit(f"unknown model id: {model_id}; known models: {known}")
    return model_id, models[model_id]


def resolved_paths(model: dict[str, Any]) -> dict[str, str]:
    model_dir = ROOT / model["model_dir"]
    return {
        "model_dir": str(model_dir),
        "tokens": str(model_dir / model["tokens"]),
        "encoder": str(model_dir / model["encoder"]),
        "decoder": str(model_dir / model["decoder"]),
        "joiner": str(model_dir / model["joiner"]),
    }


def command_list(args: argparse.Namespace) -> int:
    registry = load_registry()
    models = registry.get("models", {})
    if args.json:
        print(json.dumps(registry, ensure_ascii=False, indent=2))
        return 0

    default_model = registry.get("default_model", "")
    print(f"default_model: {default_model}")
    print("model_id\tlabel\tmodel_dir\tdecoding_method\ttext_format")
    for model_id in sorted(models):
        item = models[model_id]
        mark = "*" if model_id == default_model else " "
        print(
            f"{mark}{model_id}\t{item.get('label', '')}\t{item.get('model_dir', '')}\t"
            f"{item.get('decoding_method', 'greedy_search')}\t{item.get('text_format', 'none')}"
        )
    return 0


def command_resolve(args: argparse.Namespace) -> int:
    registry = load_registry()
    model_id, model = resolve_model(registry, args.model_id)
    paths = resolved_paths(model)

    required = ["tokens", "encoder", "decoder", "joiner"]
    missing = [name for name in required if not Path(paths[name]).is_file()]
    if missing:
        raise SystemExit(
            "missing model files: "
            + ", ".join(f"{name}={paths[name]}" for name in missing)
        )

    data = {
        "model_id": model_id,
        "label": model.get("label", model_id),
        "sample_rate": int(model.get("sample_rate", 16000)),
        "feature_dim": int(model.get("feature_dim", 80)),
        "model_type": model.get("model_type", "zipformer2"),
        "decoding_method": model.get("decoding_method", "greedy_search"),
        "text_format": model.get("text_format", "none"),
        **paths,
    }

    if args.format == "json":
        print(json.dumps(data, ensure_ascii=False, indent=2))
        return 0

    for key, value in data.items():
        env_name = key.upper()
        print(f"{env_name}={shlex.quote(str(value))}")
    return 0


def command_add(args: argparse.Namespace) -> int:
    source_dir = args.source_dir.resolve()
    if not source_dir.is_dir():
        raise SystemExit(f"source dir not found: {source_dir}")

    validate_model_id(args.model_id)
    registry = load_registry()
    models = registry.setdefault("models", {})

    if args.model_id in models and not args.overwrite:
        raise SystemExit(f"model id already exists: {args.model_id}; use --overwrite to replace")

    tokens = find_one(source_dir, args.tokens, ("tokens.txt", "tokens_test.txt", "tokens*.txt"), "tokens")
    encoder = find_one(source_dir, args.encoder, ("encoder*.onnx",), "encoder")
    decoder = find_one(source_dir, args.decoder, ("decoder*.onnx",), "decoder")
    joiner = find_one(source_dir, args.joiner, ("joiner*.onnx",), "joiner")

    if not args.allow_small_onnx:
        small = [path for path in [encoder, decoder, joiner] if path.stat().st_size < 1024 * 1024]
        if small:
            details = ", ".join(f"{path.name}={path.stat().st_size} bytes" for path in small)
            raise SystemExit(
                "ONNX file looks too small and may be incomplete or a Git LFS pointer: "
                + details
                + ". Use --allow-small-onnx only if this is expected."
            )

    target_dir = ROOT / "models" / args.model_id
    if target_dir.exists() and args.overwrite:
        shutil.rmtree(target_dir)
    target_dir.mkdir(parents=True, exist_ok=True)

    shutil.copy2(tokens, target_dir / "tokens.txt")
    shutil.copy2(encoder, target_dir / "encoder.onnx")
    shutil.copy2(decoder, target_dir / "decoder.onnx")
    shutil.copy2(joiner, target_dir / "joiner.onnx")

    models[args.model_id] = {
        "label": args.label or args.model_id,
        "model_dir": rel(target_dir),
        "tokens": "tokens.txt",
        "encoder": "encoder.onnx",
        "decoder": "decoder.onnx",
        "joiner": "joiner.onnx",
        "sample_rate": args.sample_rate,
        "feature_dim": args.feature_dim,
        "model_type": args.model_type,
        "decoding_method": args.decoding_method,
        "text_format": args.text_format,
        "notes": args.notes,
    }

    if args.set_default or not registry.get("default_model"):
        registry["default_model"] = args.model_id

    save_registry(registry)
    print(f"added model_id={args.model_id}")
    print(f"target_dir={target_dir}")
    return 0


def command_remove(args: argparse.Namespace) -> int:
    validate_model_id(args.model_id)
    registry = load_registry()
    models = registry.get("models", {})
    if args.model_id not in models:
        raise SystemExit(f"unknown model id: {args.model_id}")
    if registry.get("default_model") == args.model_id:
        raise SystemExit("cannot remove default model; set another default first")

    model = models.pop(args.model_id)
    model_dir = ROOT / model["model_dir"]
    if args.delete_files:
        protected = {ROOT / "model", ROOT}
        if model_dir.resolve() in {item.resolve() for item in protected}:
            raise SystemExit(f"refusing to delete protected model dir: {model_dir}")
        shutil.rmtree(model_dir, ignore_errors=True)

    save_registry(registry)
    print(f"removed model_id={args.model_id}")
    if args.delete_files:
        print(f"deleted_dir={model_dir}")
    return 0


def command_set_default(args: argparse.Namespace) -> int:
    registry = load_registry()
    resolve_model(registry, args.model_id)
    registry["default_model"] = args.model_id
    save_registry(registry)
    print(f"default_model={args.model_id}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage local CPU ASR demo model registry.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_list = subparsers.add_parser("list", help="List registered models.")
    p_list.add_argument("--json", action="store_true")
    p_list.set_defaults(func=command_list)

    p_resolve = subparsers.add_parser("resolve", help="Resolve a model id to concrete files.")
    p_resolve.add_argument("--model-id", default="")
    p_resolve.add_argument("--format", choices=["shell", "json"], default="shell")
    p_resolve.set_defaults(func=command_resolve)

    p_add = subparsers.add_parser("add", help="Copy a model directory into this package and register it.")
    p_add.add_argument("--source-dir", type=Path, required=True)
    p_add.add_argument("--model-id", required=True)
    p_add.add_argument("--label", default="")
    p_add.add_argument("--tokens", default="")
    p_add.add_argument("--encoder", default="")
    p_add.add_argument("--decoder", default="")
    p_add.add_argument("--joiner", default="")
    p_add.add_argument("--sample-rate", type=int, default=16000)
    p_add.add_argument("--feature-dim", type=int, default=80)
    p_add.add_argument("--model-type", default="zipformer2")
    p_add.add_argument("--decoding-method", default="greedy_search")
    p_add.add_argument("--text-format", choices=["none", "lower", "capitalize"], default="none")
    p_add.add_argument("--notes", default="")
    p_add.add_argument("--allow-small-onnx", action="store_true")
    p_add.add_argument("--set-default", action="store_true")
    p_add.add_argument("--overwrite", action="store_true")
    p_add.set_defaults(func=command_add)

    p_remove = subparsers.add_parser("remove", help="Remove a model from the registry.")
    p_remove.add_argument("model_id")
    p_remove.add_argument("--delete-files", action="store_true")
    p_remove.set_defaults(func=command_remove)

    p_default = subparsers.add_parser("set-default", help="Set default model id.")
    p_default.add_argument("model_id")
    p_default.set_defaults(func=command_set_default)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
