# [入门项目] 本机 CPU 部署流式 ASR Demo

本文说明如何把已经导出的 streaming ASR ONNX 模型部署成本机 CPU demo，并在浏览器里实时交互。

完成后会得到：

```text
ASR WebSocket: ws://127.0.0.1:8766
浏览器页面:     http://127.0.0.1:7860
```

## 1. Quick Start

建议先把部署代码放到一个 GitHub 仓库中，使用者直接 clone：

```bash
git clone <your-github-repo-url> local_cpu_asr_demo
cd local_cpu_asr_demo
```

安装本机 CPU 环境：

```bash
bash scripts/install_cpu_env.sh
```

导入一个模型：

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

另开一个终端，启动网页：

```bash
cd local_cpu_asr_demo
bash scripts/run_web_demo.sh
```

浏览器打开：

```text
http://127.0.0.1:7860
```

页面中 WebSocket 地址保持：

```text
ws://127.0.0.1:8766
```

点击 `Start`，允许麦克风权限，即可开始实时识别。

## 2. 需要什么文件

部署需要两类文件：部署代码和模型文件。

### 2.1 部署代码

建议用 GitHub 仓库统一分发。仓库里至少需要包含：

```text
local_cpu_asr_demo/
├── server/
├── scripts/
├── web/
├── examples/
├── requirements.txt
├── models.json
└── README.md
```

其中：

| 路径 | 作用 |
|---|---|
| `server/` | ASR WebSocket 服务和 sherpa-onnx 推理封装 |
| `scripts/` | 安装环境、导入模型、启动服务、启动网页 |
| `web/` | 浏览器实时 demo 页面 |
| `examples/` | WAV 测试音频 |
| `requirements.txt` | Python 依赖 |
| `models.json` | 模型注册表 |

### 2.2 模型文件

每个模型目录需要四个文件：

```text
your_model_dir/
├── encoder*.onnx
├── decoder*.onnx
├── joiner*.onnx
└── tokens*.txt
```

例子：

```text
my_streaming_model/
├── encoder-iter-96000-avg-3-chunk-48-left-256.onnx
├── decoder-iter-96000-avg-3-chunk-48-left-256.onnx
├── joiner-iter-96000-avg-3-chunk-48-left-256.onnx
└── tokens.txt
```

注意：

```text
encoder / decoder / joiner / tokens 必须来自同一套模型
不要混用不同模型的 tokens.txt
ONNX 文件不能是 Git LFS pointer
```

如果 `.onnx` 只有几百字节或几 KB，通常不是完整模型。真实 encoder ONNX 往往会明显大于 1MB，常见是几十 MB 到几百 MB。

## 3. 部署结构

推荐目录结构如下：

```text
local_cpu_asr_demo/
├── model/
│   ├── encoder.onnx
│   ├── decoder.onnx
│   ├── joiner.onnx
│   └── tokens.txt
├── models/
│   └── my_model/
│       ├── encoder.onnx
│       ├── decoder.onnx
│       ├── joiner.onnx
│       └── tokens.txt
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
├── requirements.txt
├── models.json
└── README.md
```

核心文件说明：

| 文件 | 作用 |
|---|---|
| `server/sherpa_streaming_server.py` | 启动 WebSocket ASR 服务 |
| `server/sherpa_streaming_infer.py` | 调用 sherpa-onnx 执行推理 |
| `server/sherpa_streaming_client.py` | 用 WAV 文件测试服务 |
| `web/index.html` | 浏览器麦克风 demo |
| `scripts/install_cpu_env.sh` | 创建 `.venv` 并安装依赖 |
| `scripts/add_model.sh` | 把模型复制进 `models/` 并写入 `models.json` |
| `scripts/run_server_cpu.sh` | 启动某个模型的 CPU ASR 服务 |
| `scripts/run_web_demo.sh` | 启动本地网页服务 |
| `models.json` | 记录所有可启动模型 |

`model/` 可以放一个默认模型。新增模型统一放到：

```text
models/<model_id>/
```

## 4. 如何部署

### 4.1 安装环境

进入部署仓库：

```bash
cd local_cpu_asr_demo
```

安装：

```bash
bash scripts/install_cpu_env.sh
```

安装完成后检查：

```bash
source .venv/bin/activate
python scripts/check_env.py
```

看到类似下面输出即可：

```text
package numpy: ok
package websockets: ok
package soundfile: ok
package librosa: ok
package sherpa_onnx: ok
file models.json: ok
```

### 4.2 导入模型

假设模型目录是：

```text
/path/to/your_model_dir
```

执行：

```bash
bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model"
```

导入后会生成：

```text
models/my_model/
├── encoder.onnx
├── decoder.onnx
├── joiner.onnx
└── tokens.txt
```

并更新：

```text
models.json
```

查看已导入模型：

```bash
bash scripts/list_models.sh
```

### 4.3 启动 ASR 服务

启动指定模型：

```bash
MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

正常输出应包含：

```text
Starting model: my_model
WebSocket: ws://127.0.0.1:8766
CPU threads: 1
server started at ws://127.0.0.1:8766
```

这个终端不要关闭。

如果想换端口：

```bash
MODEL_ID=my_model PORT=8777 bash scripts/run_server_cpu.sh
```

如果想增加 CPU 线程：

```bash
MODEL_ID=my_model NUM_THREADS=4 bash scripts/run_server_cpu.sh
```

### 4.4 用 WAV 文件测试

另开一个终端：

```bash
cd local_cpu_asr_demo
bash scripts/run_wav_client.sh examples/sample_zh.wav
```

如果服务正常，会看到：

```text
[SERVER] {'type': 'started', ...}
[SERVER] {'type': 'partial', 'text': '...'}
[SERVER] {'type': 'final', 'text': '...'}
```

也可以测试自己的音频：

```bash
bash scripts/run_wav_client.sh /path/to/test.wav
```

## 5. 如何交互到浏览器上

保持 ASR WebSocket 终端继续运行。

另开一个终端：

```bash
cd local_cpu_asr_demo
bash scripts/run_web_demo.sh
```

正常输出：

```text
Open http://127.0.0.1:7860
```

浏览器打开：

```text
http://127.0.0.1:7860
```

页面操作：

```text
1. 确认 WebSocket URL 是 ws://127.0.0.1:8766
2. 点击 Start
3. 允许浏览器使用麦克风
4. 开始说话
5. 查看实时转写结果
```

如果 ASR 服务端口改成了 `8777`，页面里的 WebSocket URL 也要改成：

```text
ws://127.0.0.1:8777
```

如果 `7860` 被占用，可以换网页端口：

```bash
WEB_PORT=7861 bash scripts/run_web_demo.sh
```

然后打开：

```text
http://127.0.0.1:7861
```

不要直接双击打开 `web/index.html`。请使用 `http://127.0.0.1:7860`，否则浏览器可能限制麦克风权限。

## 6. GitHub 仓库建议

因为部署需要同步多个脚本、网页文件和 server 文件，建议单独维护一个 GitHub 仓库，例如：

```text
local_cpu_asr_demo/
├── server/
├── scripts/
├── web/
├── examples/
├── requirements.txt
├── models.json
├── README.md
└── NOTION_LOCAL_CPU_TUTORIAL.md
```

建议不要把大模型 ONNX 直接放进普通 Git 仓库。可以选择：

```text
方案 A：GitHub 仓库只放部署代码，模型从 Hugging Face / 网盘下载
方案 B：使用 Git LFS 管理 ONNX 大文件
方案 C：每个模型单独发布，部署仓库只提供 add_model.sh 导入方式
```

更推荐方案 A 或 C。这样仓库更轻，使用者 clone 后只需要：

```bash
git clone <your-github-repo-url> local_cpu_asr_demo
cd local_cpu_asr_demo
bash scripts/install_cpu_env.sh
bash scripts/add_model.sh --source-dir /path/to/model --model-id my_model --label "My ASR Model"
MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

## 7. 最短命令总结

```bash
git clone <your-github-repo-url> local_cpu_asr_demo
cd local_cpu_asr_demo

bash scripts/install_cpu_env.sh

bash scripts/add_model.sh \
  --source-dir /path/to/your_model_dir \
  --model-id my_model \
  --label "My ASR Model"

MODEL_ID=my_model bash scripts/run_server_cpu.sh
```

另一个终端：

```bash
cd local_cpu_asr_demo
bash scripts/run_web_demo.sh
```

浏览器打开：

```text
http://127.0.0.1:7860
```
