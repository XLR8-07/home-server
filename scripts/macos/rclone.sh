#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  rclone Configuration for macOS                               ║
# ╚══════════════════════════════════════════════════════════════╝

RCLONE_CONF_DIR="$HOME/.config/rclone"
RCLONE_CONF_FILE="$RCLONE_CONF_DIR/rclone.conf"
MOUNT_POINT="$HOME/seedbox"
PLIST_NAME="com.rclone.seedbox"
PLIST_FILE="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

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

# Setup rclone mount for macOS
setup_rclone_mount() {
    section "Setting up rclone mount"
    
    # Check for macFUSE
    if ! [ -d "/Library/Filesystems/macfuse.fs" ]; then
        error "macFUSE is required for rclone mount on macOS"
        info "Install from: https://osxfuse.github.io/"
        info "Or: brew install --cask macfuse"
        return 1
    fi
    
    # Create mount point
    step "Creating mount point at $MOUNT_POINT..."
    mkdir -p "$MOUNT_POINT"
    
    # Create LaunchAgent for persistent mount
    create_launch_agent
    
    success "rclone mount configured!"
}

# Create LaunchAgent for persistent mount
create_launch_agent() {
    step "Creating LaunchAgent for automatic mount..."
    
    mkdir -p "$HOME/Library/LaunchAgents"
    
    # Get rclone path
    local rclone_path=$(which rclone)
    
    cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>${rclone_path}</string>
        <string>mount</string>
        <string>seedbox:</string>
        <string>${MOUNT_POINT}</string>
        <string>--config</string>
        <string>${RCLONE_CONF_FILE}</string>
        <string>--vfs-cache-mode</string>
        <string>writes</string>
        <string>--vfs-cache-max-size</string>
        <string>10G</string>
        <string>--vfs-read-chunk-size</string>
        <string>128M</string>
        <string>--vfs-read-chunk-size-limit</string>
        <string>1G</string>
        <string>--buffer-size</string>
        <string>256M</string>
        <string>--no-modtime</string>
        <string>--dir-cache-time</string>
        <string>12h</string>
        <string>--poll-interval</string>
        <string>15s</string>
        <string>--volname</string>
        <string>Seedbox</string>
        <string>--log-level</string>
        <string>INFO</string>
        <string>--log-file</string>
        <string>${HOME}/Library/Logs/rclone-seedbox.log</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>NetworkState</key>
        <true/>
    </dict>
    
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/rclone-seedbox-stdout.log</string>
    
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/rclone-seedbox-stderr.log</string>
    
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
EOF
    
    # Load the agent
    if launchctl list | grep -q "$PLIST_NAME"; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
    fi
    
    if confirm "Start rclone mount now?" "y"; then
        launchctl load "$PLIST_FILE"
        
        sleep 5
        
        if mount | grep -q "$MOUNT_POINT"; then
            success "Seedbox mounted successfully!"
            info "Mount point: $MOUNT_POINT"
            
            # Open in Finder
            if confirm "Open mount in Finder?"; then
                open "$MOUNT_POINT"
            fi
        else
            error "Mount may have failed. Check logs:"
            info "  cat ~/Library/Logs/rclone-seedbox.log"
        fi
    else
        info "Start the mount later with: launchctl load $PLIST_FILE"
    fi
}

# Manual mount (for testing)
manual_mount() {
    info "Mounting seedbox manually..."
    
    # Unmount if already mounted
    umount "$MOUNT_POINT" 2>/dev/null || true
    
    rclone mount seedbox: "$MOUNT_POINT" \
        --vfs-cache-mode writes \
        --no-modtime \
        --dir-cache-time 12h \
        --volname "Seedbox" &
    
    sleep 3
    
    if mount | grep -q "$MOUNT_POINT"; then
        success "Mount successful!"
        open "$MOUNT_POINT"
    else
        error "Mount failed"
    fi
}

# Unmount
unmount_seedbox() {
    info "Unmounting seedbox..."
    
    umount "$MOUNT_POINT" 2>/dev/null || \
        diskutil unmount force "$MOUNT_POINT" 2>/dev/null || \
        true
    
    success "Unmounted"
}

# Stop LaunchAgent
stop_mount() {
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    unmount_seedbox
    success "Mount service stopped"
}

# Export functions
export -f configure_rclone setup_rclone_mount create_launch_agent manual_mount unmount_seedbox stop_mount
