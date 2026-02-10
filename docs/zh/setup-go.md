# setup-go.sh

安装 [goenv](https://github.com/go-nv/goenv) 和 Go。

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| goenv | [go-nv/goenv](https://github.com/go-nv/goenv) | Go 版本管理器（类似 Node.js 的 nvm） |
| Go | 通过 `goenv install` | 指定版本或最新版 |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/4 | 克隆 goenv 到 `~/.goenv`（设置 `GH_PROXY` 时使用代理）。已安装则 `git pull` 更新。 |
| 2/4 | 在当前 Shell 中加载 goenv（`eval "$(goenv init -)"`) |
| 3/4 | 安装指定 Go 版本（或解析 `latest`）。已安装则跳过。设为全局默认。 |
| 4/4 | 确保 `~/.bashrc` 和 `~/.zshrc` 都有 goenv 块（`.zshrc` 不存在则跳过） |

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.goenv/` | goenv 安装目录 |
| `~/.goenv/versions/` | 已安装的 Go 版本 |
| `~/.bashrc` | 添加 goenv 初始化块 |
| `~/.zshrc` | 添加 goenv 初始化块（文件存在时） |

### Shell 配置块

```bash
# goenv START
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
# goenv END
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GO_VERSION` | `latest` | 要安装的 Go 版本（也可作为第一个参数传入） |
| `GH_PROXY` | _（空）_ | 克隆 goenv 时使用的 GitHub 代理 |
| `GO_BUILD_MIRROR_URL` | _（空）_ | Go 二进制下载镜像。设置 `GH_PROXY` 时自动使用 `https://mirrors.aliyun.com/golang/`。 |

## 重复运行行为

- goenv：已安装时执行 `git pull` 更新。
- Go 版本：已安装则跳过。
- Shell 配置：已有 `goenv START` 块则跳过。

## 依赖

- `git`、`curl`。
- 不需要 `sudo`。

## 安装后

```bash
source ~/.zshrc     # 或打开新终端
go version          # 验证安装
goenv versions      # 列出已安装版本
goenv install 1.23.0  # 安装其他版本
goenv global 1.23.0   # 切换全局版本
```
