#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  Common Utility Functions                                     ║
# ╚══════════════════════════════════════════════════════════════╝

# Logging functions
info() {
    echo -e "${BLUE}ℹ${NC}  $*"
}

success() {
    echo -e "${GREEN}✓${NC}  $*"
}

warn() {
    echo -e "${YELLOW}⚠${NC}  $*"
}

error() {
    echo -e "${RED}✗${NC}  $*" >&2
}

section() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $*${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

step() {
    echo -e "${PURPLE}▸${NC} $*"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Get local IP address
get_local_ip() {
    case "$(uname -s)" in
        Darwin*)
            ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1"
            ;;
        Linux*)
            hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || echo "127.0.0.1"
            ;;
        *)
            echo "127.0.0.1"
            ;;
    esac
}

# Get public IP address
get_public_ip() {
    curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || echo "unknown"
}

# Confirm action
confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$(echo -e ${YELLOW}"$prompt"${NC})" response
    response=${response:-$default}
    
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Create backup of file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        info "Backed up $file to $backup"
    fi
}

# Check if running as root
is_root() {
    [ "$EUID" -eq 0 ]
}

# Require root
require_root() {
    if ! is_root; then
        error "This operation requires root privileges"
        info "Please run with sudo or as root"
        exit 1
    fi
}

# Check minimum disk space (in GB)
check_disk_space() {
    local required_gb="${1:-5}"
    local mount_point="${2:-/}"
    local available_gb
    
    case "$(uname -s)" in
        Darwin*)
            available_gb=$(df -g "$mount_point" | awk 'NR==2 {print $4}')
            ;;
        Linux*)
            available_gb=$(df -BG "$mount_point" | awk 'NR==2 {print $4}' | tr -d 'G')
            ;;
    esac
    
    if [ "$available_gb" -lt "$required_gb" ]; then
        error "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        return 1
    fi
    
    success "Disk space check passed (${available_gb}GB available)"
    return 0
}

# Wait for service to be ready
wait_for_service() {
    local url="$1"
    local timeout="${2:-60}"
    local interval="${3:-2}"
    local elapsed=0
    
    info "Waiting for service at $url..."
    
    while [ $elapsed -lt $timeout ]; do
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "^[23]"; then
            success "Service is ready!"
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    error "Timeout waiting for service at $url"
    return 1
}

# Generate random string
generate_random_string() {
    local length="${1:-32}"
    
    if command_exists openssl; then
        openssl rand -base64 "$length" | tr -dc 'a-zA-Z0-9' | head -c "$length"
    else
        cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "$length"
    fi
}

# Get system memory in MB
get_system_memory_mb() {
    case "$(uname -s)" in
        Darwin*)
            echo $(($(sysctl -n hw.memsize) / 1024 / 1024))
            ;;
        Linux*)
            awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo
            ;;
    esac
}

# Get CPU count
get_cpu_count() {
    case "$(uname -s)" in
        Darwin*)
            sysctl -n hw.ncpu
            ;;
        Linux*)
            nproc
            ;;
    esac
}

# Create directory with proper permissions
create_dir() {
    local dir="$1"
    local mode="${2:-755}"
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        chmod "$mode" "$dir"
        success "Created directory: $dir"
    fi
}

# Download file with progress
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists wget; then
        wget -q --show-progress -O "$output" "$url"
    elif command_exists curl; then
        curl -L --progress-bar -o "$output" "$url"
    else
        error "Neither wget nor curl is available"
        return 1
    fi
}

# Check if port is in use
port_in_use() {
    local port="$1"
    
    case "$(uname -s)" in
        Darwin*)
            lsof -i ":$port" &>/dev/null
            ;;
        Linux*)
            ss -tuln | grep -q ":$port "
            ;;
    esac
}

# Get available port starting from a given port
get_available_port() {
    local port="${1:-8080}"
    
    while port_in_use "$port"; do
        port=$((port + 1))
    done
    
    echo "$port"
}

# Spinner for long operations
spinner() {
    local pid=$1
    local message="${2:-Processing}"
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}%s${NC} %s" "${spin:i++%${#spin}:1}" "$message"
        sleep 0.1
    done
    
    printf "\r"
}
