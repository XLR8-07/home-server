# WireGuard VPN Setup Guide

This guide covers setting up WireGuard VPN for secure remote access to your home server.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└───────────────────────────┬─────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            │         YOUR ROUTER           │
            │     Port 51820 forwarded      │
            └───────────────┬───────────────┘
                            │
            ┌───────────────┴───────────────┐
            │      HOME SERVER (VPN)        │
            │     WireGuard :51820          │
            │     10.200.200.1              │
            └───────────────┬───────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │              VPN TUNNEL               │
        │           (encrypted)                 │
        └───────────────────┬───────────────────┘
                            │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
┌───┴───┐               ┌───┴───┐               ┌───┴───┐
│ Phone │               │Laptop │               │Tablet │
│.200.2 │               │.200.3 │               │.200.4 │
└───────┘               └───────┘               └───────┘
```

## Why WireGuard?

| Feature | WireGuard | OpenVPN |
|---------|-----------|---------|
| Speed | ⚡ Very Fast | Moderate |
| Code Size | ~4,000 lines | ~100,000 lines |
| Cryptography | Modern (Curve25519) | Configurable |
| Mobile Battery | Excellent | Higher drain |
| Setup Complexity | Simple | Complex |

## Quick Setup

### On the Server

```bash
./install.sh --vpn
```

This will:
1. Install WireGuard
2. Generate server keys
3. Configure firewall rules
4. Enable IP forwarding
5. Start WireGuard service
6. Generate your first client config

### On Clients

1. Install WireGuard app:
   - **iOS**: [App Store](https://apps.apple.com/app/wireguard/id1441195209)
   - **Android**: [Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android)
   - **macOS**: [App Store](https://apps.apple.com/app/wireguard/id1451685025)
   - **Windows**: [wireguard.com](https://www.wireguard.com/install/)
   - **Linux**: `apt install wireguard`

2. Import configuration:
   - Scan QR code (mobile)
   - Or import `.conf` file

## Manual Configuration

### Server Configuration

Location: `/etc/wireguard/wg0.conf`

```ini
[Interface]
# Server's private key (keep secret!)
PrivateKey = <server_private_key>

# Server's VPN IP address
Address = 10.200.200.1/24

# UDP port to listen on
ListenPort = 51820

# Firewall rules (Linux)
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client 1: Phone
[Peer]
PublicKey = <client1_public_key>
AllowedIPs = 10.200.200.2/32

# Client 2: Laptop
[Peer]
PublicKey = <client2_public_key>
AllowedIPs = 10.200.200.3/32
```

### Client Configuration

```ini
[Interface]
# Client's private key
PrivateKey = <client_private_key>

# Client's VPN IP
Address = 10.200.200.2/32

# DNS servers to use when VPN is active
DNS = 1.1.1.1, 8.8.8.8

[Peer]
# Server's public key
PublicKey = <server_public_key>

# Server's public IP/domain and port
Endpoint = your-public-ip:51820

# What traffic to route through VPN
# Split tunnel (only home network):
AllowedIPs = 10.200.200.0/24, 192.168.1.0/24

# Full tunnel (all traffic):
# AllowedIPs = 0.0.0.0/0, ::/0

# Keep connection alive (important for mobile)
PersistentKeepalive = 25
```

## Router Configuration

### Port Forwarding

Forward UDP port 51820 to your home server:

| Setting | Value |
|---------|-------|
| Protocol | UDP |
| External Port | 51820 |
| Internal IP | Your server's local IP |
| Internal Port | 51820 |

### Dynamic DNS

If you don't have a static public IP, use a Dynamic DNS service:
- [DuckDNS](https://www.duckdns.org/) (free)
- [No-IP](https://www.noip.com/) (free tier)
- [Cloudflare](https://www.cloudflare.com/) (with DDNS client)

## Adding New Clients

### Using the script

```bash
./install.sh --vpn
# Select option to generate client config
```

### Manually

1. Generate keys on client:
   ```bash
   wg genkey | tee privatekey | wg pubkey > publickey
   ```

2. Add peer to server config:
   ```ini
   [Peer]
   PublicKey = <new_client_public_key>
   AllowedIPs = 10.200.200.X/32
   ```

3. Reload server:
   ```bash
   sudo wg syncconf wg0 <(sudo wg-quick strip wg0)
   ```

4. Create client config with server's public key

## Split Tunnel vs Full Tunnel

### Split Tunnel (Recommended)

Only routes traffic destined for your home network through the VPN:

```ini
AllowedIPs = 10.200.200.0/24, 192.168.1.0/24
```

**Pros:**
- Faster internet (other traffic bypasses VPN)
- Less battery usage
- Can access local network and home network simultaneously

**Cons:**
- Other internet traffic not encrypted by VPN

### Full Tunnel

Routes ALL traffic through your home server:

```ini
AllowedIPs = 0.0.0.0/0, ::/0
```

**Pros:**
- All traffic encrypted
- Appears as if browsing from home
- Bypass geo-restrictions

**Cons:**
- Slower (all traffic goes through home connection)
- Higher battery usage
- Higher bandwidth on home connection

## Security Best Practices

1. **Protect private keys** - Never share or commit them to git
2. **Use strong keys** - Always use `wg genkey`, never create manually
3. **Limit peer access** - Use specific `/32` IPs for AllowedIPs on server
4. **Keep updated** - Regularly update WireGuard
5. **Monitor connections** - Check `sudo wg show` periodically
6. **Firewall** - Only allow port 51820/udp from internet

## Troubleshooting

### Can't connect

1. Check server is running:
   ```bash
   sudo wg show
   ```

2. Verify port forwarding:
   ```bash
   # From outside network
   nc -zvu your-public-ip 51820
   ```

3. Check firewall allows traffic:
   ```bash
   sudo iptables -L -n | grep 51820
   ```

### Connected but no traffic

1. Check IP forwarding:
   ```bash
   sysctl net.ipv4.ip_forward
   # Should return 1
   ```

2. Verify NAT rules:
   ```bash
   sudo iptables -t nat -L -n
   ```

3. Check AllowedIPs on both ends

### Slow speeds

1. Use split tunnel instead of full tunnel
2. Check home internet upload speed (limits VPN throughput)
3. Try different MTU:
   ```ini
   [Interface]
   MTU = 1420
   ```

### Handshake but no data

- Usually a routing or firewall issue
- Check that server can reach the internet
- Verify PostUp/PostDown rules are correct

## Mobile Tips

### iOS

- Enable "On-Demand" activation for automatic VPN on untrusted networks
- Settings: WireGuard → Your tunnel → Edit → On-Demand Activation

### Android

- Enable "Always-on VPN" in system settings
- Settings → Network → VPN → ⚙️ next to WireGuard → Always-on VPN

### Battery Optimization

- PersistentKeepalive of 25 seconds works well for most cases
- Lower values = faster reconnection but more battery
- Higher values = better battery but slower reconnection
