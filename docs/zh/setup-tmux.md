# setup-tmux.sh

安装 tmux、TPM 插件管理器、Catppuccin 主题及常用插件，支持完整鼠标交互。需要 `sudo`。

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| tmux | apt | 终端复用器 |
| TPM | [tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) | Tmux 插件管理器 |
| tmux-sensible | [tmux-plugins/tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) | 合理默认值（ESC 延迟修复、历史记录等） |
| Catppuccin | [catppuccin/tmux](https://github.com/catppuccin/tmux) | Catppuccin Mocha 主题 |
| vim-tmux-navigator | [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Ctrl+h/j/k/l 在 vim 和 tmux 分屏间无缝切换 |
| tmux-yank | [tmux-plugins/tmux-yank](https://github.com/tmux-plugins/tmux-yank) | 系统剪贴板集成 |
| tmux-resurrect | [tmux-plugins/tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | 保存和恢复会话 |
| tmux-continuum | [tmux-plugins/tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | 自动保存会话（基于 resurrect） |

## 生成的配置

脚本生成 `~/.tmux.conf`，包含以下部分：

### 基础设置

- 256 色 + RGB 终端支持。
- 窗口和面板从 1 开始编号（非 0）。
- `renumber-windows on` — 关闭窗口后自动重新编号，不留空隙。
- `detach-on-destroy off` — 销毁会话时切换到其他会话而非脱离。

### 鼠标交互

所有鼠标功能默认启用（`set -g mouse on`）：

| 操作 | 效果 |
|------|------|
| 左键点击 status bar 上的窗口标签 | 切换到该窗口 |
| 左键点击 session 名（status bar 左侧） | 打开 session/窗口树形选择器 |
| 右键点击面板区域 | 弹出菜单：分屏、缩放、交换、关闭 |
| 右键点击 status bar 窗口标签 | 弹出菜单：重命名、新建窗口、关闭 |
| 右键点击 session 名 | 弹出菜单：新建/重命名/关闭 session |
| 双击面板 | 切换缩放（最大化/还原） |
| 中键点击面板 | 粘贴 buffer |
| 滚轮滚动 status bar | 前后切换窗口 |
| 拖拽面板边框 | 调整面板大小 |

### 快捷导航

以下快捷键无需 prefix：

| 按键 | 操作 |
|------|------|
| `Alt+1` .. `Alt+9` | 按编号切换窗口 |
| `Alt+n` | 在当前目录新建窗口 |

### 自定义键位（可选）

默认禁用。通过 `TMUX_KEYBINDS=1` 启用：

| 按键 | 操作 | 替代原有 |
|------|------|----------|
| `Ctrl+a` | Prefix 键 | `Ctrl+b` |
| `Prefix + \|` | 垂直分屏 | `Prefix + %` |
| `Prefix + -` | 水平分屏 | `Prefix + "` |
| `Prefix + H/J/K/L` | 调整面板大小（可重复） | — |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/4 | `sudo apt install -y tmux`（已安装则跳过） |
| 2/4 | `git clone` TPM 到 `~/.tmux/plugins/tpm`（支持 `GH_PROXY`） |
| 3/4 | 生成 `~/.tmux.conf` — 与现有内容比较，仅在不同时写入 |
| 4/4 | 克隆各插件到 `~/.tmux/plugins/`（目录已存在则跳过） |

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.tmux.conf` | 生成的配置 |
| `~/.tmux/plugins/tpm/` | TPM 安装目录 |
| `~/.tmux/plugins/tmux-sensible/` | 插件 |
| `~/.tmux/plugins/tmux/` | Catppuccin 主题 |
| `~/.tmux/plugins/vim-tmux-navigator/` | 插件 |
| `~/.tmux/plugins/tmux-yank/` | 插件 |
| `~/.tmux/plugins/tmux-resurrect/` | 插件 |
| `~/.tmux/plugins/tmux-continuum/` | 插件 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TMUX_KEYBINDS` | `0` | 启用自定义键位（`1` 启用） |
| `TMUX_MOUSE` | `1` | 启用鼠标支持（`0` 禁用） |
| `TMUX_STATUS_POS` | `top` | 状态栏位置（`top` 或 `bottom`） |
| `GH_PROXY` | _（空）_ | Git clone 的 GitHub 代理 URL |

## 重复运行行为

- tmux 二进制：`tmux` 命令存在则跳过。
- TPM：`~/.tmux/plugins/tpm` 目录存在则跳过。
- 配置：重新生成并比较内容，仅在内容不同时写入。
- 插件：各插件目录存在则跳过。

## 依赖

- `sudo` 权限（apt 安装）。
- `git`（克隆 TPM 和插件）。

## 安装后

启动新的 tmux 会话：`tmux` 或 `tmux new -s work`。在现有会话中重载配置：`tmux source ~/.tmux.conf`。

后续管理插件：`Prefix + I` 安装新插件，`Prefix + U` 更新插件。
