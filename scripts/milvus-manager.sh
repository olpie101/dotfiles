#!/usr/bin/env bash

set -e

# Milvus Configuration (same as claude-code-launcher.sh)
MILVUS_COMPOSE_FILE="$HOME/.dotfiles/compose/milvus.yml"
MILVUS_VOLUME_DIRECTORY="$HOME/.config/milvus"
MILVUS_PROJECT_NAME="milvus"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Milvus Service Manager"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  start     Start Milvus services"
    echo "  stop      Stop Milvus services"
    echo "  restart   Restart Milvus services"
    echo "  status    Show status of Milvus services"
    echo "  logs      Show logs from Milvus services"
    echo "            Optional: specify service name as second argument"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 stop"
    echo "  $0 status"
    echo "  $0 logs"
    echo "  $0 logs milvus-standalone"
    echo ""
}

# Function to check if services are running
check_services() {
    local etcd_running=$(podman ps --filter "name=milvus-etcd" --format "{{.Names}}" | grep -c "milvus-etcd" || echo "0")
    local minio_running=$(podman ps --filter "name=milvus-minio" --format "{{.Names}}" | grep -c "milvus-minio" || echo "0")
    local standalone_running=$(podman ps --filter "name=milvus-standalone" --format "{{.Names}}" | grep -c "milvus-standalone" || echo "0")
    
    echo "$etcd_running:$minio_running:$standalone_running"
}

# Start command
start_milvus() {
    print_info "Starting Milvus services..."
    
    # Check if services are already running
    local status=$(check_services)
    IFS=':' read -r etcd_running minio_running standalone_running <<< "$status"
    
    if [ "$etcd_running" -eq 1 ] && [ "$minio_running" -eq 1 ] && [ "$standalone_running" -eq 1 ]; then
        print_warning "All Milvus services are already running"
        return 0
    fi
    
    # Create volume directory if it doesn't exist
    if [ ! -d "$MILVUS_VOLUME_DIRECTORY" ]; then
        print_info "Creating Milvus volume directory: $MILVUS_VOLUME_DIRECTORY"
        mkdir -p "$MILVUS_VOLUME_DIRECTORY"
        if [ $? -eq 0 ]; then
            print_status "Volume directory created successfully"
        else
            print_error "Failed to create volume directory"
            exit 1
        fi
    fi
    
    # Start services
    print_info "Starting Milvus compose services..."
    DOCKER_VOLUME_DIRECTORY="$MILVUS_VOLUME_DIRECTORY" podman-compose \
        -f "$MILVUS_COMPOSE_FILE" \
        -p "$MILVUS_PROJECT_NAME" \
        up -d
    
    if [ $? -eq 0 ]; then
        print_status "Milvus services started successfully"
        print_info "Waiting for services to initialize..."
        sleep 3
        show_status
    else
        print_error "Failed to start Milvus services"
        exit 1
    fi
}

# Stop command
stop_milvus() {
    print_info "Stopping Milvus services..."
    
    # Check if services are running
    local status=$(check_services)
    IFS=':' read -r etcd_running minio_running standalone_running <<< "$status"
    
    if [ "$etcd_running" -eq 0 ] && [ "$minio_running" -eq 0 ] && [ "$standalone_running" -eq 0 ]; then
        print_warning "Milvus services are not running"
        return 0
    fi
    
    # Stop services
    DOCKER_VOLUME_DIRECTORY="$MILVUS_VOLUME_DIRECTORY" podman-compose \
        -f "$MILVUS_COMPOSE_FILE" \
        -p "$MILVUS_PROJECT_NAME" \
        down
    
    if [ $? -eq 0 ]; then
        print_status "Milvus services stopped successfully"
    else
        print_error "Failed to stop Milvus services"
        exit 1
    fi
}

# Restart command
restart_milvus() {
    print_info "Restarting Milvus services..."
    stop_milvus
    sleep 2
    start_milvus
}

# Status command
show_status() {
    print_info "Milvus Services Status:"
    echo ""
    
    # Check each service
    local etcd_status=$(podman ps -a --filter "name=milvus-etcd" --format "table {{.Names}}\t{{.Status}}" | grep "milvus-etcd" || echo "milvus-etcd\tNot Found")
    local minio_status=$(podman ps -a --filter "name=milvus-minio" --format "table {{.Names}}\t{{.Status}}" | grep "milvus-minio" || echo "milvus-minio\tNot Found")
    local standalone_status=$(podman ps -a --filter "name=milvus-standalone" --format "table {{.Names}}\t{{.Status}}" | grep "milvus-standalone" || echo "milvus-standalone\tNot Found")
    
    # Parse and display status
    echo "Service              Status"
    echo "-------------------  ------------------------"
    
    # etcd
    if echo "$etcd_status" | grep -q "Up"; then
        echo -e "milvus-etcd          ${GREEN}Running${NC} ($(echo "$etcd_status" | cut -d$'\t' -f2))"
    elif echo "$etcd_status" | grep -q "Exited"; then
        echo -e "milvus-etcd          ${RED}Stopped${NC} ($(echo "$etcd_status" | cut -d$'\t' -f2))"
    else
        echo -e "milvus-etcd          ${RED}Not Found${NC}"
    fi
    
    # minio
    if echo "$minio_status" | grep -q "Up"; then
        echo -e "milvus-minio         ${GREEN}Running${NC} ($(echo "$minio_status" | cut -d$'\t' -f2))"
    elif echo "$minio_status" | grep -q "Exited"; then
        echo -e "milvus-minio         ${RED}Stopped${NC} ($(echo "$minio_status" | cut -d$'\t' -f2))"
    else
        echo -e "milvus-minio         ${RED}Not Found${NC}"
    fi
    
    # standalone
    if echo "$standalone_status" | grep -q "Up"; then
        echo -e "milvus-standalone    ${GREEN}Running${NC} ($(echo "$standalone_status" | cut -d$'\t' -f2))"
    elif echo "$standalone_status" | grep -q "Exited"; then
        echo -e "milvus-standalone    ${RED}Stopped${NC} ($(echo "$standalone_status" | cut -d$'\t' -f2))"
    else
        echo -e "milvus-standalone    ${RED}Not Found${NC}"
    fi
    
    echo ""
    
    # Show ports if running
    local status=$(check_services)
    IFS=':' read -r etcd_running minio_running standalone_running <<< "$status"
    
    if [ "$standalone_running" -eq 1 ]; then
        print_info "Milvus WebUI available at: http://localhost:9091/webui/"
        print_info "Milvus API available at: localhost:19530"
    fi
    
    if [ "$minio_running" -eq 1 ]; then
        print_info "MinIO Console available at: http://localhost:9001"
    fi
}

# Logs command
show_logs() {
    local service_name=$1
    
    if [ -n "$service_name" ]; then
        print_info "Showing logs for $service_name..."
        podman logs --tail 50 -f "$service_name"
    else
        print_info "Showing logs for all Milvus services..."
        print_info "Press Ctrl+C to stop following logs"
        echo ""
        DOCKER_VOLUME_DIRECTORY="$MILVUS_VOLUME_DIRECTORY" podman-compose \
            -f "$MILVUS_COMPOSE_FILE" \
            -p "$MILVUS_PROJECT_NAME" \
            logs --tail 50 -f
    fi
}

# Main script logic
case "$1" in
    start)
        start_milvus
        ;;
    stop)
        stop_milvus
        ;;
    restart)
        restart_milvus
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    *)
        show_usage
        exit 0
        ;;
esac