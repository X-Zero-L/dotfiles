# dotfiles

一键配置 shell 开发环境的自动化脚本，适用于 Debian/Ubuntu 系统。

## 安装了什么

| 组件 | 说明 |
|------|------|
| **zsh** | 替代 bash 的现代 shell |
| **Oh My Zsh** | zsh 配置管理框架 |
| **zsh-autosuggestions** | 根据历史记录自动补全建议 |
| **zsh-syntax-highlighting** | 命令行语法高亮 |
| **z** | 快速跳转常用目录（内置插件） |
| **Starship** | 跨 shell 的美观终端提示符 |
| **Catppuccin Powerline** | Starship 主题预设 |

## 快速开始

一行命令，直接运行：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

或者克隆仓库后执行：

```bash
git clone https://github.com/X-Zero-L/dotfiles.git
cd dotfiles
./setup-shell.sh
```

运行过程中会要求输入用户密码（用于 `chsh` 切换默认 shell）。

安装完成后，运行 `exec zsh` 或打开新终端即可生效。

## 注意事项

- 脚本支持**重复运行**，已安装的组件会自动跳过。
- 需要 `sudo` 权限安装系统包。
- Starship 需要终端支持 [Nerd Font](https://www.nerdfonts.com/) 才能正常显示图标。
