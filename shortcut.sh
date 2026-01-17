#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  LEGACY SCRIPT - Use install.sh instead                       ║
# ║  This file is kept for reference only                         ║
# ╚══════════════════════════════════════════════════════════════╝

echo "⚠️  This is a legacy script. Please use ./install.sh instead."
echo "   Run: ./install.sh --help for options"
exit 1

# Original script below for reference:

set -e

echo "========================================="
echo "   📦 Jellyfin + Seedbox Media Server Setup"
echo "========================================="

# --- 1. Update system ---
echo "[1/8] Updating system..."
sudo apt update && sudo apt upgrade -y

# --- 2. Install dependencies ---
echo "[2/8] Installing dependencies (rclone, ssh, curl)..."
sudo apt install -y rclone openssh-server curl gnupg apt-transport-https software-properties-common

# --- 3. Install Jellyfin ---
# echo "[3/8] Installing Jellyfin..."
# # wget -O- https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jellyfin.gpg
# curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash
# less install-debuntu.sh
# sudo bash install-debuntu.sh
# echo "deb [signed-by=/usr/share/keyrings/jellyfin.gpg arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
# sudo apt update
# sudo apt install -y jellyfin

# --- 4. Configure rclone remote ---
echo "[4/8] Configuring rclone remote for Seedbox..."
read -p "Seedbox SFTP URL (e.g. abcd.seedbox.vip): " SEEDBOX_HOST
read -p "Seedbox SFTP Port (e.g. 63526): " SEEDBOX_PORT
read -p "Seedbox Username: " SEEDBOX_USER
read -s -p "Seedbox Password: " SEEDBOX_PASS
echo

RCLONE_CONF_DIR="$HOME/.config/rclone"
mkdir -p "$RCLONE_CONF_DIR"

RCLONE_CONF_FILE="$RCLONE_CONF_DIR/rclone.conf"

# If existing, backup
if [ -f "$RCLONE_CONF_FILE" ]; then
    cp "$RCLONE_CONF_FILE" "$RCLONE_CONF_FILE.bak.$(date +%s)"
fi

cat > "$RCLONE_CONF_FILE" <<EOF
[seedbox]
type = sftp
host = $SEEDBOX_HOST
user = $SEEDBOX_USER
port = $SEEDBOX_PORT
pass = $(rclone obscure "$SEEDBOX_PASS")
EOF

echo "✅ rclone remote 'seedbox' configured successfully."

# --- 5. Create mount point ---
echo "[5/8] Creating mount point at /mnt/seedbox..."
sudo mkdir -p /mnt/seedbox
sudo chown $USER:$USER /mnt/seedbox

# --- 6. Create systemd service for persistent mount ---
echo "[6/8] Creating systemd service for rclone mount..."
SERVICE_FILE="/etc/systemd/system/rclone-seedbox.service"

sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Rclone Mount for Seedbox
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/rclone mount seedbox: /mnt/seedbox \\
    --vfs-cache-mode writes \\
    --allow-other \\
    --no-modtime \\
    --dir-cache-time 12h \\
    --poll-interval 15s
ExecStop=/bin/fusermount -u /mnt/seedbox
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable rclone-seedbox.service
sudo systemctl start rclone-seedbox.service

echo "✅ rclone mount service enabled and started."

# --- 7. Enable SSH ---
echo "[7/8] Enabling SSH for remote access..."
sudo systemctl enable ssh
sudo systemctl start ssh
echo "✅ SSH is enabled. You can connect using:"
echo "   ssh $USER@$(hostname -I | awk '{print $1}')"

# --- 8. Start Jellyfin ---
echo "[8/8] Starting Jellyfin service..."
sudo systemctl enable jellyfin
sudo systemctl restart jellyfin

IP_ADDR=$(hostname -I | awk '{print $1}')
echo "✅ Jellyfin is running! Access it via:"
echo "   http://$IP_ADDR:8096"
echo
echo "🎉 Setup complete! Your media server is ready."
echo "   Mount point: /mnt/seedbox"
echo "   rclone remote: seedbox"
echo "   Jellyfin dashboard: http://$IP_ADDR:8096"
