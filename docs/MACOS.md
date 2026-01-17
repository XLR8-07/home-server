# macOS Installation Guide

This guide covers macOS-specific installation and configuration.

## Supported Versions

| macOS Version | Chip | Status |
|--------------|------|--------|
| macOS 12 Monterey+ | Intel | ✅ Supported |
| macOS 12 Monterey+ | Apple Silicon (M1/M2/M3) | ✅ Supported |

## Prerequisites

### Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Docker Desktop (for monitoring)

```bash
brew install --cask docker
```

Then launch Docker Desktop from Applications.

### Install macFUSE (for rclone mount)

```bash
brew install --cask macfuse
```

**Important:** After installing macFUSE, you need to:
1. Open System Preferences → Security & Privacy
2. Click "Allow" for the macFUSE kernel extension
3. Restart your Mac

## Installation

```bash
git clone https://github.com/yourusername/home-server.git
cd home-server
chmod +x install.sh
./install.sh
```

## Service Management

### rclone Mount

macOS uses LaunchAgents instead of systemd:

```bash
# Check status
launchctl list | grep rclone

# Start
launchctl load ~/Library/LaunchAgents/com.rclone.seedbox.plist

# Stop
launchctl unload ~/Library/LaunchAgents/com.rclone.seedbox.plist

# View logs
cat ~/Library/Logs/rclone-seedbox.log
```

### Jellyfin

```bash
# Start Jellyfin
open -a Jellyfin

# Check if running
pgrep -x Jellyfin

# Kill Jellyfin
pkill Jellyfin
```

To start Jellyfin at login:
- System Preferences → Users & Groups → Login Items → Add Jellyfin

### Docker Services (Monitoring)

```bash
cd monitoring

# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Restart services
docker compose restart
```

## Mount Points

| Service | Path |
|---------|------|
| Seedbox Mount | `~/seedbox` |
| Jellyfin App | `/Applications/Jellyfin.app` |
| Jellyfin Data | `~/Library/Application Support/Jellyfin` |
| rclone Config | `~/.config/rclone/rclone.conf` |
| LaunchAgents | `~/Library/LaunchAgents/` |

## Power Settings for Server Use

Prevent Mac from sleeping:

```bash
# Disable sleep
sudo pmset -a sleep 0
sudo pmset -a disksleep 0

# Disable hibernation
sudo pmset -a hibernatemode 0

# Enable Wake on LAN
sudo pmset -a womp 1

# Check current settings
pmset -g
```

## Remote Access

### Enable SSH

System Preferences → Sharing → Remote Login

Or via terminal:
```bash
sudo systemsetup -setremotelogin on
```

### Enable Screen Sharing (VNC)

System Preferences → Sharing → Screen Sharing

Or via terminal:
```bash
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
```

## Firewall Configuration

### Using System Preferences

System Preferences → Security & Privacy → Firewall → Firewall Options
- Add Jellyfin to allowed apps
- Add Docker to allowed apps

### Using pf (advanced)

```bash
# Edit /etc/pf.conf to add rules
# WireGuard
pass in on en0 proto udp from any to any port 51820
```

## WireGuard on macOS

macOS can be used as a VPN client or server:

### As Client (Recommended)

1. Install WireGuard app from App Store
2. Import configuration file generated on your Linux server
3. Or scan QR code

### As Server

The setup script can configure macOS as a WireGuard server, but it requires:
- Keeping the Mac always on
- Port forwarding on your router
- Additional pf firewall configuration

## Troubleshooting

### macFUSE not working

1. Check System Preferences → Security & Privacy for blocked extension
2. Restart Mac after allowing extension
3. Verify macFUSE is loaded:
   ```bash
   kextstat | grep macfuse
   ```

### rclone mount disappears

1. Check LaunchAgent is loaded:
   ```bash
   launchctl list | grep rclone
   ```

2. Check for errors in logs:
   ```bash
   cat ~/Library/Logs/rclone-seedbox.log
   ```

### Docker not starting

1. Ensure Docker Desktop is running
2. Check Docker daemon status:
   ```bash
   docker info
   ```

3. Reset Docker Desktop if needed (Docker menu → Troubleshoot → Reset)

### Jellyfin can't access mounted files

Jellyfin may need Full Disk Access:
1. System Preferences → Security & Privacy → Privacy → Full Disk Access
2. Add Jellyfin.app

### Network issues with WireGuard

1. Check if WireGuard is interfering with DNS:
   - Try changing DNS in WireGuard config
   
2. Verify IP forwarding is enabled:
   ```bash
   sysctl net.inet.ip.forwarding
   ```
