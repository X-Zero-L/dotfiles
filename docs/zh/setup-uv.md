# setup-uv.sh

安装 [uv](https://docs.astral.sh/uv/) 包管理器，可选安装 Python 版本。

## 操作系统支持

uv 适用于所有支持的平台（Linux 和 macOS）。无需操作系统特定的包管理器：

| 操作系统 | 状态 |
|---------|------|
| Debian/Ubuntu | ✓ |
| CentOS/RHEL | ✓ |
| Fedora | ✓ |
| Arch Linux | ✓ |
| macOS | ✓ |

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| uv | [astral.sh/uv](https://astral.sh/uv/) | 高性能 Python 包和项目管理器 |
| Python | 通过 `uv python install` | 可选，指定版本 |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/2 | 从 astral.sh 下载并运行 uv 安装脚本。已安装则执行 `uv self update`。 |
| 2/2 | 如设置 `UV_PYTHON`，执行 `uv python install <version>` |

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.local/bin/uv` | uv 二进制文件 |
| `~/.local/bin/uvx` | uvx（uv 工具运行器） |
| `~/.local/share/uv/` | uv 缓存和数据目录 |
| `~/.local/share/uv/python/` | 已安装的 Python 版本 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `UV_PYTHON` | _（空）_ | 要安装的 Python 版本（也可作为第一个参数传入）。留空则跳过 Python 安装。 |

## 重复运行行为

- uv：已安装时执行 `uv self update` 升级到最新版。
- Python：`uv python install` 内部处理已有版本。

## 依赖

- `curl`。
- 不需要 `sudo`。

## 安装后

运行 `source ~/.zshrc` 或打开新终端，然后：

```bash
uv init myproject       # 创建新项目
uv add requests         # 添加依赖
uv run python main.py   # 使用托管的 Python 运行
```
