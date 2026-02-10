# setup-ssh.sh

Configures OpenSSH server: custom port, key-only authentication, and GitHub SSH proxy.

## What Gets Configured

| Item | Description |
|------|-------------|
| openssh-server | Installed if missing |
| Port | Custom SSH port (optional) |
| Private key | Imported to `~/.ssh/` for outbound SSH (e.g. GitHub) |
| Public key | Added to `~/.ssh/authorized_keys` for inbound SSH |
| Password auth | Disabled when public key is provided |
| GitHub SSH proxy | `~/.ssh/config` with port 443 + corkscrew proxy (optional) |

## How It Works

| Step | Action |
|------|--------|
| 1/6 | Ensure `sshd` is installed and running |
| 2/6 | Import private key to `~/.ssh/` (if `SSH_PRIVATE_KEY` is set), derive `.pub` |
| 3/6 | Set custom port in `sshd_config` (if `SSH_PORT` is set) |
| 4/6 | Add public key to `~/.ssh/authorized_keys` (if `SSH_PUBKEY` is set) |
| 5/6 | Disable password auth, enable key-only login (only if `SSH_PUBKEY` is set) |
| 6/6 | Configure GitHub SSH proxy in `~/.ssh/config` (if `SSH_PROXY_PORT` is set) |

## Files Created/Modified

| File | Description |
|------|-------------|
| `/etc/ssh/sshd_config` | SSH server configuration (backed up before changes) |
| `~/.ssh/authorized_keys` | Authorized public keys (inbound) |
| `~/.ssh/id_ed25519` | Imported private key (auto-detects RSA/ECDSA) |
| `~/.ssh/id_ed25519.pub` | Derived public key |
| `~/.ssh/config` | SSH client config with GitHub proxy settings |
| `~/.ssh/` | Created with `700` permissions if missing |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SSH_PORT` | _(empty)_ | Custom SSH port. Leave empty to keep current port. |
| `SSH_PUBKEY` | _(empty)_ | Public key string (e.g. `ssh-ed25519 AAAA...`). When set, adds the key and disables password auth. |
| `SSH_PRIVATE_KEY` | _(empty)_ | Private key content. When set, writes to `~/.ssh/` and derives public key. Key type auto-detected. |
| `SSH_PROXY_HOST` | `127.0.0.1` | Proxy host for GitHub SSH. Only used when `SSH_PROXY_PORT` is set. |
| `SSH_PROXY_PORT` | _(empty)_ | Proxy port (e.g. `7890`). When set, configures `~/.ssh/config` to connect to GitHub via `ssh.github.com:443` through a corkscrew proxy. Useful when port 22 is blocked or a proxy is required. |

## Re-run Behavior

- openssh-server: skipped if already installed.
- Port: skipped if already set to the target port.
- Private key: skipped if key file already exists.
- Public key: skipped if already in `authorized_keys`.
- Password auth: always reconfigured when `SSH_PUBKEY` is set.
- GitHub SSH config: skipped if `Host github.com` block already exists in `~/.ssh/config`.
- `sshd_config` is backed up before each modification.

## Dependencies

- `sudo` required.
- `openssh-server` (auto-installed if missing).
- `corkscrew` (auto-installed if `SSH_PROXY_PORT` is set).

## Post-Install

If you changed the SSH port, remember to:

1. Update firewall rules: `sudo ufw allow <port>/tcp`
2. Reconnect using the new port: `ssh -p <port> user@host`

**Warning:** If you enable key-only auth, make sure your key works before closing the current session.

Test GitHub SSH connectivity: `ssh -T git@github.com`
