# Model Expansion Tutorial

This guide explains how to add streaming Zipformer transducer ONNX models into this local CPU ASR demo.

The workflow is:

```text
new model folder -> scripts/add_model.sh -> models.json -> run_server_cpu.sh
```

This repository does not ship large ONNX model files. Add your own model after cloning the repository.

## 1. Model Folder Format

A source model folder should contain:

```text
source_model_dir/
├── encoder*.onnx
├── decoder*.onnx
├── joiner*.onnx
└── tokens*.txt
```

Example:

```text
source_model_dir/
├── encoder-iter-96000-avg-3-chunk-48-left-256.onnx
├── decoder-iter-96000-avg-3-chunk-48-left-256.onnx
├── joiner-iter-96000-avg-3-chunk-48-left-256.onnx
└── tokens.txt
```

The four files must come from the same exported model.

## 2. Add a Model

Run from the repository root:

```bash
bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model"
```

This command:

```text
creates models/my_model/
copies files as encoder.onnx / decoder.onnx / joiner.onnx / tokens.txt
updates models.json
keeps the original source folder unchanged
```

If this is the first model in an empty registry, it also becomes the default model.

## 3. List Models

```bash
bash scripts/list_models.sh
```

Example after adding one model:

```text
default_model: my_model
model_id        label           model_dir        decoding_method  text_format
*my_model       My ASR Model    models/my_model  greedy_search    none
```

The `*` marks the default model.

## 4. Start a Model

Start the default model:

```bash
bash scripts/run_server_cpu.sh
```

Start a specific registered model:

```bash
MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

Use another port:

```bash
MODEL_ID=my_model PORT=8777 bash scripts/run_server_cpu.sh
```

Print the resolved command without starting the server:

```bash
MODEL_ID=my_model DRY_RUN=1 bash scripts/run_server_cpu.sh
```

## 5. Test the Model

Open another terminal:

```bash
bash scripts/run_wav_client.sh examples/sample_zh.wav
```

If the server runs on another port:

```bash
SERVER_URI=ws://127.0.0.1:8777 bash scripts/run_wav_client.sh examples/sample_zh.wav
```

## 6. Set the Default Model

```bash
python scripts/model_admin.py set-default my_model
```

Then this starts `my_model`:

```bash
bash scripts/run_server_cpu.sh
```

## 7. Remove a Model

Remove only the registry entry:

```bash
bash scripts/remove_model.sh my_model
```

Remove both the registry entry and copied files:

```bash
bash scripts/remove_model.sh my_model --delete-files
```

The default model cannot be removed. Set another default model first.

## 8. Explicit File Selection

If a source folder contains multiple candidate files, specify exact files:

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

## 9. Runtime Options

You can store runtime metadata in `models.json`:

```bash
bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model" \
  --sample-rate 16000 \
  --feature-dim 80 \
  --model-type zipformer2 \
  --decoding-method greedy_search \
  --text-format none
```

These values are read by `scripts/run_server_cpu.sh`.

## 10. Safety Checks

`add_model.sh` rejects ONNX files smaller than 1 MB by default.

Very small `.onnx` files are often Git LFS pointer files or incomplete downloads.

If a small file is expected, override the guard:

```bash
--allow-small-onnx
```

For real ASR models, especially the encoder, an ONNX file is usually much larger than 1 MB.

## 11. How It Works Internally

`models.json` is the model registry:

```json
{
  "default_model": "my_model",
  "models": {
    "my_model": {
      "label": "My ASR Model",
      "model_dir": "models/my_model",
      "tokens": "tokens.txt",
      "encoder": "encoder.onnx",
      "decoder": "decoder.onnx",
      "joiner": "joiner.onnx",
      "sample_rate": 16000,
      "feature_dim": 80,
      "model_type": "zipformer2",
      "decoding_method": "greedy_search",
      "text_format": "none"
    }
  }
}
```

`scripts/run_server_cpu.sh` calls:

```bash
python scripts/model_admin.py resolve --model-id "$MODEL_ID" --format shell
```

Then it starts:

```bash
python server/sherpa_streaming_server.py \
  --tokens ... \
  --encoder ... \
  --decoder ... \
  --joiner ... \
  --provider cpu
```

So adding a new model does not require editing server code.
