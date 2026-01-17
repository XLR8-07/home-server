#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  WireGuard VPN Setup for macOS                                ║
# ╚══════════════════════════════════════════════════════════════╝

# Note: macOS is typically used as a VPN CLIENT, not server
# For server functionality, use Linux or consider Tailscale

WG_DIR="/usr/local/etc/wireguard"
VPN_SUBNET="10.200.200"
CLIENT_DIR="$SCRIPT_DIR/vpn/clients"

# Check for Apple Silicon
if [[ $(uname -m) == 'arm64' ]]; then
    WG_DIR="/opt/homebrew/etc/wireguard"
fi

# Setup WireGuard
setup_wireguard() {
    section "Setting up WireGuard VPN"
    
    echo ""
    echo -e "${YELLOW}Note: macOS is typically used as a VPN client.${NC}"
    echo -e "${YELLOW}For a VPN server, use the Linux setup or consider Tailscale.${NC}"
    echo ""
    
    # Install WireGuard
    install_wireguard
    
    echo ""
    echo -e "${BOLD}Select WireGuard mode:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 📱 Client mode (connect to existing VPN)"
    echo -e "  ${CYAN}2)${NC} 🖥️  Server mode (host VPN on this Mac)"
    echo -e "  ${CYAN}3)${NC} ❌ Cancel"
    echo ""
    read -p "$(echo -e ${YELLOW}"Enter choice [1-3]: "${NC})" choice
    
    case $choice in
        1) setup_wireguard_client ;;
        2) setup_wireguard_server ;;
        3) return 0 ;;
        *) error "Invalid option" ;;
    esac
}

# Install WireGuard
install_wireguard() {
    step "Installing WireGuard tools..."
    
    if ! command_exists wg; then
        brew install wireguard-tools
    else
        success "WireGuard tools already installed"
    fi
    
    # Install qrencode for QR codes
    if ! command_exists qrencode; then
        brew install qrencode
    fi
    
    success "WireGuard installed"
    
    info "For the best experience, also install the WireGuard app from the App Store"
}

# Setup as VPN client
setup_wireguard_client() {
    section "WireGuard Client Setup"
    
    echo ""
    echo -e "${BOLD}How would you like to configure the client?${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 📄 Import configuration file"
    echo -e "  ${CYAN}2)${NC} ✏️  Enter configuration manually"
    echo ""
    read -p "$(echo -e ${YELLOW}"Enter choice [1-2]: "${NC})" choice
    
    case $choice in
        1) import_config ;;
        2) manual_client_config ;;
        *) error "Invalid option" ;;
    esac
}

# Import existing config
import_config() {
    echo ""
    read -p "$(echo -e ${CYAN}"Enter path to .conf file: "${NC})" config_path
    
    if [ ! -f "$config_path" ]; then
        error "File not found: $config_path"
        return 1
    fi
    
    sudo mkdir -p "$WG_DIR"
    sudo cp "$config_path" "$WG_DIR/wg0.conf"
    sudo chmod 600 "$WG_DIR/wg0.conf"
    
    success "Configuration imported!"
    
    info "To connect using the CLI:"
    info "  sudo wg-quick up wg0"
    info ""
    info "To connect using the WireGuard app:"
    info "  Open WireGuard app > Import tunnel > Select the .conf file"
}

# Manual client configuration
manual_client_config() {
    mkdir -p "$CLIENT_DIR"
    
    echo ""
    echo -e "${BOLD}Enter VPN server details:${NC}"
    echo ""
    
    read -p "$(echo -e ${CYAN}"  Server public key: "${NC})" server_pubkey
    read -p "$(echo -e ${CYAN}"  Server endpoint (IP:port): "${NC})" server_endpoint
    read -p "$(echo -e ${CYAN}"  Your VPN IP (e.g. 10.200.200.2/32): "${NC})" client_ip
    
    # Generate client keys
    step "Generating client keys..."
    local client_private_key=$(wg genkey)
    local client_public_key=$(echo "$client_private_key" | wg pubkey)
    
    echo ""
    echo -e "${GREEN}Your client public key (give this to the server admin):${NC}"
    echo -e "${BOLD}$client_public_key${NC}"
    echo ""
    
    # Create config
    local config_name="wg0"
    local config_file="$CLIENT_DIR/${config_name}.conf"
    
    cat > "$config_file" <<EOF
# WireGuard Client Configuration
# Generated: $(date)

[Interface]
PrivateKey = $client_private_key
Address = $client_ip
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $server_pubkey
Endpoint = $server_endpoint
AllowedIPs = 10.200.200.0/24
PersistentKeepalive = 25
EOF
    
    # Also save to WireGuard directory
    sudo mkdir -p "$WG_DIR"
    sudo cp "$config_file" "$WG_DIR/wg0.conf"
    sudo chmod 600 "$WG_DIR/wg0.conf"
    
    success "Client configuration created!"
    info "Config saved to: $config_file"
    
    # Show QR code
    if command_exists qrencode; then
        echo ""
        echo -e "${BOLD}Scan this QR code with the WireGuard mobile app:${NC}"
        qrencode -t ansiutf8 < "$config_file"
    fi
}

# Setup as VPN server (for macOS)
setup_wireguard_server() {
    section "WireGuard Server Setup (macOS)"
    
    warn "Running a VPN server on macOS requires:"
    warn "  - Keeping the Mac always on"
    warn "  - Port forwarding on your router"
    warn "  - Disabling macOS firewall or allowing WireGuard"
    echo ""
    
    if ! confirm "Continue with server setup?"; then
        return 0
    fi
    
    # Generate server keys
    step "Generating server keys..."
    
    sudo mkdir -p "$WG_DIR"
    
    local server_private_key=$(wg genkey)
    local server_public_key=$(echo "$server_private_key" | wg pubkey)
    
    echo "$server_private_key" | sudo tee "$WG_DIR/server_private.key" > /dev/null
    echo "$server_public_key" | sudo tee "$WG_DIR/server_public.key" > /dev/null
    sudo chmod 600 "$WG_DIR/server_private.key"
    
    # Get network info
    local local_ip=$(get_local_ip)
    local public_ip=$(get_public_ip)
    local default_interface=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
    
    # Create server config
    step "Creating server configuration..."
    
    sudo tee "$WG_DIR/wg0.conf" > /dev/null <<EOF
# WireGuard Server Configuration (macOS)
# Generated: $(date)

[Interface]
PrivateKey = $server_private_key
Address = ${VPN_SUBNET}.1/24
ListenPort = 51820

# Note: macOS requires manual NAT setup via pfctl
# PostUp and PostDown scripts don't work the same as Linux

# Peers will be added below
EOF
    
    sudo chmod 600 "$WG_DIR/wg0.conf"
    
    # Enable IP forwarding
    step "Enabling IP forwarding..."
    sudo sysctl -w net.inet.ip.forwarding=1
    
    # Make permanent
    if ! grep -q "net.inet.ip.forwarding=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.inet.ip.forwarding=1" | sudo tee -a /etc/sysctl.conf > /dev/null
    fi
    
    # Setup NAT with pf
    setup_macos_nat "$default_interface"
    
    success "Server configuration created!"
    
    echo ""
    echo -e "${GREEN}Server Public Key:${NC} $server_public_key"
    echo -e "${GREEN}Server Endpoint:${NC} $public_ip:51820"
    echo -e "${GREEN}Local IP:${NC} $local_ip"
    echo ""
    
    info "To start the VPN server:"
    info "  sudo wg-quick up wg0"
    info ""
    info "To add clients, use: generate_client_config"
    
    # Generate first client
    if confirm "Generate a client configuration now?" "y"; then
        generate_macos_client_config "$server_public_key" "$public_ip"
    fi
}

# Setup NAT for macOS using pf
setup_macos_nat() {
    local interface="$1"
    
    step "Setting up NAT with pf..."
    
    # Create pf rules
    local pf_rules="/etc/pf.anchors/wireguard"
    
    sudo tee "$pf_rules" > /dev/null <<EOF
# WireGuard NAT rules
nat on $interface from ${VPN_SUBNET}.0/24 to any -> ($interface)
pass in on utun+ all
pass out on utun+ all
EOF
    
    # Add anchor to pf.conf if not present
    if ! sudo grep -q "wireguard" /etc/pf.conf; then
        sudo cp /etc/pf.conf /etc/pf.conf.backup
        echo 'nat-anchor "wireguard"' | sudo tee -a /etc/pf.conf > /dev/null
        echo 'anchor "wireguard"' | sudo tee -a /etc/pf.conf > /dev/null
        echo 'load anchor "wireguard" from "/etc/pf.anchors/wireguard"' | sudo tee -a /etc/pf.conf > /dev/null
    fi
    
    # Load pf rules
    sudo pfctl -f /etc/pf.conf 2>/dev/null || true
    sudo pfctl -e 2>/dev/null || true
    
    success "NAT configured"
}

# Generate client config for macOS server
generate_macos_client_config() {
    local server_pubkey="$1"
    local server_endpoint="$2"
    
    mkdir -p "$CLIENT_DIR"
    
    echo ""
    read -p "$(echo -e ${CYAN}"Enter client name: "${NC})" client_name
    client_name=$(echo "$client_name" | tr -cd '[:alnum:]_-')
    
    # Generate client keys
    local client_private_key=$(wg genkey)
    local client_public_key=$(echo "$client_private_key" | wg pubkey)
    
    # Find next IP
    local client_number=$(sudo grep -c "^\[Peer\]" "$WG_DIR/wg0.conf" 2>/dev/null || echo "0")
    client_number=$((client_number + 2))
    local client_ip="${VPN_SUBNET}.${client_number}/32"
    
    # Add peer to server
    sudo tee -a "$WG_DIR/wg0.conf" > /dev/null <<EOF

# Client: $client_name
[Peer]
PublicKey = $client_public_key
AllowedIPs = $client_ip
EOF
    
    # Create client config
    local config_file="$CLIENT_DIR/${client_name}.conf"
    
    cat > "$config_file" <<EOF
# WireGuard Client Configuration
# Client: $client_name
# Generated: $(date)

[Interface]
PrivateKey = $client_private_key
Address = $client_ip
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $server_pubkey
Endpoint = $server_endpoint:51820
AllowedIPs = ${VPN_SUBNET}.0/24
PersistentKeepalive = 25
EOF
    
    success "Client config created: $config_file"
    
    # Show QR code
    if command_exists qrencode; then
        echo ""
        qrencode -t ansiutf8 < "$config_file"
        qrencode -o "$CLIENT_DIR/${client_name}_qr.png" < "$config_file"
    fi
    
    # Reload WireGuard if running
    if sudo wg show wg0 &>/dev/null; then
        sudo wg syncconf wg0 <(sudo wg-quick strip wg0)
    fi
}

# Export functions
export -f setup_wireguard setup_wireguard_client setup_wireguard_server
