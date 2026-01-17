<p align="center">
  <img src="https://raw.githubusercontent.com/selfhst/icons/main/svg/jellyfin.svg" width="80" alt="Home Server">
</p>

<h1 align="center">🏠 Home Server</h1>

<p align="center">
  <strong>A comprehensive, cross-platform home media server with monitoring, metrics, and secure remote access</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#screenshots">Screenshots</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue?style=for-the-badge&logo=linux&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/Docker-Enabled-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
</p>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎬 Media Server
- **Jellyfin** - Free, open-source media streaming
- **rclone** - Mount remote seedbox via SFTP
- **Persistent mounts** - Auto-reconnect on boot
- **Hardware transcoding** - GPU acceleration support

</td>
<td width="50%">

### 📊 Monitoring & Metrics
- **Prometheus** - Time-series metrics collection
- **Grafana** - Beautiful dashboards & visualization
- **Loki** - Centralized log aggregation
- **Alertmanager** - Smart alert routing

</td>
</tr>
<tr>
<td width="50%">

### 🔐 Secure Remote Access
- **WireGuard VPN** - Fast, modern VPN protocol
- **QR Code generation** - Easy mobile setup
- **Split tunneling** - Route only home traffic
- **Multi-client support** - Connect all your devices

</td>
<td width="50%">

### 🖥️ Cross-Platform
- **Linux** - Ubuntu, Debian, Fedora, Arch
- **macOS** - Intel & Apple Silicon
- **Automated setup** - Interactive installer
- **Platform-specific optimizations**

</td>
</tr>
</table>

---

## 🛠️ Tech Stack

<p align="center">
  <img src="https://img.shields.io/badge/Jellyfin-00A4DC?style=for-the-badge&logo=jellyfin&logoColor=white" alt="Jellyfin">
  <img src="https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white" alt="Prometheus">
  <img src="https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white" alt="Grafana">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
</p>
<p align="center">
  <img src="https://img.shields.io/badge/WireGuard-88171A?style=for-the-badge&logo=wireguard&logoColor=white" alt="WireGuard">
  <img src="https://img.shields.io/badge/rclone-3F79AD?style=for-the-badge&logo=rclone&logoColor=white" alt="rclone">
  <img src="https://img.shields.io/badge/Loki-F7D14C?style=for-the-badge&logo=grafana&logoColor=black" alt="Loki">
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
</p>

---

## 📸 Screenshots

<details>
<summary><b>🖥️ Interactive Installer</b></summary>
<br>
<p align="center">
  <img src="docs/images/installer-preview.svg" alt="Installer Preview" width="700">
</p>
</details>

<details>
<summary><b>📊 Grafana Dashboard</b></summary>
<br>
<p align="center">
  <img src="docs/images/grafana-dashboard.svg" alt="Grafana Dashboard" width="900">
</p>
</details>

<details>
<summary><b>🔐 VPN Architecture</b></summary>
<br>
<p align="center">
  <img src="docs/images/vpn-diagram.svg" alt="VPN Diagram" width="800">
</p>
</details>

---

## 📐 Architecture

<p align="center">
  <img src="docs/images/architecture.svg" alt="Architecture Diagram" width="800">
</p>

<details>
<summary><b>📝 Text Version</b></summary>

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HOME SERVER                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Jellyfin  │    │  Prometheus │    │   Grafana   │    │  WireGuard  │  │
│  │   :8096     │    │    :9090    │    │    :3000    │    │   :51820    │  │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘  │
│         │                  │                  │                  │         │
│         │           ┌──────┴──────┐           │                  │         │
│         │           │    Loki     │───────────┘                  │         │
│         │           │    :3100    │                              │         │
│         │           └──────┬──────┘                              │         │
│         │                  │                                     │         │
│  ┌──────┴──────────────────┴─────────────────────────────────────┴──────┐  │
│  │                         System Layer                                  │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │   rclone    │  │ Node Export │  │  cAdvisor   │  │  Promtail   │  │  │
│  │  │   mount     │  │    :9100    │  │    :8080    │  │   (logs)    │  │  │
│  │  └──────┬──────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └─────────┼────────────────────────────────────────────────────────────┘  │
│            │                                                               │
└────────────┼───────────────────────────────────────────────────────────────┘
             │
             ▼
      ┌─────────────┐
      │   Seedbox   │
      │   (SFTP)    │
      └─────────────┘
```

</details>

---

## 🚀 Quick Start

### Prerequisites

| Platform | Requirements |
|----------|-------------|
| **Linux** | `curl`, `git`, Docker (optional for monitoring) |
| **macOS** | Homebrew, Docker Desktop (optional for monitoring) |

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/home-server.git
cd home-server

# Make installer executable
chmod +x install.sh

# Run the interactive installer
./install.sh
```

### Quick Install Options

```bash
# Full setup (Jellyfin + Seedbox + Monitoring + VPN)
./install.sh --full

# Media server only
./install.sh --media

# Monitoring stack only
./install.sh --monitoring

# VPN setup only
./install.sh --vpn

# Health check
./install.sh --health
```

---

## 📁 Project Structure

```
home-server/
├── 📄 install.sh                    # Main interactive installer
├── 📄 README.md                     # This file
│
├── 📂 scripts/
│   ├── 📂 common/                   # Shared utilities
│   │   ├── colors.sh               # Terminal colors
│   │   ├── utils.sh                # Helper functions
│   │   ├── health.sh               # Health check
│   │   └── monitoring.sh           # Monitoring deployment
│   │
│   ├── 📂 linux/                    # Linux-specific scripts
│   │   ├── setup.sh                # Main Linux setup
│   │   ├── rclone.sh               # rclone configuration
│   │   └── vpn.sh                  # WireGuard setup
│   │
│   └── 📂 macos/                    # macOS-specific scripts
│       ├── setup.sh                # Main macOS setup
│       ├── rclone.sh               # rclone with LaunchAgent
│       └── vpn.sh                  # WireGuard (client/server)
│
├── 📂 monitoring/                   # Docker-based monitoring
│   ├── docker-compose.yml          # Full monitoring stack
│   ├── 📂 prometheus/
│   │   ├── prometheus.yml          # Prometheus config
│   │   ├── alerts.yml              # Alert rules
│   │   └── alertmanager.yml        # Alert routing
│   ├── 📂 grafana/
│   │   ├── 📂 provisioning/        # Auto-provisioning
│   │   └── 📂 dashboards/          # Pre-built dashboards
│   ├── 📂 loki/
│   │   └── loki-config.yml         # Log aggregation config
│   └── 📂 promtail/
│       └── promtail-config.yml     # Log collection config
│
├── 📂 vpn/
│   ├── 📂 wireguard/               # Configuration templates
│   │   ├── server.conf.template
│   │   └── client.conf.template
│   └── 📂 clients/                 # Generated client configs
│
├── 📂 config/
│   └── .env.example                # Environment template
│
└── 📂 docs/                         # Additional documentation
    ├── LINUX.md
    ├── MACOS.md
    └── VPN.md
```

---

## 📊 Monitoring Dashboards

The monitoring stack includes pre-configured Grafana dashboards for:

| Dashboard | Metrics |
|-----------|---------|
| **System Overview** | CPU, Memory, Disk, Network |
| **Container Metrics** | Docker container stats via cAdvisor |
| **Logs Explorer** | Centralized logs from all services |
| **Alerts** | Active and historical alerts |

### Accessing Dashboards

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Grafana** | `http://<server-ip>:3000` | admin / admin |
| **Prometheus** | `http://<server-ip>:9090` | - |
| **Alertmanager** | `http://<server-ip>:9093` | - |
| **Jellyfin** | `http://<server-ip>:8096` | Setup on first access |

---

## 🔐 VPN Remote Access

WireGuard provides secure, high-performance VPN access to your home server from anywhere.

### Features

- ⚡ **Fast** - WireGuard is significantly faster than OpenVPN
- 🔒 **Secure** - Modern cryptography (Curve25519, ChaCha20, Poly1305)
- 📱 **Mobile Ready** - QR codes for easy phone setup
- 🔀 **Split Tunnel** - Route only home network traffic through VPN

### Client Setup

1. Run VPN setup on server: `./install.sh --vpn`
2. Generate client config
3. Scan QR code with WireGuard app (iOS/Android)
4. Or import `.conf` file on desktop

### Supported Clients

| Platform | App |
|----------|-----|
| iOS | [WireGuard](https://apps.apple.com/app/wireguard/id1441195209) |
| Android | [WireGuard](https://play.google.com/store/apps/details?id=com.wireguard.android) |
| macOS | [WireGuard](https://apps.apple.com/app/wireguard/id1451685025) |
| Windows | [WireGuard](https://www.wireguard.com/install/) |
| Linux | `apt install wireguard` |

---

## 📈 Metrics & Alerts

### Collected Metrics

| Category | Metrics |
|----------|---------|
| **System** | CPU usage, Memory, Load average, Uptime |
| **Disk** | Usage per mount, I/O rates, Inodes |
| **Network** | Bandwidth, Connections, Errors |
| **Containers** | CPU, Memory, Network per container |
| **Services** | Jellyfin status, rclone mount status |

### Default Alerts

| Alert | Severity | Condition |
|-------|----------|-----------|
| High CPU | Warning | CPU > 80% for 5min |
| High Memory | Warning | Memory > 85% for 5min |
| Disk Space Low | Warning | Disk > 85% full |
| Disk Space Critical | Critical | Disk > 95% full |
| Host Down | Critical | Target unreachable for 1min |
| Seedbox Mount Down | Critical | Mount unavailable for 2min |

---

## ⚙️ Configuration

### Environment Variables

Copy and customize the example config:

```bash
cp config/.env.example config/.env
```

Key configuration options:

| Variable | Description | Default |
|----------|-------------|---------|
| `SEEDBOX_HOST` | Seedbox SFTP hostname | - |
| `SEEDBOX_PORT` | Seedbox SFTP port | `22` |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password | `admin` |
| `VPN_SUBNET` | WireGuard VPN subnet | `10.200.200` |
| `VPN_PORT` | WireGuard UDP port | `51820` |

---

## 🔧 Maintenance

### Health Check

```bash
./install.sh --health
```

Checks:
- ✅ Service status (Jellyfin, rclone, monitoring)
- ✅ Disk usage across all mounts
- ✅ VPN connectivity
- ✅ Network interfaces

### Useful Commands

```bash
# View monitoring logs
cd monitoring && docker compose logs -f

# Restart monitoring stack
cd monitoring && docker compose restart

# Check rclone mount (Linux)
systemctl status rclone-seedbox

# Check rclone mount (macOS)
launchctl list | grep rclone

# WireGuard status
sudo wg show
```

---

## 🛡️ Security Best Practices

1. **Change default passwords** - Especially Grafana admin
2. **Keep services updated** - Regular `docker compose pull`
3. **Firewall** - Only expose necessary ports
4. **VPN** - Use VPN for remote access instead of exposing services
5. **Backups** - Regular backups of Grafana dashboards and configs

### Recommended Firewall Rules

```bash
# Allow SSH (if needed)
ufw allow 22/tcp

# Allow Jellyfin (local network only)
ufw allow from 192.168.0.0/16 to any port 8096

# Allow WireGuard
ufw allow 51820/udp

# Deny everything else from internet
ufw default deny incoming
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Jellyfin](https://jellyfin.org/) - Free Software Media System
- [rclone](https://rclone.org/) - Cloud storage Swiss army knife
- [Prometheus](https://prometheus.io/) - Monitoring system & TSDB
- [Grafana](https://grafana.com/) - Observability platform
- [WireGuard](https://www.wireguard.com/) - Fast, modern VPN
- [Loki](https://grafana.com/oss/loki/) - Log aggregation system

---

<p align="center">
  Made with ❤️ for the self-hosted community
</p>

<p align="center">
  <a href="#top">⬆️ Back to Top</a>
</p>
