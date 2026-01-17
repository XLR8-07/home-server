#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  System Health Check                                          ║
# ╚══════════════════════════════════════════════════════════════╝

run_health_check() {
    local all_good=true
    
    echo ""
    echo -e "${BOLD}System Health Report${NC}"
    echo -e "${DIM}Generated: $(date)${NC}"
    echo ""
    
    # System Info
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}System Information${NC}                                         ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${NC}"
    
    local hostname=$(hostname)
    local os_info=$(uname -srm)
    local cpu_count=$(get_cpu_count)
    local mem_mb=$(get_system_memory_mb)
    local mem_gb=$((mem_mb / 1024))
    
    printf "${CYAN}│${NC}  %-15s %-43s ${CYAN}│${NC}\n" "Hostname:" "$hostname"
    printf "${CYAN}│${NC}  %-15s %-43s ${CYAN}│${NC}\n" "OS:" "$os_info"
    printf "${CYAN}│${NC}  %-15s %-43s ${CYAN}│${NC}\n" "CPU Cores:" "$cpu_count"
    printf "${CYAN}│${NC}  %-15s %-43s ${CYAN}│${NC}\n" "Memory:" "${mem_gb}GB"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Service Status
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}Service Status${NC}                                             ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${NC}"
    
    # Check Jellyfin
    check_service_health "Jellyfin" "jellyfin" "8096" || all_good=false
    
    # Check rclone mount
    check_mount_health || all_good=false
    
    # Check Docker services
    if command_exists docker; then
        check_docker_health "Prometheus" "prometheus" "9090" || all_good=false
        check_docker_health "Grafana" "grafana" "3000" || all_good=false
        check_docker_health "Loki" "loki" "3100" || all_good=false
    fi
    
    # Check WireGuard
    check_vpn_health || all_good=false
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Disk Usage
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}Disk Usage${NC}                                                 ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${NC}"
    
    check_disk_usage
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Network
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}Network${NC}                                                    ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${NC}"
    
    local local_ip=$(get_local_ip)
    local public_ip=$(get_public_ip)
    
    printf "${CYAN}│${NC}  %-15s %-43s ${CYAN}│${NC}\n" "Local IP:" "$local_ip"
    printf "${CYAN}│${NC}  %-15s %-43s ${CYAN}│${NC}\n" "Public IP:" "$public_ip"
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Summary
    if $all_good; then
        echo -e "${GREEN}✓ All systems operational${NC}"
    else
        echo -e "${YELLOW}⚠ Some services need attention${NC}"
    fi
}

check_service_health() {
    local name="$1"
    local service="$2"
    local port="$3"
    
    local status="${RED}●${NC} Stopped"
    local healthy=false
    
    case "$(uname -s)" in
        Darwin*)
            if launchctl list 2>/dev/null | grep -q "$service"; then
                status="${GREEN}●${NC} Running"
                healthy=true
            fi
            ;;
        Linux*)
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                status="${GREEN}●${NC} Running"
                healthy=true
            fi
            ;;
    esac
    
    # Also check port
    if [ -n "$port" ] && port_in_use "$port"; then
        status="${GREEN}●${NC} Running"
        healthy=true
    fi
    
    printf "${CYAN}│${NC}  %-15s %-43b ${CYAN}│${NC}\n" "$name:" "$status"
    
    $healthy
}

check_docker_health() {
    local name="$1"
    local container="$2"
    local port="$3"
    
    local status="${DIM}●${NC} Not installed"
    local healthy=false
    
    if command_exists docker; then
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "$container"; then
            status="${GREEN}●${NC} Running"
            healthy=true
        elif docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$container"; then
            status="${YELLOW}●${NC} Stopped"
        else
            status="${DIM}●${NC} Not deployed"
        fi
    fi
    
    printf "${CYAN}│${NC}  %-15s %-43b ${CYAN}│${NC}\n" "$name:" "$status"
    
    $healthy
}

check_mount_health() {
    local mount_point
    local status="${RED}●${NC} Not mounted"
    local healthy=false
    
    case "$(uname -s)" in
        Darwin*)
            mount_point="$HOME/seedbox"
            ;;
        Linux*)
            mount_point="/mnt/seedbox"
            ;;
    esac
    
    if mount | grep -q "$mount_point"; then
        status="${GREEN}●${NC} Mounted"
        healthy=true
    elif [ -d "$mount_point" ]; then
        status="${YELLOW}●${NC} Dir exists (unmounted)"
    fi
    
    printf "${CYAN}│${NC}  %-15s %-43b ${CYAN}│${NC}\n" "Seedbox Mount:" "$status"
    
    $healthy
}

check_vpn_health() {
    local status="${DIM}●${NC} Not configured"
    local healthy=false
    
    case "$(uname -s)" in
        Darwin*)
            if command_exists wg && wg show 2>/dev/null | grep -q "interface"; then
                status="${GREEN}●${NC} Connected"
                healthy=true
            elif [ -f "/usr/local/etc/wireguard/wg0.conf" ] || [ -f "/opt/homebrew/etc/wireguard/wg0.conf" ]; then
                status="${YELLOW}●${NC} Configured (inactive)"
            fi
            ;;
        Linux*)
            if systemctl is-active --quiet wg-quick@wg0 2>/dev/null; then
                status="${GREEN}●${NC} Connected"
                healthy=true
            elif [ -f "/etc/wireguard/wg0.conf" ]; then
                status="${YELLOW}●${NC} Configured (inactive)"
            fi
            ;;
    esac
    
    printf "${CYAN}│${NC}  %-15s %-43b ${CYAN}│${NC}\n" "WireGuard VPN:" "$status"
    
    return 0  # VPN is optional, don't fail health check
}

check_disk_usage() {
    local warn_threshold=80
    local crit_threshold=90
    
    while IFS= read -r line; do
        local mount=$(echo "$line" | awk '{print $NF}')
        local usage=$(echo "$line" | awk '{print $(NF-1)}' | tr -d '%')
        local size=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        
        local color="${GREEN}"
        local indicator="●"
        
        if [ "$usage" -ge "$crit_threshold" ]; then
            color="${RED}"
            indicator="●"
        elif [ "$usage" -ge "$warn_threshold" ]; then
            color="${YELLOW}"
            indicator="●"
        fi
        
        printf "${CYAN}│${NC}  ${color}${indicator}${NC} %-12s %6s / %-6s (%s%%)             ${CYAN}│${NC}\n" \
            "$mount" "$used" "$size" "$usage"
    done < <(df -h 2>/dev/null | grep -E '^/dev/' | head -5)
}

# Export functions
export -f run_health_check check_service_health check_docker_health check_mount_health check_vpn_health check_disk_usage
