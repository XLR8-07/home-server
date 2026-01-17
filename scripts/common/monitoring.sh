#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  Monitoring Stack Deployment                                  ║
# ╚══════════════════════════════════════════════════════════════╝

deploy_monitoring_stack() {
    local monitoring_dir="$SCRIPT_DIR/monitoring"
    
    step "Creating monitoring configuration..."
    
    # Create data directories
    create_dir "$monitoring_dir/data/prometheus" 777
    create_dir "$monitoring_dir/data/grafana" 777
    create_dir "$monitoring_dir/data/loki" 777
    
    step "Starting monitoring stack with Docker Compose..."
    
    cd "$monitoring_dir"
    
    # Check for docker compose v2 vs v1
    if docker compose version &>/dev/null; then
        COMPOSE_CMD="docker compose"
    elif command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
    else
        error "Docker Compose not found"
        info "Install Docker Compose: https://docs.docker.com/compose/install/"
        return 1
    fi
    
    # Pull and start containers
    $COMPOSE_CMD pull
    $COMPOSE_CMD up -d
    
    # Wait for services to be ready
    info "Waiting for services to start..."
    sleep 10
    
    # Check service health
    local ip=$(get_local_ip)
    
    if wait_for_service "http://${ip}:3000" 60; then
        success "Grafana is ready"
    else
        warn "Grafana may still be starting..."
    fi
    
    if wait_for_service "http://${ip}:9090" 30; then
        success "Prometheus is ready"
    else
        warn "Prometheus may still be starting..."
    fi
    
    success "Monitoring stack deployed successfully!"
}

stop_monitoring_stack() {
    local monitoring_dir="$SCRIPT_DIR/monitoring"
    
    cd "$monitoring_dir"
    
    if docker compose version &>/dev/null; then
        docker compose down
    else
        docker-compose down
    fi
    
    success "Monitoring stack stopped"
}

restart_monitoring_stack() {
    local monitoring_dir="$SCRIPT_DIR/monitoring"
    
    cd "$monitoring_dir"
    
    if docker compose version &>/dev/null; then
        docker compose restart
    else
        docker-compose restart
    fi
    
    success "Monitoring stack restarted"
}

show_monitoring_logs() {
    local service="${1:-}"
    local monitoring_dir="$SCRIPT_DIR/monitoring"
    
    cd "$monitoring_dir"
    
    if docker compose version &>/dev/null; then
        docker compose logs -f $service
    else
        docker-compose logs -f $service
    fi
}

# Export functions
export -f deploy_monitoring_stack stop_monitoring_stack restart_monitoring_stack show_monitoring_logs
