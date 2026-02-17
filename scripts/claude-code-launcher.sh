#!/usr/bin/env bash

set -e

export NATS_URL=wss://hermes.sava.africa
export NATS_CREDS=/Users/eduardokolomajr/.local/share/nats/nsc/keys/creds/sava_technologies/DEV_EDUARDO/user.creds


# CCAOS Environment Configuration
CCAOS_ENV_FILE="${CCAOS_ENV_FILE:-$HOME/.config/ccaos/.env}"

# Ensure the .env file and directory exist
if [ ! -f "$CCAOS_ENV_FILE" ]; then
    mkdir -p "$(dirname "$CCAOS_ENV_FILE")"
    touch "$CCAOS_ENV_FILE"
fi

# Source the .env file if it exists
if [ -f "$CCAOS_ENV_FILE" ]; then
    set -a  # automatically export all variables
    source "$CCAOS_ENV_FILE"
    set +a  # turn off automatic export
fi

# Export CCAOS_ENV_FILE so it's available to child processes
export CCAOS_ENV_FILE

# Configuration
DEFAULT_BASE_URL="http://localhost:25283"
CONTAINER_NAME="ccflare-local"
CONTAINER_IMAGE="ccflare:latest"
CONTAINER_PORT="25283"
HEALTH_CHECK_RETRIES=3
HEALTH_CHECK_DELAY=1

# Crawl4AI Configuration
CRAWL4AI_CONTAINER_NAME="crawl4ai"
CRAWL4AI_CONTAINER_IMAGE="unclecode/crawl4ai:0.6.0-r2"
CRAWL4AI_CONTAINER_PORT="11235"
CRAWL4AI_ENV_FILE="$HOME/.dotfiles/.config/crawl4ai/.llm.env"
CRAWL4AI_BASE_URL="http://localhost:11235"

# Milvus Configuration
MILVUS_COMPOSE_FILE="$HOME/.dotfiles/compose/milvus.yml"
MILVUS_VOLUME_DIRECTORY="$HOME/.config/milvus"
MILVUS_PROJECT_NAME="milvus"
MILVUS_STANDALONE_PORT="19530"
MILVUS_WEBUI_PORT="9091"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 1. Check and set ANTHROPIC_BASE_URL
if [ -z "$ANTHROPIC_BASE_URL" ]; then
    print_warning "ANTHROPIC_BASE_URL not set, using default: $DEFAULT_BASE_URL"
    export ANTHROPIC_BASE_URL="$DEFAULT_BASE_URL"
else
    print_status "ANTHROPIC_BASE_URL is set to: $ANTHROPIC_BASE_URL"
fi

# 2. Check if container exists
container_exists=$(podman ps -a --filter name="$CONTAINER_NAME" --format "{{.Names}}" | grep -w "$CONTAINER_NAME" || true)

if [ -z "$container_exists" ]; then
    print_warning "Container '$CONTAINER_NAME' does not exist. Creating and starting..."
    podman run -d \
        --name "$CONTAINER_NAME" \
        --restart=always \
        -p "${CONTAINER_PORT}:8080" \
        -v "$HOME/.config/ccflare:/home/ccflare/.config/ccflare" \
        -e "ccflare_DB_PATH=/home/ccflare/.config/ccflare/ccflare.db" \
        -e "ccflare_CONFIG_PATH=/home/ccflare/.config/ccflare/ccflare.json" \
        "$CONTAINER_IMAGE"
    
    if [ $? -eq 0 ]; then
        print_status "Container '$CONTAINER_NAME' created and started successfully"
    else
        print_error "Failed to create/start container '$CONTAINER_NAME'"
        exit 1
    fi
else
    # Check if container is running
    container_running=$(podman ps --filter name="$CONTAINER_NAME" --format "{{.Names}}" | grep -w "$CONTAINER_NAME" || true)
    
    if [ -z "$container_running" ]; then
        print_warning "Container '$CONTAINER_NAME' exists but is not running. Starting..."
        podman start "$CONTAINER_NAME"
        
        if [ $? -eq 0 ]; then
            print_status "Container '$CONTAINER_NAME' started successfully"
        else
            print_error "Failed to start container '$CONTAINER_NAME'"
            exit 1
        fi
    else
        print_status "Container '$CONTAINER_NAME' is already running"
    fi
fi

# 3. Health check with retries for ccflare
print_status "Checking ccflare health endpoint..."
for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
    if curl -s -f "${ANTHROPIC_BASE_URL}/health" > /dev/null 2>&1; then
        print_status "ccflare health check successful on attempt $i"
        break
    else
        if [ $i -eq $HEALTH_CHECK_RETRIES ]; then
            print_error "ccflare health check failed after $HEALTH_CHECK_RETRIES attempts"
            print_error "Container may not be ready or there might be a connectivity issue"
            exit 1
        else
            print_warning "ccflare health check failed on attempt $i, retrying in ${HEALTH_CHECK_DELAY}s..."
            sleep $HEALTH_CHECK_DELAY
        fi
    fi
done

# 4. Check if crawl4ai container exists
crawl4ai_exists=$(podman ps -a --filter name="$CRAWL4AI_CONTAINER_NAME" --format "{{.Names}}" | grep -w "$CRAWL4AI_CONTAINER_NAME" || true)

if [ -z "$crawl4ai_exists" ]; then
    print_warning "Container '$CRAWL4AI_CONTAINER_NAME' does not exist. Creating and starting..."
    podman run -d \
        -p "${CRAWL4AI_CONTAINER_PORT}:${CRAWL4AI_CONTAINER_PORT}" \
        --name "$CRAWL4AI_CONTAINER_NAME" \
        --restart=always \
        --env-file "$CRAWL4AI_ENV_FILE" \
        --shm-size=1g \
        "$CRAWL4AI_CONTAINER_IMAGE"
    
    if [ $? -eq 0 ]; then
        print_status "Container '$CRAWL4AI_CONTAINER_NAME' created and started successfully"
    else
        print_error "Failed to create/start container '$CRAWL4AI_CONTAINER_NAME'"
        exit 1
    fi
else
    # Check if crawl4ai container is running
    crawl4ai_running=$(podman ps --filter name="$CRAWL4AI_CONTAINER_NAME" --format "{{.Names}}" | grep -w "$CRAWL4AI_CONTAINER_NAME" || true)
    
    if [ -z "$crawl4ai_running" ]; then
        print_warning "Container '$CRAWL4AI_CONTAINER_NAME' exists but is not running. Starting..."
        podman start "$CRAWL4AI_CONTAINER_NAME"
        
        if [ $? -eq 0 ]; then
            print_status "Container '$CRAWL4AI_CONTAINER_NAME' started successfully"
        else
            print_error "Failed to start container '$CRAWL4AI_CONTAINER_NAME'"
            exit 1
        fi
    else
        print_status "Container '$CRAWL4AI_CONTAINER_NAME' is already running"
    fi
fi

# 5. Health check with retries for crawl4ai
print_status "Checking crawl4ai health endpoint..."
for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
    if curl -s -f "${CRAWL4AI_BASE_URL}/health" > /dev/null 2>&1; then
        print_status "crawl4ai health check successful on attempt $i"
        break
    else
        if [ $i -eq $HEALTH_CHECK_RETRIES ]; then
            print_error "crawl4ai health check failed after $HEALTH_CHECK_RETRIES attempts"
            print_error "Container may not be ready or there might be a connectivity issue"
            exit 1
        else
            print_warning "crawl4ai health check failed on attempt $i, retrying in ${HEALTH_CHECK_DELAY}s..."
            sleep $HEALTH_CHECK_DELAY
        fi
    fi
done

# 6. Check if Milvus services are running
# print_status "Checking Milvus services..."
#
# # Check if all Milvus containers are running using podman directly
# milvus_etcd_running=$(podman ps --filter "name=milvus-etcd" --format "{{.Names}}" | grep -w "milvus-etcd" | wc -l | tr -d ' ')
# milvus_minio_running=$(podman ps --filter "name=milvus-minio" --format "{{.Names}}" | grep -w "milvus-minio" | wc -l | tr -d ' ')
# milvus_standalone_running=$(podman ps --filter "name=milvus-standalone" --format "{{.Names}}" | grep -w "milvus-standalone" | wc -l | tr -d ' ')
#
# if [ "$milvus_etcd_running" -eq 0 ] || [ "$milvus_minio_running" -eq 0 ] || [ "$milvus_standalone_running" -eq 0 ]; then
#     print_error "Milvus services are not running!"
#     print_error "Please start Milvus first with:"
#     print_error "  cd $HOME/.dotfiles"
#     print_error "  DOCKER_VOLUME_DIRECTORY=\"$MILVUS_VOLUME_DIRECTORY\" podman-compose -f \"./compose/milvus.yml\" -p \"milvus\" up -d"
#     print_error ""
#     print_error "Missing services:"
#     [ "$milvus_etcd_running" -eq 0 ] && print_error "  - milvus-etcd"
#     [ "$milvus_minio_running" -eq 0 ] && print_error "  - milvus-minio"
#     [ "$milvus_standalone_running" -eq 0 ] && print_error "  - milvus-standalone"
#     exit 1
# else
#     print_status "All Milvus services are running"
# fi
#
# # 7. Health check for Milvus standalone service
# print_status "Checking Milvus health endpoints..."
#
# # Check Milvus WebUI endpoint
# for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
#     if curl -s -f "http://localhost:${MILVUS_WEBUI_PORT}/healthz" > /dev/null 2>&1; then
#         print_status "Milvus WebUI health check successful on attempt $i"
#         break
#     else
#         if [ $i -eq $HEALTH_CHECK_RETRIES ]; then
#             print_error "Milvus health check failed after $HEALTH_CHECK_RETRIES attempts"
#             print_warning "Milvus may still be initializing. You can check status at http://localhost:${MILVUS_WEBUI_PORT}/webui/"
#             # Don't exit here, as Milvus might take longer to initialize
#         else
#             print_warning "Milvus health check failed on attempt $i, retrying in ${HEALTH_CHECK_DELAY}s..."
#             sleep $HEALTH_CHECK_DELAY
#         fi
#     fi
# done
#
# Launch Claude Code with any passed arguments
print_status "Launching Claude Code..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use claude
claude --add-dir ~/.agent-os --dangerously-skip-permissions "$@"
