#!/usr/bin/env bash

#  ╦ ╦╔═╗╔╦╗╔═╗  ╔═╗╔═╗╦═╗╦  ╦╔═╗╦═╗
#  ╠═╣║ ║║║║║╣   ╚═╗║╣ ╠╦╝╚╗╔╝║╣ ╠╦╝
#  ╩ ╩╚═╝╩ ╩╚═╝  ╚═╝╚═╝╩╚═ ╚╝ ╚═╝╩╚═
#  Jellyfin + Seedbox Media Server Setup
#  Cross-platform installer for macOS & Linux

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "$SCRIPT_DIR/scripts/common/colors.sh"
source "$SCRIPT_DIR/scripts/common/utils.sh"

# Banner
print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${PURPLE}🏠 HOME SERVER${NC}                                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${DIM}Jellyfin + Seedbox Media Server with Monitoring${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}▸${NC} Cross-platform (macOS & Linux)                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}▸${NC} Metrics & Logging (Prometheus, Grafana, Loki)            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}▸${NC} VPN Support (WireGuard)                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            OS="macos"
            OS_NAME="macOS"
            ;;
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                OS="linux"
                OS_NAME="${NAME:-Linux}"
                DISTRO="${ID:-unknown}"
            else
                OS="linux"
                OS_NAME="Linux"
                DISTRO="unknown"
            fi
            ;;
        *)
            error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
    
    info "Detected OS: ${BOLD}${OS_NAME}${NC}"
    [ "$OS" = "linux" ] && info "Distribution: ${BOLD}${DISTRO}${NC}"
}

# Check prerequisites
check_prerequisites() {
    section "Checking prerequisites"
    
    local missing=()
    
    # Common requirements
    if ! command_exists curl; then
        missing+=("curl")
    fi
    
    if ! command_exists git; then
        missing+=("git")
    fi
    
    # Docker check (optional for monitoring)
    if ! command_exists docker; then
        warn "Docker not found. Monitoring stack requires Docker."
        warn "Install Docker to enable Prometheus, Grafana, and Loki."
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required tools: ${missing[*]}"
        info "Please install them before continuing."
        exit 1
    fi
    
    success "All prerequisites met!"
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BOLD}Select components to install:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 📺 Full Setup (Jellyfin + Seedbox + Monitoring)"
    echo -e "  ${CYAN}2)${NC} 🎬 Media Server Only (Jellyfin + Seedbox)"
    echo -e "  ${CYAN}3)${NC} 📊 Monitoring Stack Only (Prometheus + Grafana + Loki)"
    echo -e "  ${CYAN}4)${NC} 🔐 VPN Setup (WireGuard)"
    echo -e "  ${CYAN}5)${NC} 🔧 Configure rclone remote"
    echo -e "  ${CYAN}6)${NC} 🩺 System Health Check"
    echo -e "  ${CYAN}7)${NC} ❌ Exit"
    echo ""
    read -p "$(echo -e ${YELLOW}"Enter choice [1-7]: "${NC})" choice
    
    case $choice in
        1) full_setup ;;
        2) media_setup ;;
        3) monitoring_setup ;;
        4) vpn_setup ;;
        5) rclone_setup ;;
        6) health_check ;;
        7) exit 0 ;;
        *) error "Invalid option"; show_menu ;;
    esac
}

# Full setup
full_setup() {
    section "Starting Full Setup"
    
    # Load platform-specific scripts
    source "$SCRIPT_DIR/scripts/${OS}/setup.sh"
    
    install_dependencies
    setup_rclone
    setup_jellyfin
    setup_monitoring
    
    success "Full setup complete!"
    show_completion_info
}

# Media only setup
media_setup() {
    section "Starting Media Server Setup"
    
    source "$SCRIPT_DIR/scripts/${OS}/setup.sh"
    
    install_dependencies
    setup_rclone
    setup_jellyfin
    
    success "Media server setup complete!"
    show_media_info
}

# Monitoring setup
monitoring_setup() {
    section "Starting Monitoring Stack Setup"
    
    if ! command_exists docker; then
        error "Docker is required for the monitoring stack"
        info "Please install Docker first:"
        [ "$OS" = "macos" ] && info "  brew install --cask docker"
        [ "$OS" = "linux" ] && info "  curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    source "$SCRIPT_DIR/scripts/common/monitoring.sh"
    deploy_monitoring_stack
    
    success "Monitoring stack deployed!"
    show_monitoring_info
}

# VPN setup
vpn_setup() {
    section "Starting VPN Setup"
    
    source "$SCRIPT_DIR/scripts/${OS}/vpn.sh"
    setup_wireguard
    
    success "VPN setup complete!"
    show_vpn_info
}

# rclone setup
rclone_setup() {
    section "Configuring rclone"
    
    source "$SCRIPT_DIR/scripts/${OS}/rclone.sh"
    configure_rclone
    
    success "rclone configured!"
}

# Health check
health_check() {
    section "Running System Health Check"
    
    source "$SCRIPT_DIR/scripts/common/health.sh"
    run_health_check
}

# Show completion info
show_completion_info() {
    local ip=$(get_local_ip)
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}🎉 Setup Complete!${NC}                                          ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Jellyfin:${NC}      http://${ip}:8096                        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Grafana:${NC}       http://${ip}:3000                        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Prometheus:${NC}    http://${ip}:9090                        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${DIM}Grafana default credentials: admin / admin${NC}                ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_media_info() {
    local ip=$(get_local_ip)
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}🎬 Media Server Ready!${NC}                                      ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Jellyfin:${NC}      http://${ip}:8096                        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Mount Point:${NC}   /mnt/seedbox (Linux) | ~/seedbox (macOS)  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_monitoring_info() {
    local ip=$(get_local_ip)
    
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}📊 Monitoring Stack Active!${NC}                                 ${BLUE}║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}                                                              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}Grafana:${NC}       http://${ip}:3000                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}Prometheus:${NC}    http://${ip}:9090                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}Loki:${NC}          http://${ip}:3100                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${DIM}Default Grafana login: admin / admin${NC}                      ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                              ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_vpn_info() {
    local ip=$(get_local_ip)
    
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${BOLD}🔐 WireGuard VPN Active!${NC}                                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}                                                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}Server IP:${NC}     ${ip}                                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}VPN Port:${NC}      51820 (UDP)                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}Config Dir:${NC}    /etc/wireguard/                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${DIM}Client configs in: ./vpn/clients/${NC}                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main execution
main() {
    print_banner
    detect_os
    check_prerequisites
    
    # If argument provided, run specific setup
    case "${1:-}" in
        --full) full_setup ;;
        --media) media_setup ;;
        --monitoring) monitoring_setup ;;
        --vpn) vpn_setup ;;
        --health) health_check ;;
        *) show_menu ;;
    esac
}

main "$@"
