# dotfiles

[English](README.md)

Debian/Ubuntu 系统自动化配置脚本 —— shell 环境与代理。

## 脚本说明

### `setup-shell.sh` — Shell 环境

安装并配置：

| 组件 | 说明 |
|------|------|
| **zsh** | 替代 bash 的现代 shell |
| **Oh My Zsh** | zsh 配置管理框架 |
| **zsh-autosuggestions** | 根据历史记录自动补全建议 |
| **zsh-syntax-highlighting** | 命令行语法高亮 |
| **z** | 快速跳转常用目录（内置插件） |
| **Starship** | 跨 shell 的美观终端提示符 |
| **Catppuccin Powerline** | Starship 主题预设 |

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

通过代理下载（无法直连 GitHub 时使用）：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

运行过程中会要求输入用户密码（用于 `chsh` 切换默认 shell）。
安装完成后，运行 `exec zsh` 或打开新终端即可生效。

### `setup-clash.sh` — Clash 代理

安装 [clash-for-linux](https://github.com/nelvko/clash-for-linux-install)，支持传入订阅链接。

```bash
# 通过参数传入订阅链接
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- https://你的订阅链接

# 通过代理下载
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- https://你的订阅链接
```

支持的环境变量：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLASH_SUB_URL` | _（空）_ | 订阅链接（也可作为第一个参数传入） |
| `CLASH_KERNEL` | `mihomo` | 代理内核（`mihomo` 或 `clash`） |
| `CLASH_GH_PROXY` | `https://gh-proxy.org` | GitHub 加速代理（设为空字符串可禁用） |

安装完成后，使用 `clashsub add <url>` 管理订阅，`clashon`/`clashoff` 开关代理。

## 完整安装

> 建议顺序：先装 clash 配好代理，再装 shell 环境，后续下载更快。

```bash
# 克隆仓库（无法直连时使用代理）
git clone https://gh-proxy.org/https://github.com/X-Zero-L/dotfiles.git
cd dotfiles

# 1. 先配代理
./setup-clash.sh https://你的订阅链接

# 2. 再装 shell 环境（此时已有代理，下载更快）
./setup-shell.sh
```

## 注意事项

- 两个脚本均支持**重复运行**，已安装的组件会自动跳过。
- 需要 `sudo` 权限安装系统包。
- Starship 需要终端支持 [Nerd Font](https://www.nerdfonts.com/) 才能正常显示图标。
- 如果 `gh-proxy.org` 不可用，可到 [ghproxy.link](https://ghproxy.link/) 查找其他可用代理。
