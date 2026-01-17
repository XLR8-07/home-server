#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  rclone Configuration for Linux                               ║
# ╚══════════════════════════════════════════════════════════════╝

RCLONE_CONF_DIR="$HOME/.config/rclone"
RCLONE_CONF_FILE="$RCLONE_CONF_DIR/rclone.conf"
MOUNT_POINT="/mnt/seedbox"
SERVICE_NAME="rclone-seedbox"

# Configure rclone
configure_rclone() {
    section "Configuring rclone"
    
    mkdir -p "$RCLONE_CONF_DIR"
    
    # Backup existing config
    backup_file "$RCLONE_CONF_FILE"
    
    echo ""
    echo -e "${BOLD}Enter your Seedbox SFTP details:${NC}"
    echo ""
    
    read -p "$(echo -e ${CYAN}"  Seedbox SFTP Host (e.g. abcd.seedbox.vip): "${NC})" SEEDBOX_HOST
    read -p "$(echo -e ${CYAN}"  Seedbox SFTP Port (e.g. 22 or 63526): "${NC})" SEEDBOX_PORT
    read -p "$(echo -e ${CYAN}"  Seedbox Username: "${NC})" SEEDBOX_USER
    read -s -p "$(echo -e ${CYAN}"  Seedbox Password: "${NC})" SEEDBOX_PASS
    echo ""
    
    # Validate input
    if [ -z "$SEEDBOX_HOST" ] || [ -z "$SEEDBOX_PORT" ] || [ -z "$SEEDBOX_USER" ] || [ -z "$SEEDBOX_PASS" ]; then
        error "All fields are required"
        return 1
    fi
    
    step "Creating rclone configuration..."
    
    # Obscure password
    local obscured_pass=$(rclone obscure "$SEEDBOX_PASS")
    
    cat > "$RCLONE_CONF_FILE" <<EOF
[seedbox]
type = sftp
host = $SEEDBOX_HOST
user = $SEEDBOX_USER
port = $SEEDBOX_PORT
pass = $obscured_pass
shell_type = unix
md5sum_command = md5sum
sha1sum_command = sha1sum
EOF
    
    chmod 600 "$RCLONE_CONF_FILE"
    
    success "rclone remote 'seedbox' configured!"
    
    # Test connection
    step "Testing connection..."
    if rclone lsd seedbox: --max-depth 1 &>/dev/null; then
        success "Connection successful!"
    else
        warn "Connection test failed. Please verify your credentials."
    fi
    
    # Setup mount
    setup_rclone_mount
}

# Setup rclone mount
setup_rclone_mount() {
    section "Setting up rclone mount"
    
    # Create mount point
    step "Creating mount point at $MOUNT_POINT..."
    sudo mkdir -p "$MOUNT_POINT"
    sudo chown $USER:$USER "$MOUNT_POINT"
    
    # Enable FUSE for user mounts
    if [ -f /etc/fuse.conf ]; then
        if ! grep -q "^user_allow_other" /etc/fuse.conf; then
            echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
        fi
    fi
    
    # Create systemd service
    create_rclone_service
    
    success "rclone mount configured!"
}

# Create systemd service
create_rclone_service() {
    step "Creating systemd service..."
    
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=Rclone SFTP Mount for Seedbox
Documentation=https://rclone.org/commands/rclone_mount/
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=$USER
Group=$(id -gn)
Environment="PATH=/usr/local/bin:/usr/bin:/bin"

ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/rclone mount seedbox: $MOUNT_POINT \\
    --config=$RCLONE_CONF_FILE \\
    --vfs-cache-mode writes \\
    --vfs-cache-max-size 10G \\
    --vfs-read-chunk-size 128M \\
    --vfs-read-chunk-size-limit 1G \\
    --buffer-size 256M \\
    --allow-other \\
    --no-modtime \\
    --dir-cache-time 12h \\
    --poll-interval 15s \\
    --attr-timeout 1s \\
    --log-level INFO \\
    --log-file=/var/log/rclone-seedbox.log

ExecStop=/bin/fusermount -uz $MOUNT_POINT

Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
    
    # Create log file
    sudo touch /var/log/rclone-seedbox.log
    sudo chown $USER:$USER /var/log/rclone-seedbox.log
    
    # Reload and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    
    if confirm "Start rclone mount service now?" "y"; then
        sudo systemctl start "$SERVICE_NAME"
        
        sleep 3
        
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            success "rclone mount service started!"
            info "Mount point: $MOUNT_POINT"
            
            # Show mount contents
            if [ -d "$MOUNT_POINT" ]; then
                info "Contents of mount point:"
                ls -la "$MOUNT_POINT" 2>/dev/null | head -10
            fi
        else
            error "Service failed to start. Check logs with: journalctl -u $SERVICE_NAME"
        fi
    else
        info "Start the service later with: sudo systemctl start $SERVICE_NAME"
    fi
}

# Manual mount (for testing)
manual_mount() {
    info "Mounting seedbox manually..."
    
    rclone mount seedbox: "$MOUNT_POINT" \
        --vfs-cache-mode writes \
        --allow-other \
        --no-modtime \
        --dir-cache-time 12h &
    
    sleep 2
    
    if mount | grep -q "$MOUNT_POINT"; then
        success "Mount successful!"
    else
        error "Mount failed"
    fi
}

# Unmount
unmount_seedbox() {
    info "Unmounting seedbox..."
    
    fusermount -uz "$MOUNT_POINT" 2>/dev/null || \
        sudo umount -l "$MOUNT_POINT" 2>/dev/null || \
        sudo umount -f "$MOUNT_POINT" 2>/dev/null
    
    success "Unmounted"
}

# Export functions
export -f configure_rclone setup_rclone_mount create_rclone_service manual_mount unmount_seedbox
