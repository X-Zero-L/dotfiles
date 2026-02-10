# setup-ssh.sh

Configures OpenSSH server: custom port and key-only authentication.

## What Gets Configured

| Item | Description |
|------|-------------|
| openssh-server | Installed if missing |
| Port | Custom SSH port (optional) |
| Private key | Imported to `~/.ssh/` for outbound SSH (e.g. GitHub) |
| Public key | Added to `~/.ssh/authorized_keys` for inbound SSH |
| Password auth | Disabled when public key is provided |

## How It Works

| Step | Action |
|------|--------|
| 1/5 | Ensure `sshd` is installed and running |
| 2/5 | Import private key to `~/.ssh/` (if `SSH_PRIVATE_KEY` is set), derive `.pub` |
| 3/5 | Set custom port in `sshd_config` (if `SSH_PORT` is set) |
| 4/5 | Add public key to `~/.ssh/authorized_keys` (if `SSH_PUBKEY` is set) |
| 5/5 | Disable password auth, enable key-only login (only if `SSH_PUBKEY` is set) |

## Files Created/Modified

| File | Description |
|------|-------------|
| `/etc/ssh/sshd_config` | SSH server configuration (backed up before changes) |
| `~/.ssh/authorized_keys` | Authorized public keys (inbound) |
| `~/.ssh/id_ed25519` | Imported private key (auto-detects RSA/ECDSA) |
| `~/.ssh/id_ed25519.pub` | Derived public key |
| `~/.ssh/` | Created with `700` permissions if missing |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SSH_PORT` | _(empty)_ | Custom SSH port. Leave empty to keep current port. |
| `SSH_PUBKEY` | _(empty)_ | Public key string (e.g. `ssh-ed25519 AAAA...`). When set, adds the key and disables password auth. |
| `SSH_PRIVATE_KEY` | _(empty)_ | Private key content. When set, writes to `~/.ssh/` and derives public key. Key type auto-detected. |

## Re-run Behavior

- openssh-server: skipped if already installed.
- Port: skipped if already set to the target port.
- Private key: skipped if key file already exists.
- Public key: skipped if already in `authorized_keys`.
- Password auth: always reconfigured when `SSH_PUBKEY` is set.
- `sshd_config` is backed up before each modification.

## Dependencies

- `sudo` required.
- `openssh-server` (auto-installed if missing).

## Post-Install

If you changed the SSH port, remember to:

1. Update firewall rules: `sudo ufw allow <port>/tcp`
2. Reconnect using the new port: `ssh -p <port> user@host`

**Warning:** If you enable key-only auth, make sure your key works before closing the current session.
