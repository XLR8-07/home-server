# Linux Installation Guide

This guide covers Linux-specific installation and configuration.

## Supported Distributions

| Distribution | Status | Package Manager |
|-------------|--------|-----------------|
| Ubuntu 20.04+ | ✅ Fully Supported | apt |
| Debian 11+ | ✅ Fully Supported | apt |
| Fedora 35+ | ✅ Supported | dnf |
| CentOS Stream 9+ | ✅ Supported | dnf |
| Arch Linux | ✅ Supported | pacman |

## Prerequisites

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y curl git

# Fedora
sudo dnf install -y curl git

# Arch
sudo pacman -Sy curl git
```

## Installation

```bash
git clone https://github.com/yourusername/home-server.git
cd home-server
chmod +x install.sh
./install.sh
```

## Service Management

### rclone Mount

```bash
# Check status
sudo systemctl status rclone-seedbox

# Start/Stop/Restart
sudo systemctl start rclone-seedbox
sudo systemctl stop rclone-seedbox
sudo systemctl restart rclone-seedbox

# View logs
journalctl -u rclone-seedbox -f
```

### Jellyfin

```bash
# Check status
sudo systemctl status jellyfin

# Start/Stop/Restart
sudo systemctl start jellyfin
sudo systemctl stop jellyfin
sudo systemctl restart jellyfin

# View logs
journalctl -u jellyfin -f
```

### WireGuard VPN

```bash
# Check status
sudo systemctl status wg-quick@wg0
sudo wg show

# Start/Stop
sudo systemctl start wg-quick@wg0
sudo systemctl stop wg-quick@wg0

# View connected clients
sudo wg show wg0
```

## Mount Points

| Service | Path |
|---------|------|
| Seedbox Mount | `/mnt/seedbox` |
| Jellyfin Config | `/var/lib/jellyfin` |
| WireGuard | `/etc/wireguard` |
| rclone Config | `~/.config/rclone/rclone.conf` |

## Firewall Configuration

### UFW (Ubuntu/Debian)

```bash
# Allow Jellyfin (local network)
sudo ufw allow from 192.168.0.0/16 to any port 8096

# Allow WireGuard
sudo ufw allow 51820/udp

# Allow monitoring (local network)
sudo ufw allow from 192.168.0.0/16 to any port 3000  # Grafana
sudo ufw allow from 192.168.0.0/16 to any port 9090  # Prometheus

# Enable firewall
sudo ufw enable
```

### firewalld (Fedora/CentOS)

```bash
# Allow WireGuard
sudo firewall-cmd --permanent --add-port=51820/udp

# Allow Jellyfin
sudo firewall-cmd --permanent --add-port=8096/tcp

# Reload
sudo firewall-cmd --reload
```

## Disabling Sleep

For server use, disable automatic sleep:

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

## Troubleshooting

### rclone mount fails

1. Check if FUSE is installed:
   ```bash
   sudo apt install fuse3  # Debian/Ubuntu
   sudo dnf install fuse3  # Fedora
   ```

2. Enable user mounts in `/etc/fuse.conf`:
   ```
   user_allow_other
   ```

3. Check credentials:
   ```bash
   rclone lsd seedbox:
   ```

### Jellyfin not starting

1. Check logs:
   ```bash
   journalctl -u jellyfin -n 50
   ```

2. Verify permissions:
   ```bash
   sudo chown -R jellyfin:jellyfin /var/lib/jellyfin
   ```

### WireGuard connection issues

1. Enable IP forwarding:
   ```bash
   sudo sysctl -w net.ipv4.ip_forward=1
   echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
   ```

2. Check firewall allows UDP 51820

3. Verify keys match between client and server
