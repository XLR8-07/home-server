#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  macOS Setup Script                                           ║
# ╚══════════════════════════════════════════════════════════════╝

# Install Homebrew if not present
install_homebrew() {
    if ! command_exists brew; then
        step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ $(uname -m) == 'arm64' ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        success "Homebrew already installed"
    fi
}

# Install dependencies
install_dependencies() {
    section "Installing Dependencies"
    
    install_homebrew
    
    step "Updating Homebrew..."
    brew update
    
    step "Installing required packages..."
    
    # Core utilities
    brew install curl wget gnupg
    
    # rclone
    if ! command_exists rclone; then
        brew install rclone
    else
        success "rclone already installed"
    fi
    
    # macFUSE for rclone mount
    if ! [ -d "/Library/Filesystems/macfuse.fs" ]; then
        warn "macFUSE is required for rclone mount"
        info "Install from: https://osxfuse.github.io/"
        
        if confirm "Install macFUSE via Homebrew Cask?"; then
            brew install --cask macfuse
            warn "You may need to allow the kernel extension in System Preferences > Security & Privacy"
            warn "A restart may be required after allowing the extension"
        fi
    else
        success "macFUSE already installed"
    fi
    
    # Docker Desktop
    if ! command_exists docker; then
        if confirm "Docker is not installed. Install Docker Desktop for monitoring stack?"; then
            brew install --cask docker
            info "Please launch Docker Desktop from Applications to complete setup"
        fi
    else
        success "Docker already installed"
    fi
    
    success "Dependencies installed successfully!"
}

# Setup Jellyfin
setup_jellyfin() {
    section "Setting up Jellyfin"
    
    # Check if already running
    if pgrep -x "Jellyfin" > /dev/null; then
        success "Jellyfin is already running"
        return 0
    fi
    
    step "Installing Jellyfin..."
    
    # Install Jellyfin via Homebrew
    brew install --cask jellyfin
    
    success "Jellyfin installed!"
    
    # Launch Jellyfin
    if confirm "Launch Jellyfin now?" "y"; then
        open -a "Jellyfin"
        
        # Wait a moment for it to start
        sleep 3
        
        local ip=$(get_local_ip)
        info "Access Jellyfin at: http://${ip}:8096"
        info "Or: http://localhost:8096"
    fi
    
    # Configure Jellyfin to start at login
    if confirm "Start Jellyfin automatically at login?"; then
        osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Jellyfin.app", hidden:false}'
        success "Jellyfin will start automatically at login"
    fi
}

# Setup monitoring
setup_monitoring() {
    section "Setting up Monitoring Stack"
    
    # Check if Docker is running
    if ! docker info &>/dev/null; then
        error "Docker is not running"
        info "Please start Docker Desktop and try again"
        return 1
    fi
    
    source "$SCRIPT_DIR/scripts/common/monitoring.sh"
    deploy_monitoring_stack
}

# Disable system sleep (for server use)
disable_sleep() {
    section "Configuring Power Settings"
    
    step "Disabling automatic sleep..."
    
    # Prevent sleep when display is off
    sudo pmset -a sleep 0
    sudo pmset -a disksleep 0
    sudo pmset -a hibernatemode 0
    
    # Prevent display sleep (optional)
    if confirm "Also prevent display from sleeping?"; then
        sudo pmset -a displaysleep 0
    fi
    
    # Enable wake on network access
    sudo pmset -a womp 1
    
    success "Power settings configured for server use"
    
    # Show current settings
    info "Current power settings:"
    pmset -g
}

# Enable remote access
enable_remote_access() {
    section "Enabling Remote Access"
    
    # Enable SSH (Remote Login)
    step "Enabling SSH (Remote Login)..."
    sudo systemsetup -setremotelogin on
    
    local ip=$(get_local_ip)
    success "SSH enabled!"
    info "Connect with: ssh $USER@$ip"
    
    # Enable Screen Sharing (optional)
    if confirm "Enable Screen Sharing (VNC)?"; then
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
        success "Screen Sharing enabled"
        info "Connect with VNC to: vnc://$ip"
    fi
}

# Export functions
export -f install_dependencies setup_jellyfin setup_monitoring disable_sleep enable_remote_access
