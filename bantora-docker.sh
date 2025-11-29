#!/bin/bash

# Bantora Docker Management Script
# Created by Cascade AI
# Author: Tsungai Kaviya
# Copyright: TeraTech Solutions (Pvt) Ltd
# Date/Time: 2025-11-28

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Service definitions - list in dependency order
declare -a SERVICES=(
    "bantora-database"
    "bantora-redis"
    "bantora-api"
    "bantora-web"
    "bantora-gateway"
)

# Services that have JAR files to build
declare -A SERVICES_WITH_JAR=(
    ["bantora-api"]=1
)

# Services that are Flutter apps
declare -A SERVICES_WITH_FLUTTER=(
    ["bantora-web"]=1
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Print usage information
print_usage() {
    echo "Bantora Docker Management Script"
    echo ""
    echo "Usage: $0 [OPTIONS] [ACTION] [SERVICES...]"
    echo ""
    echo "Actions:"
    echo "  -r    [services]     Restart services"
    echo "  -rr   [services]     Redeploy + Restart services"
    echo "  -rrr  [services]     Rebuild + Redeploy + Restart services"
    echo "  -rrrr [services]     Recreate + Rebuild + Redeploy + Restart services"
    echo "  -rrrrr [services]    Redownload + Recreate + Rebuild + Redeploy + Restart"
    echo ""
    echo "Options:"
    echo "  --status            Show service status"
    echo "  --logs [options] [service]  Show logs for a service"
    echo "    Log Options:"
    echo "      --tail <N|all>  Show the last N lines or all lines (default: 500)"
    echo "      -f, --follow    Follow log output"
    echo "  --cleanup           Stop and remove all containers"
    echo "  --build-all         Build all services"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Services: ${SERVICES[*]}"
    echo ""
    echo "Examples:"
    echo "  $0 -rrr bantora-api bantora-web     # Rebuild API and Web"
    echo "  $0 -rr bantora-database              # Redeploy database"
    echo "  $0 --status                          # Show all service status"
    echo "  $0 --logs --tail 200 bantora-api     # Show last 200 log lines"
}

# Load environment variables
source_env() {
    local env_file="$SCRIPT_DIR/.env"
    
    if [ -f "$env_file" ]; then
        echo -e "${BLUE}Loading environment variables from $env_file...${NC}"
        set -a
        source "$env_file"
        set +a
    else
        echo -e "${RED}Error: Environment file $env_file not found${NC}"
        exit 1
    fi
}

# Get container name for a service
get_container_name() {
    local service="$1"
    case "$service" in
        "bantora-database") echo "${DB_CONTAINER_NAME:-bantora-database}" ;;
        "bantora-redis") echo "${REDIS_CONTAINER_NAME:-bantora-redis}" ;;
        "bantora-api") echo "${API_CONTAINER_NAME:-bantora-api}" ;;
        "bantora-web") echo "${WEB_CONTAINER_NAME:-bantora-web}" ;;
        "bantora-gateway") echo "${GATEWAY_CONTAINER_NAME:-bantora-gateway}" ;;
        *) echo "$service" ;;
    esac
}

# Check if container is running
is_container_running() {
    local container_name="$1"
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

# Check service health
check_service_health() {
    local container_name="$1"
    
    if ! is_container_running "$container_name"; then
        echo -e "${RED}✗ $container_name: NOT RUNNING${NC}"
        return 1
    fi
    
    local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
    
    if [ "$health" = "healthy" ]; then
        echo -e "${GREEN}✓ $container_name: HEALTHY${NC}"
        return 0
    elif [ "$health" = "unhealthy" ]; then
        echo -e "${RED}✗ $container_name: UNHEALTHY${NC}"
        return 1
    elif [ "$health" = "starting" ]; then
        echo -e "${YELLOW}⟳ $container_name: STARTING${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $container_name: RUNNING${NC}"
        return 0
    fi
}

# Wait for service health
wait_for_health() {
    local container_name="$1"
    local max_wait="${2:-180}"
    local elapsed=0
    
    echo -e "${BLUE}Waiting for $container_name to be healthy (max ${max_wait}s)...${NC}"
    
    while [ $elapsed -lt $max_wait ]; do
        if check_service_health "$container_name" > /dev/null 2>&1; then
            local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
            if [ "$health" = "healthy" ] || [ "$health" = "none" ]; then
                echo -e "${GREEN}✓ $container_name is healthy${NC}"
                return 0
            fi
        fi
        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done
    
    echo -e "\n${RED}✗ Timeout waiting for $container_name to become healthy${NC}"
    return 1
}

# =============================================================================
# BUILD FUNCTIONS
# =============================================================================

# Build JAR for a service
build_jar() {
    local service="$1"
    echo -e "${BLUE}Building JAR for $service...${NC}"
    
    cd "$SCRIPT_DIR"
    ./gradlew ":$service:bootJar" -x test --no-daemon
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ JAR build successful for $service${NC}"
    else
        echo -e "${RED}✗ JAR build failed for $service${NC}"
        exit 1
    fi
}

# Build Flutter app for a service
build_flutter() {
    local service="$1"
    echo -e "${BLUE}Building Flutter app for $service...${NC}"
    
    cd "$SCRIPT_DIR/$service/bantora_app"
    
    # Get dependencies
    flutter pub get
    
    # Build for web
    flutter build web --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Flutter build successful for $service${NC}"
    else
        echo -e "${RED}✗ Flutter build failed for $service${NC}"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
}

# Build Docker image for a service
build_docker_image() {
    local service="$1"
    echo -e "${BLUE}Building Docker image for $service...${NC}"
    
    cd "$SCRIPT_DIR"
    docker compose build "$service"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Docker image build successful for $service${NC}"
    else
        echo -e "${RED}✗ Docker image build failed for $service${NC}"
        exit 1
    fi
}

# =============================================================================
# SERVICE MANAGEMENT FUNCTIONS
# =============================================================================

# Restart service
restart_service() {
    local service="$1"
    local container_name=$(get_container_name "$service")
    
    echo -e "${BLUE}Restarting $service...${NC}"
    docker compose restart "$service"
    wait_for_health "$container_name"
}

# Redeploy service
redeploy_service() {
    local service="$1"
    local container_name=$(get_container_name "$service")
    
    echo -e "${BLUE}Redeploying $service...${NC}"
    docker compose stop "$service"
    docker compose rm -f "$service"
    docker compose up -d "$service"
    wait_for_health "$container_name"
}

# Rebuild service
rebuild_service() {
    local service="$1"
    local container_name=$(get_container_name "$service")
    
    echo -e "${BLUE}Rebuilding $service...${NC}"
    
    # Build JAR if needed
    if [ "${SERVICES_WITH_JAR[$service]}" = "1" ]; then
        build_jar "$service"
    fi
    
    # Build Flutter if needed
    if [ "${SERVICES_WITH_FLUTTER[$service]}" = "1" ]; then
        build_flutter "$service"
    fi
    
    # Build Docker image
    build_docker_image "$service"
    
    # Redeploy
    redeploy_service "$service"
}

# Recreate service
recreate_service() {
    local service="$1"
    local container_name=$(get_container_name "$service")
    
    echo -e "${BLUE}Recreating $service...${NC}"
    docker compose stop "$service"
    docker compose rm -f "$service"
    docker compose pull "$service" 2>/dev/null || true
    rebuild_service "$service"
}

# Show status
show_status() {
    echo -e "${BLUE}Service Status:${NC}"
    echo ""
    
    for service in "${SERVICES[@]}"; do
        local container_name=$(get_container_name "$service")
        check_service_health "$container_name"
    done
}

# Show logs
show_logs() {
    local service="$1"
    local tail_lines="${2:-500}"
    local follow="${3:-false}"
    
    if [ "$tail_lines" = "all" ]; then
        tail_lines=""
    else
        tail_lines="--tail $tail_lines"
    fi
    
    if [ "$follow" = "true" ]; then
        docker compose logs -f $tail_lines "$service"
    else
        docker compose logs $tail_lines "$service"
    fi
}

# Cleanup
cleanup() {
    echo -e "${YELLOW}Stopping and removing all Bantora containers...${NC}"
    docker compose down
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# =============================================================================
# MAIN LOGIC
# =============================================================================

# Load environment
source_env

# Parse arguments
ACTION=""
SERVICES_TO_PROCESS=()
TAIL_LINES="500"
FOLLOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|-rr|-rrr|-rrrr|-rrrrr)
            ACTION="$1"
            shift
            ;;
        --status)
            show_status
            exit 0
            ;;
        --logs)
            shift
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --tail)
                        TAIL_LINES="$2"
                        shift 2
                        ;;
                    -f|--follow)
                        FOLLOW_LOGS=true
                        shift
                        ;;
                    *)
                        show_logs "$1" "$TAIL_LINES" "$FOLLOW_LOGS"
                        exit 0
                        ;;
                esac
            done
            echo -e "${RED}Error: No service specified for logs${NC}"
            exit 1
            ;;
        --cleanup)
            cleanup
            exit 0
            ;;
        --build-all)
            for service in "${SERVICES[@]}"; do
                if [ "${SERVICES_WITH_JAR[$service]}" = "1" ]; then
                    build_jar "$service"
                fi
                if [ "${SERVICES_WITH_FLUTTER[$service]}" = "1" ]; then
                    build_flutter "$service"
                fi
            done
            exit 0
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            SERVICES_TO_PROCESS+=("$1")
            shift
            ;;
    esac
done

# If no services specified, use all
if [ ${#SERVICES_TO_PROCESS[@]} -eq 0 ]; then
    SERVICES_TO_PROCESS=("${SERVICES[@]}")
fi

# Execute action
case "$ACTION" in
    -r)
        for service in "${SERVICES_TO_PROCESS[@]}"; do
            restart_service "$service"
        done
        ;;
    -rr)
        for service in "${SERVICES_TO_PROCESS[@]}"; do
            redeploy_service "$service"
        done
        ;;
    -rrr)
        for service in "${SERVICES_TO_PROCESS[@]}"; do
            rebuild_service "$service"
        done
        ;;
    -rrrr)
        for service in "${SERVICES_TO_PROCESS[@]}"; do
            recreate_service "$service"
        done
        ;;
    -rrrrr)
        echo -e "${BLUE}Full rebuild requested...${NC}"
        for service in "${SERVICES_TO_PROCESS[@]}"; do
            docker compose pull "$service" 2>/dev/null || true
            recreate_service "$service"
        done
        ;;
    "")
        print_usage
        exit 1
        ;;
    *)
        echo -e "${RED}Unknown action: $ACTION${NC}"
        print_usage
        exit 1
        ;;
esac

echo -e "${GREEN}✓ All operations completed successfully${NC}"
