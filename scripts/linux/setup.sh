#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  Linux Setup Script                                           ║
# ║  Supports: Ubuntu, Debian, Fedora, CentOS, Arch               ║
# ╚══════════════════════════════════════════════════════════════╝

# Detect package manager
detect_package_manager() {
    if command_exists apt; then
        PKG_MANAGER="apt"
        PKG_UPDATE="sudo apt update"
        PKG_INSTALL="sudo apt install -y"
    elif command_exists dnf; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="sudo dnf check-update || true"
        PKG_INSTALL="sudo dnf install -y"
    elif command_exists yum; then
        PKG_MANAGER="yum"
        PKG_UPDATE="sudo yum check-update || true"
        PKG_INSTALL="sudo yum install -y"
    elif command_exists pacman; then
        PKG_MANAGER="pacman"
        PKG_UPDATE="sudo pacman -Sy"
        PKG_INSTALL="sudo pacman -S --noconfirm"
    else
        error "No supported package manager found"
        exit 1
    fi
    
    info "Detected package manager: $PKG_MANAGER"
}

# Install dependencies
install_dependencies() {
    section "Installing Dependencies"
    detect_package_manager
    
    step "Updating package lists..."
    eval "$PKG_UPDATE"
    
    step "Installing required packages..."
    
    case "$PKG_MANAGER" in
        apt)
            $PKG_INSTALL curl wget gnupg apt-transport-https \
                software-properties-common openssh-server \
                fuse3 ca-certificates lsb-release
            ;;
        dnf|yum)
            $PKG_INSTALL curl wget gnupg openssh-server \
                fuse3 ca-certificates
            ;;
        pacman)
            $PKG_INSTALL curl wget gnupg openssh fuse3 ca-certificates
            ;;
    esac
    
    # Install rclone if not present
    if ! command_exists rclone; then
        step "Installing rclone..."
        curl https://rclone.org/install.sh | sudo bash
    else
        success "rclone already installed"
    fi
    
    # Install Docker if not present
    if ! command_exists docker; then
        if confirm "Docker is not installed. Install Docker for monitoring stack?"; then
            install_docker
        fi
    else
        success "Docker already installed"
    fi
    
    success "Dependencies installed successfully!"
}

# Install Docker
install_docker() {
    step "Installing Docker..."
    
    case "$PKG_MANAGER" in
        apt)
            # Add Docker's official GPG key
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            
            # Add repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        dnf)
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        pacman)
            sudo pacman -S --noconfirm docker docker-compose
            ;;
    esac
    
    # Start Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    success "Docker installed! You may need to log out and back in for group changes to take effect."
}

# Setup Jellyfin
setup_jellyfin() {
    section "Setting up Jellyfin"
    
    if systemctl is-active --quiet jellyfin 2>/dev/null; then
        success "Jellyfin is already running"
        return 0
    fi
    
    step "Installing Jellyfin..."
    
    case "$PKG_MANAGER" in
        apt)
            # Add Jellyfin repository
            curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | \
                sudo gpg --dearmor -o /usr/share/keyrings/jellyfin.gpg
            
            echo "deb [signed-by=/usr/share/keyrings/jellyfin.gpg arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu $(lsb_release -cs) main" | \
                sudo tee /etc/apt/sources.list.d/jellyfin.list
            
            sudo apt update
            sudo apt install -y jellyfin
            ;;
        dnf|yum)
            # Jellyfin RPM repository
            sudo tee /etc/yum.repos.d/jellyfin.repo <<EOF
[jellyfin]
name=Jellyfin
baseurl=https://repo.jellyfin.org/releases/server/fedora/stable/\$basearch/
gpgcheck=1
gpgkey=https://repo.jellyfin.org/releases/server/fedora/stable/\$basearch/repodata/repomd.xml.key
enabled=1
EOF
            $PKG_INSTALL jellyfin
            ;;
        pacman)
            # Jellyfin from AUR or official repos
            $PKG_INSTALL jellyfin-server jellyfin-web
            ;;
    esac
    
    # Enable and start Jellyfin
    sudo systemctl enable jellyfin
    sudo systemctl start jellyfin
    
    # Configure Jellyfin to use rclone mount
    local mount_point="/mnt/seedbox"
    
    if [ -d "$mount_point" ]; then
        info "Add $mount_point as a media library in Jellyfin web interface"
    fi
    
    success "Jellyfin installed and started!"
    info "Access Jellyfin at: http://$(get_local_ip):8096"
}

# Setup monitoring
setup_monitoring() {
    section "Setting up Monitoring Stack"
    source "$SCRIPT_DIR/scripts/common/monitoring.sh"
    deploy_monitoring_stack
}

# Disable system sleep
disable_sleep() {
    section "Disabling System Sleep"
    
    sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
    
    success "System sleep disabled"
}

# Enable SSH
enable_ssh() {
    section "Enabling SSH"
    
    sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null
    sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null
    
    local ip=$(get_local_ip)
    success "SSH enabled!"
    info "Connect with: ssh $USER@$ip"
}

# Export functions
export -f install_dependencies setup_jellyfin setup_monitoring disable_sleep enable_ssh
