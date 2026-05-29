# [入门项目] 本机 CPU 部署 icefall 流式 ASR 模型

本文说明如何从 GitHub 获取部署代码，把自己导出的 icefall streaming ASR ONNX 模型部署成本机 CPU demo，并在浏览器中实时交互。

最终会启动两个本机服务：

```text
ASR WebSocket: ws://127.0.0.1:0000
Browser demo:  http://127.0.0.1:0000
```

## 1. Quick Start

系统说明：

```text
推荐系统：macOS / Linux / Windows WSL2
本文主流程：面向 macOS 和 Linux shell 环境开发
Windows 用户：建议使用 WSL2，不建议直接在原生 PowerShell/CMD 中照抄命令
```

如果你使用 Windows，推荐先安装 WSL2 Ubuntu，然后在 WSL2 终端中执行下面的命令。这样 `bash`、`.venv`、`python3`、`scripts/*.sh` 的行为和本文保持一致。

下载部署代码：

```bash
git clone https://github.com/Gilgamesh-J/deployment-for-icefall-streaming-model.git
cd deployment-for-icefall-streaming-model
```

安装本机 CPU 环境：

```bash
bash scripts/install_cpu_env.sh
```

导入模型：

```bash
bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model"
```

启动 ASR WebSocket：

```bash
MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

另开一个终端，启动浏览器页面：

```bash
cd deployment-for-icefall-streaming-model
bash scripts/run_web_demo.sh
```

浏览器打开：

```text
http://127.0.0.1:0000
```

确认页面里的 WebSocket URL 是：

```text
ws://127.0.0.1:0000
```

点击 `Start`，允许麦克风权限，即可开始实时识别。

## 2. 需要什么文件

需要两类文件：

```text
部署代码
模型文件
```

### 2.1 部署代码

部署代码来自 GitHub：

```text
https://github.com/Gilgamesh-J/deployment-for-icefall-streaming-model
```

仓库包含：

```text
deployment-for-icefall-streaming-model/
├── server/
├── scripts/
├── web/
├── examples/
├── models/
├── models.json
├── requirements.txt
├── README.md
├── MODEL_EXPANSION.md
└── NOTION_LOCAL_CPU_TUTORIAL.md
```

仓库不包含大模型 ONNX 文件。模型需要使用者自己准备，并通过 `scripts/add_model.sh` 导入。

### 2.2 模型文件

每个模型目录需要四个文件：

```text
your_model_dir/
├── encoder*.onnx
├── decoder*.onnx
├── joiner*.onnx
└── tokens*.txt
```

如果 `.onnx` 只有几百字节或几 KB，通常不是完整模型。

## 3. 仓库结构

核心结构如下：

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
├── models/
│   └── .gitkeep
├── models.json
└── requirements.txt
```

文件职责：

| 文件 | 作用 |
|---|---|
| `server/sherpa_streaming_server.py` | WebSocket ASR 服务 |
| `server/sherpa_streaming_infer.py` | sherpa-onnx 推理封装 |
| `server/sherpa_streaming_client.py` | WAV 文件测试客户端 |
| `web/index.html` | 浏览器麦克风实时 demo |
| `scripts/install_cpu_env.sh` | 创建 `.venv` 并安装依赖 |
| `scripts/check_env.py` | 检查 Python 依赖和部署文件 |
| `scripts/add_model.sh` | 导入模型并更新 `models.json` |
| `scripts/list_models.sh` | 查看已注册模型 |
| `scripts/run_server_cpu.sh` | 启动 CPU ASR WebSocket |
| `scripts/run_wav_client.sh` | 用 WAV 测试 ASR 服务 |
| `scripts/run_web_demo.sh` | 启动本地网页服务 |
| `models.json` | 模型注册表，初始为空 |

模型导入后会被复制到：

```text
models/<model_id>/
├── encoder.onnx
├── decoder.onnx
├── joiner.onnx
└── tokens.txt
```

这些本地模型文件默认被 `.gitignore` 忽略，不会被提交到 GitHub。

## 4. 如何部署

下面命令默认在 macOS、Linux 或 Windows WSL2 里执行。原生 Windows PowerShell/CMD 没有作为本文的主测试路径。

### 4.1 安装环境

进入仓库：

```bash
cd deployment-for-icefall-streaming-model
```

安装：

```bash
bash scripts/install_cpu_env.sh
```

检查：

```bash
source .venv/bin/activate
python scripts/check_env.py
```

正常情况下会看到：

```text
package numpy: ok
package websockets: ok
package soundfile: ok
package librosa: ok
package sherpa_onnx: ok
file models.json: ok
registry models: empty; add one with scripts/add_model.sh
```

这里出现 `registry models: empty` 是正常的，因为 GitHub 仓库默认不包含模型。

### 4.2 导入模型

假设模型目录是：

```text
/path/to/your_model_dir
```

导入：

```bash
bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model"
```

导入完成后查看模型：

```bash
bash scripts/list_models.sh
```

如果这是第一个导入的模型，它会自动成为默认模型。

如果源目录里有多个候选文件，可以显式指定：

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

### 4.3 启动 ASR WebSocket

启动指定模型：

```bash
MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

正常输出应包含：

```text
Starting model: my_model
WebSocket: ws://127.0.0.1:0000
CPU threads: 1
server started at ws://127.0.0.1:0000
```

这个终端不要关闭。

可选参数：

```bash
MODEL_ID=my_model PORT=0000 bash scripts/run_server_cpu.sh
MODEL_ID=my_model NUM_THREADS=4 bash scripts/run_server_cpu.sh
MODEL_ID=my_model DRY_RUN=1 bash scripts/run_server_cpu.sh
```

含义：

| 参数 | 作用 |
|---|---|
| `PORT=0000` | 改 ASR WebSocket 端口 |
| `NUM_THREADS=4` | 改 CPU 推理线程数 |
| `DRY_RUN=1` | 只打印启动命令，不真正启动 |

### 4.4 用 WAV 文件测试

另开一个终端：

```bash
cd deployment-for-icefall-streaming-model
bash scripts/run_wav_client.sh examples/sample_zh.wav
```

如果服务正常，会看到：

```text
[SERVER] {'type': 'started', ...}
[SERVER] {'type': 'partial', 'text': '...'}
[SERVER] {'type': 'final', 'text': '...'}
```

测试自己的 WAV：

```bash
bash scripts/run_wav_client.sh /path/to/test.wav
```

如果 ASR 端口不是 `0000`：

```bash
SERVER_URI=ws://127.0.0.1:0000 bash scripts/run_wav_client.sh examples/sample_zh.wav
```

## 5. 如何交互到浏览器上

保持 ASR WebSocket 终端继续运行。

另开一个终端：

```bash
cd deployment-for-icefall-streaming-model
bash scripts/run_web_demo.sh
```

正常输出：

```text
Open http://127.0.0.1:0000
```

浏览器打开：

```text
http://127.0.0.1:0000
```

页面操作：

```text
1. 确认 WebSocket URL 是 ws://127.0.0.1:0000
2. 点击 Start
3. 允许浏览器使用麦克风
4. 开始说话
5. 查看实时转写结果
```

如果 ASR 服务端口改成了 `0000`，页面里的 WebSocket URL 也要改成：

```text
ws://127.0.0.1:0000
```

如果 `0000` 被占用，可以换网页端口：

```bash
WEB_PORT=7861 bash scripts/run_web_demo.sh
```

然后打开：

```text
http://127.0.0.1:0000
```

不要直接双击打开 `web/index.html`。请使用 `http://127.0.0.1:0000`，否则浏览器可能限制麦克风权限。

## 6. 最短命令总结

终端 1：

```bash
git clone https://github.com/Gilgamesh-J/deployment-for-icefall-streaming-model.git
cd deployment-for-icefall-streaming-model

bash scripts/install_cpu_env.sh

bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model"

MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

终端 2：

```bash
cd deployment-for-icefall-streaming-model
bash scripts/run_web_demo.sh
```

浏览器：

```text
http://127.0.0.1:0000
```
