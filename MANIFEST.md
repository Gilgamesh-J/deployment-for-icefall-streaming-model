# Package Manifest

This repository contains deployment code for local CPU streaming ASR demos. It does not include large ONNX model files.

## Runtime

- `server/sherpa_streaming_infer.py`: sherpa-onnx recognizer wrapper
- `server/sherpa_streaming_server.py`: WebSocket ASR server
- `server/sherpa_streaming_client.py`: WAV-file WebSocket client

## Demo

- `web/index.html`: local browser microphone demo
- `examples/sample_zh.wav`: sample Chinese WAV
- `examples/sample_en.wav`: sample English WAV

## Scripts

- `scripts/install_cpu_env.sh`: create `.venv` and install dependencies
- `scripts/check_env.py`: verify Python packages and deployment files
- `scripts/model_admin.py`: add/list/resolve/remove registered models
- `scripts/add_model.sh`: copy a model into `models/<model_id>/` and update `models.json`
- `scripts/list_models.sh`: list registered models
- `scripts/remove_model.sh`: remove registered models
- `scripts/run_server_cpu.sh`: start CPU WebSocket ASR server
- `scripts/run_wav_client.sh`: test with a WAV file
- `scripts/run_web_demo.sh`: serve browser demo at `http://127.0.0.1:7860`
- `scripts/package.sh`: create a source package without local model weights

## Registry and Docs

- `models.json`: model registry; initially empty
- `requirements.txt`: Python dependencies
- `README.md`: main deployment guide
- `MODEL_EXPANSION.md`: adding and switching models
- `NOTION_LOCAL_CPU_TUTORIAL.md`: concise Notion-style tutorial

## Files Created Locally After Use

These are intentionally ignored by Git:

- `.venv/`
- `models/<model_id>/encoder.onnx`
- `models/<model_id>/decoder.onnx`
- `models/<model_id>/joiner.onnx`
- `models/<model_id>/tokens.txt`
