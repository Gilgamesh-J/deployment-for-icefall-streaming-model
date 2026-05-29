# Deployment for icefall Streaming ASR Models

This repository provides a small local CPU deployment demo for streaming ASR models exported from icefall-style Zipformer transducer recipes.

It starts:

```text
ASR WebSocket: ws://127.0.0.1:8766
Browser demo:  http://127.0.0.1:7860
```

The repository contains only deployment code. It does not include large ONNX model files. Add your own exported model with `scripts/add_model.sh`.

## Quick Start

### macOS / Linux / Windows WSL2

Clone the repository:

```bash
git clone https://github.com/Gilgamesh-J/deployment-for-icefall-streaming-model.git
cd deployment-for-icefall-streaming-model
```

Install the local CPU environment:

```bash
bash scripts/install_cpu_env.sh
```

Add your model:

```bash
bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model"
```

Start the ASR WebSocket server:

```bash
MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

Open a second terminal and start the browser page:

```bash
cd deployment-for-icefall-streaming-model
bash scripts/run_web_demo.sh
```

Open:

```text
http://127.0.0.1:7860
```

Keep the WebSocket URL as:

```text
ws://127.0.0.1:8766
```

Click `Start`, allow microphone access, and speak.

### Windows PowerShell

Open PowerShell, then run:

```powershell
git clone https://github.com/Gilgamesh-J/deployment-for-icefall-streaming-model.git
cd deployment-for-icefall-streaming-model
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\scripts\install_cpu_env.ps1

.\scripts\add_model.ps1 `
  --source-dir C:\path\to\your_model_dir `
  --model-id my_model `
  --label "My ASR Model"

.\scripts\run_server_cpu.ps1 -ModelId my_model
```

Open a second PowerShell window:

```powershell
cd deployment-for-icefall-streaming-model
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\run_web_demo.ps1
```

Open:

```text
http://127.0.0.1:7860
```

Keep the WebSocket URL as:

```text
ws://127.0.0.1:8766
```

## Required Model Files

Each deployable model folder should contain:

```text
your_model_dir/
├── encoder*.onnx
├── decoder*.onnx
├── joiner*.onnx
└── tokens*.txt
```

Example:

```text
my_streaming_model/
├── encoder-iter-96000-avg-3-chunk-48-left-256.onnx
├── decoder-iter-96000-avg-3-chunk-48-left-256.onnx
├── joiner-iter-96000-avg-3-chunk-48-left-256.onnx
└── tokens.txt
```

The encoder, decoder, joiner, and tokens file must come from the same exported model. Do not mix `tokens.txt` from another model.

If an ONNX file is only a few hundred bytes or a few KB, it is likely a Git LFS pointer or an incomplete download rather than a real model file.

## Repository Structure

```text
deployment-for-icefall-streaming-model/
├── server/
│   ├── sherpa_streaming_infer.py
│   ├── sherpa_streaming_server.py
│   └── sherpa_streaming_client.py
├── scripts/
│   ├── install_cpu_env.sh
│   ├── check_env.py
│   ├── model_admin.py
│   ├── add_model.sh
│   ├── list_models.sh
│   ├── remove_model.sh
│   ├── run_server_cpu.sh
│   ├── run_wav_client.sh
│   └── run_web_demo.sh
├── web/
│   └── index.html
├── examples/
│   ├── sample_zh.wav
│   └── sample_en.wav
├── models.json
├── requirements.txt
├── MODEL_EXPANSION.md
├── NOTION_LOCAL_CPU_TUTORIAL.md
└── README.md
```

Key files:

| Path | Purpose |
|---|---|
| `server/sherpa_streaming_server.py` | WebSocket ASR server |
| `server/sherpa_streaming_infer.py` | sherpa-onnx streaming inference wrapper |
| `server/sherpa_streaming_client.py` | WAV-file test client |
| `web/index.html` | Browser microphone demo |
| `scripts/install_cpu_env.sh` | Create `.venv` and install dependencies |
| `scripts/add_model.sh` | Copy a model into `models/` and update `models.json` |
| `scripts/run_server_cpu.sh` | Start a registered model on CPU |
| `scripts/run_web_demo.sh` | Start the local browser page |
| `models.json` | Model registry |

## Install

Recommended environment:

| Item | Requirement |
|---|---|
| OS | macOS / Linux / Windows WSL2 / Windows PowerShell |
| Python | 3.9 or newer |
| Runtime | CPU |
| Browser | Chrome / Edge / Safari |

For native Windows PowerShell, use the `.ps1` scripts. For macOS, Linux, and WSL2, use the `.sh` scripts.

Install:

```bash
bash scripts/install_cpu_env.sh
```

Check the environment:

```bash
source .venv/bin/activate
python scripts/check_env.py
```

Expected output includes:

```text
package numpy: ok
package websockets: ok
package soundfile: ok
package librosa: ok
package sherpa_onnx: ok
file models.json: ok
```

Windows PowerShell equivalent:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\install_cpu_env.ps1
.\.venv\Scripts\python.exe scripts\check_env.py
```

## Add a Model

```bash
bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model"
```

This creates:

```text
models/my_model/
├── encoder.onnx
├── decoder.onnx
├── joiner.onnx
└── tokens.txt
```

It also updates `models.json`.

List registered models:

```bash
bash scripts/list_models.sh
```

Windows PowerShell equivalent:

```powershell
.\scripts\add_model.ps1 `
  --source-dir C:\path\to\your_model_dir `
  --model-id my_model `
  --label "My ASR Model"

.\scripts\list_models.ps1
```

If the source folder contains multiple candidate files, specify the exact files:

```bash
bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model" \
  --tokens tokens.txt \
  --encoder encoder-iter-96000-avg-3-chunk-48-left-256.onnx \
  --decoder decoder-iter-96000-avg-3-chunk-48-left-256.onnx \
  --joiner joiner-iter-96000-avg-3-chunk-48-left-256.onnx
```

## Start the ASR Server

```bash
MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

Default address:

```text
ws://127.0.0.1:8766
```

Use another port:

```bash
MODEL_ID=my_model PORT=8777 bash scripts/run_server_cpu.sh
```

Use more CPU threads:

```bash
MODEL_ID=my_model NUM_THREADS=4 bash scripts/run_server_cpu.sh
```

Print the resolved command without starting the server:

```bash
MODEL_ID=my_model DRY_RUN=1 bash scripts/run_server_cpu.sh
```

Windows PowerShell equivalent:

```powershell
.\scripts\run_server_cpu.ps1 -ModelId my_model
.\scripts\run_server_cpu.ps1 -ModelId my_model -Port 8777
.\scripts\run_server_cpu.ps1 -ModelId my_model -NumThreads 4
.\scripts\run_server_cpu.ps1 -ModelId my_model -DryRun
```

## Test with a WAV File

Keep the ASR server running. Open another terminal:

```bash
cd deployment-for-icefall-streaming-model
bash scripts/run_wav_client.sh examples/sample_zh.wav
```

Expected output:

```text
[SERVER] {'type': 'started', ...}
[SERVER] {'type': 'partial', 'text': '...'}
[SERVER] {'type': 'final', 'text': '...'}
```

Use your own WAV:

```bash
bash scripts/run_wav_client.sh /path/to/test.wav
```

Windows PowerShell equivalent:

```powershell
.\scripts\run_wav_client.ps1 examples\sample_zh.wav
```

If the server runs on another port:

```powershell
$env:SERVER_URI = "ws://127.0.0.1:8777"
.\scripts\run_wav_client.ps1 examples\sample_zh.wav
```

## Browser Interaction

Keep the ASR server running. Open another terminal:

```bash
cd deployment-for-icefall-streaming-model
bash scripts/run_web_demo.sh
```

Open:

```text
http://127.0.0.1:7860
```

Steps:

```text
1. Confirm WebSocket URL: ws://127.0.0.1:8766
2. Click Start
3. Allow microphone access
4. Speak
5. Read the live transcript
```

If the ASR server uses another port, update the WebSocket URL in the page.

If port `7860` is occupied:

```bash
WEB_PORT=7861 bash scripts/run_web_demo.sh
```

Then open:

```text
http://127.0.0.1:7861
```

Do not open `web/index.html` directly with `file://`; browser microphone permissions may be blocked. Use `http://127.0.0.1:7860`.

Windows PowerShell equivalent:

```powershell
.\scripts\run_web_demo.ps1
.\scripts\run_web_demo.ps1 -WebPort 7861
```

## Notes on Model Files

Large ONNX files are intentionally not committed to this repository. Recommended workflows:

```text
Option A: Put deployment code in GitHub and host models on Hugging Face or another release page.
Option B: Use Git LFS for ONNX files if you really want models in the same repository.
Option C: Keep each model release separate and import it with scripts/add_model.sh.
```

For most users, Option A or C is simpler.

## More Documentation

- `NOTION_LOCAL_CPU_TUTORIAL.md`: concise Notion-style deployment tutorial.
- `MODEL_EXPANSION.md`: how to add, list, remove, and switch models.
