#!/bin/bash

# Bantora Docker Management Script
# Created in Windsurf Editor 1.9.0
# Author: Tsungai Kaviya
# Copyright: TeraTech Solutions (Pvt) Ltd
# Date/Time: 2025-06-13 00:52:00

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

# Service definitions - list in dependency order
declare -a SERVICES=(
    "bantora-database"
    "bantora-api"
    "bantora-web"
    "bantora-gateway"
)

# Services that have JAR files to build
declare -A SERVICES_WITH_JAR=(
    ["bantora-api"]=1
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
    echo "  -d, --detach         Run in detached mode (this is the default)"
    echo "  -a, --attach         Run in attached mode"
    echo "  --rebuild-all        Rebuild all services in dependency order"
    echo "  --status            Show service status"
    echo "  --logs [options] [service]  Show logs for a service. Default is last 500 lines detached."
    echo "    Log Options:"
    echo "      --tail <N|all>  Show the last N lines or all lines (default: 500)."
    echo "      -f, --follow    Follow log output."
    echo "  --test [type]       Run tests (unit, integration, playwright, all)"
    echo "  --tests <pattern>   When used with --test playwright, runs only matching JUnit tests (Gradle --tests pattern)"
    echo "  --test-unit         Run Java unit tests via gradle"
    echo "  --test-integration  Run integration tests against running services"
    echo "  --test-playwright   Run Playwright UI tests"
    echo "  --test-env-clean    Clean setup test environment with full isolation"
    echo "  --test-env-status   Show test environment status and conflicts"
    echo "  --cleanup           Stop and remove all containers"
    echo "  --destroy-all       Stop and remove all containers (same as --cleanup)"
    echo "  --full-cleanup      Stop, remove containers and clean Bantora resources only"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Services: ${SERVICES[*]}"
    echo ""
    echo "Examples:"
    echo "  # Service Management"
    echo "  $0 -rrr bantora-api bantora-web     # Rebuild API and Web services"
    echo "  $0 -rr bantora-database             # Redeploy database"
    echo "  $0 -d -r bantora-api                # Restart API in detached mode"
    echo "  $0 --logs --tail 200 bantora-api    # Show last 200 log lines for API"
    echo ""
    echo "  # Testing"
    echo "  # Run all tests (unit, integration, and UI)"
    echo "  $0 --test all"
    echo ""
    echo "  # Run specific test types"
    echo "  $0 --test unit                      # Run all unit tests"
    echo "  $0 --test integration               # Run all integration tests"
    echo "  $0 --test playwright                # Run all Playwright UI tests"
    echo ""
    echo "  # Run specific test classes or methods"
    echo "  # Run specific test class"
    echo "  $0 --test unit --tests 'com.t3ratech.bantora.api.service.UserServiceTest'"
    echo "  # Run specific test method"
    echo "  $0 --test unit --tests 'com.t3ratech.bantora.api.service.UserServiceTest.testCreateUser'"
    echo ""
    echo "  # UI Auth Test Examples"
    echo "  # Run login tests"
    echo "  $0 --test playwright --tests 'LoginTest*'"
    echo "  # Run registration tests"
    echo "  $0 --test playwright --tests 'RegistrationTest*'"
    echo "  # Run all auth-related tests"
    echo "  $0 --test playwright --tests '*Auth*'"
    echo ""
    echo "  # API Unit Test Examples"
    echo "  # Run all controller tests"
    echo "  $0 --test unit --tests '*ControllerTest'"
    echo "  # Run all service tests"
    echo "  $0 --test unit --tests '*ServiceTest'"
    echo "  # Run repository tests"
    echo "  $0 --test unit --tests '*RepositoryTest'"
    echo ""
    echo "  # Integration Test Examples"
    echo "  # Run all API integration tests"
    echo "  $0 --test integration --tests '*ApiIntegrationTest'"
    echo "  # Run database integration tests"
    echo "  $0 --test integration --tests '*RepositoryIT'"
    echo ""
    echo "  # Advanced Test Filtering"
    echo "  # Run tests with specific tags"
    echo "  $0 --test unit --tests 'com.t3ratech.bantora.api.*' --tests '!*IntegrationTest'"
    echo "  # Run tests matching multiple patterns"
    echo "  $0 --test unit --tests '*Service*' --tests '*Util*'"
    echo ""
    echo "  # Test with Debug Output"
    echo "  # Run with debug logging"
    echo "  DEBUG=true $0 --test unit --tests 'com.t3ratech.bantora.api.service.*'"
    echo "  # Run with test output"
    echo "  $0 --test unit --tests 'com.t3ratech.bantora.api.service.*' --info"
}

# Resolve the actual container name for a given service using env overrides
get_container_name_for_service() {
    local service="$1"
    local var_name=""
    case "$service" in
        "bantora-database") var_name="DB_CONTAINER_NAME" ;;
        "bantora-api") var_name="API_CONTAINER_NAME" ;;
        "bantora-web") var_name="WEB_CONTAINER_NAME" ;;
        "bantora-gateway") var_name="GATEWAY_CONTAINER_NAME" ;;
        *) var_name="" ;;
    esac
    if [ -n "$var_name" ] && [ -n "${!var_name}" ]; then
        echo "${!var_name}"
    else
        echo "$service"
    fi
}

# Load environment variables
source_env() {
    local env_file="${1:-$SCRIPT_DIR/.env}"
    
    if [ -f "$env_file" ]; then
        echo "Loading environment variables from $env_file..."
        set -a
        source "$env_file"
        set +a
        # Track which environment file was sourced
        export TEST_MODE="false"
        export BANTORA_ENV_SOURCE="$env_file"
    else
        echo -e "${RED}Error: Environment file $env_file not found${NC}"
        exit 1
    fi
}

# Load test environment variables
source_test_env() {
    if [ -f "$SCRIPT_DIR/.env.test" ]; then
        echo "Loading test environment variables from $SCRIPT_DIR/.env.test..."
        set -a
        source "$SCRIPT_DIR/.env.test"
        set +a
        # Track that we are in test mode and where env came from
        export TEST_MODE="true"
        export BANTORA_ENV_SOURCE="$SCRIPT_DIR/.env.test"
        
        # Environment variables will be used directly - system will break if missing
        echo "Using test environment variables from .env.test - system will fail fast if any are missing"
        
        # Ensure test environment isolation by stopping conflicting dev containers
        ensure_test_environment_isolation
    else
        echo -e "${YELLOW}Warning: .env.test file not found, using regular .env for tests${NC}"
        source_env
    fi
}

# Ensure test environment isolation by managing conflicting containers
ensure_test_environment_isolation() {
    echo -e "${BLUE}Ensuring test environment isolation...${NC}"
    
    # List of dev container patterns that conflict with test containers
    local dev_containers=(
        "bantora-database" 
        "bantora-api" 
        "bantora-web" 
        "bantora-gateway"
    )
    
    local conflicts_found=false
    
    # Check for running dev containers that would conflict with test containers
    for service in "${dev_containers[@]}"; do
        # Get dev container name (without test prefix)
        local dev_container=$(docker ps -q -f "name=^${service}$" 2>/dev/null || true)
        local test_container=$(docker ps -q -f "name=^bantora-test-${service#bantora-}$" 2>/dev/null || true)
        
        if [ -n "$dev_container" ] && [ -n "$test_container" ]; then
            echo -e "${YELLOW}Conflict detected: Both dev ($service) and test (bantora-test-${service#bantora-}) containers are running${NC}"
            conflicts_found=true
        elif [ -n "$dev_container" ]; then
            # Check if dev container is using test ports by examining port mappings
            local dev_ports=$(docker port "$service" 2>/dev/null | grep -E ":(15432|18091|18080|17083)" || true)
            if [ -n "$dev_ports" ]; then
                echo -e "${YELLOW}Dev container $service is using test ports: $dev_ports${NC}"
                conflicts_found=true
            fi
        fi
    done
    
    if [ "$conflicts_found" = true ]; then
        echo -e "${YELLOW}Port/container conflicts detected between dev and test environments.${NC}"
        echo -e "${YELLOW}To ensure test isolation, stopping conflicting dev containers...${NC}"
        
        # Stop dev containers that conflict with test environment
        for service in "${dev_containers[@]}"; do
            local container_id=$(docker ps -q -f "name=^${service}$" 2>/dev/null || true)
            if [ -n "$container_id" ]; then
                echo -e "${YELLOW}Stopping dev container: $service${NC}"
                docker stop "$service" >/dev/null 2>&1 || true
            fi
        done
        
        echo -e "${GREEN}Test environment isolation ensured${NC}"
    else
        echo -e "${GREEN}No conflicts detected - test environment is isolated${NC}"
    fi
}

# Check if service is valid
is_valid_service() {
    local service=$1
    for s in "${SERVICES[@]}"; do
        if [ "$s" = "$service" ]; then
            return 0
        fi
    done
    return 1
}

# Check if service has a JAR file
service_has_jar() {
    local service=$1
    [ "${SERVICES_WITH_JAR[$service]}" = "1" ]
}

# =============================================================================
# CORE SERVICE MANAGEMENT FUNCTIONS
# =============================================================================

# Wait for service to be healthy
wait_for_service_health() {
    local service=$1
    local max_retries=30
    local retry_count=0
    local health_check_cmd=""
    
    echo "Waiting for $service to be healthy..."
    
    # Map service name to environment variable prefix
    local health_check_var
    case "$service" in
        bantora-database) health_check_var="DB_HEALTH_CMD" ;;
        bantora-api) health_check_var="API_HEALTH_CMD" ;;
        bantora-web) health_check_var="WEB_HEALTH_CMD" ;;
        bantora-gateway) health_check_var="GATEWAY_HEALTH_CMD" ;;
        *) health_check_var="${service#bantora-}_HEALTH_CMD" ;;  # Fallback to service name without bantora- prefix
    esac
    
    # Get health check command from environment variables - no fallbacks!
    if [ -z "${!health_check_var}" ]; then
        local env_file_ref="${BANTORA_ENV_SOURCE}"
        echo -e "${RED}Error: No health check defined for service: $service${NC}"
        echo -e "${RED}Please define a health check in $env_file_ref as ${health_check_var}${NC}"
        echo -e "${YELLOW}Current service prefixes and health checks:${NC}"
        env | grep -E '_(HEALTH_CMD|PORT)=' | sort
        return 1
    fi
    
    health_check_cmd="${!health_check_var}"
    local env_source_ref="${BANTORA_ENV_SOURCE}"
    echo -e "${GREEN}Using health check from $env_source_ref: ${health_check_var}=${health_check_cmd}${NC}"
    
    echo -e "Checking health with command: $health_check_cmd"
    
    while [ $retry_count -lt $max_retries ]; do
        # Check if container is running
        local container_id
        # Get actual container name from environment variables
        local container_name_var=""
        case "$service" in
            "bantora-database")
                container_name_var="DB_CONTAINER_NAME"
                ;;
            "bantora-api")
                container_name_var="API_CONTAINER_NAME"
                ;;
            "bantora-web")
                container_name_var="WEB_CONTAINER_NAME"
                ;;
            "bantora-gateway")
                container_name_var="GATEWAY_CONTAINER_NAME"
                ;;
        esac
        
        local actual_container_name="${!container_name_var:-$service}"
        container_id=$(docker ps -q -f "name=^${actual_container_name}$" 2>/dev/null || true)
        
        if [ -z "$container_id" ]; then
            echo -e "${RED}Container for $service is not running${NC}"
            return 1
        fi
        
        # Check health using the health check command
        if docker exec -i "$container_id" sh -c "$health_check_cmd" >/dev/null 2>&1; then
            echo -e "${GREEN}$service is healthy${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}Health check attempt $((retry_count + 1))/$max_retries failed, retrying in 5 seconds...${NC}"
        sleep 5
        retry_count=$((retry_count + 1))
    done
    
    echo -e "${RED}$service failed to become healthy after $max_retries attempts${NC}"
    echo -e "Last health check command: $health_check_cmd"
    
    # Show container logs to help with debugging
    echo -e "\n${YELLOW}=== Container logs for $service ===${NC}"
    docker logs "$container_id" 2>&1 | tail -n 20
    
    return 1
}

# Stop service
stop_service() {
    local service=$1
    echo "Stopping $service..."
    docker compose stop "$service" 2>/dev/null || true
}

# Remove service container
remove_service() {
    local service=$1
    echo "Removing $service container..."
    # Stop and remove the container using docker compose. The -s flag stops it before removing.
    docker compose rm -s -f "$service" 2>/dev/null || true
    # As a fallback, try to remove the container directly by name, in case compose fails.
    docker rm -f "$service" 2>/dev/null || true
}

# Build service (JAR or Docker image)
build_service() {
    local service=$1
    
    # Build JAR if service has one
    if service_has_jar "$service"; then
        echo "Building JAR for $service..."
        
        # Special cases for submodules
        if [ "$service" = "bantora-api" ]; then
            ./gradlew ":bantora-api:build" -x test
        elif [ "$service" = "bantora-web" ]; then
            ./gradlew ":bantora-web:build" -x test
        elif [ "$service" = "bantora-database" ]; then
            ./gradlew ":bantora-database:build" -x test
        else
            ./gradlew ":$service:build" -x test
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to build JAR for $service${NC}"
            return 1
        fi
    fi
    
    echo "Building Docker image for $service..."
    docker compose build "$service"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to build Docker image for $service${NC}"
        return 1
    fi
}

# Start service
start_service() {
    local service=$1
    
    echo "Starting $service..."
    if [ "$DETACH_MODE" = "true" ]; then
        if ! docker compose up -d "$service"; then
            echo -e "${RED}Failed to start $service. Checking logs...${NC}"
            docker compose logs "$service" | tail -n 50
            return 1
        fi
        wait_for_service_health "$service"
    else
        if ! docker compose up "$service"; then
            echo -e "${RED}Failed to start $service in attached mode.${NC}"
            return 1
    fi
    fi
}

# Get service status
get_service_status() {
    local service=$1
    local container_id
    local container_name
    
    # Try different container name patterns
    for pattern in "bantora-$service" "$service"; do
        container_id=$(docker ps -a -q -f "name=^${pattern}$" 2>/dev/null || true)
        if [ -n "$container_id" ]; then
            container_name=$(docker inspect --format '{{.Name}}' "$container_id" 2>/dev/null | sed 's/^\///' || true)
            break
        fi
    done
    
    # If no container found, service is not running
    if [ -z "$container_id" ]; then
        echo -e "  $service: ${RED}Not running${NC}"
        return 0
    fi
    
    # Get detailed container info
    local container_info
    container_info=$(docker inspect "$container_id" 2>/dev/null || true)
    
    # If no container info, service is not running
    if [ -z "$container_info" ] || [ "$container_info" = "[]" ]; then
        echo -e "  $service: ${RED}Not running${NC}"
        return 0
    fi
    
    # Extract status and health from the container info
    local status=$(echo "$container_info" | jq -r '.[0].State.Status // "unknown"' 2>/dev/null || echo "unknown")
    local health=$(echo "$container_info" | jq -r '.[0].State.Health.Status // ""' 2>/dev/null || echo "")
    
    # Special case for database which might not have a health check
    if ([ "$service" = "database" ] || [ "$service" = "bantora-database" ]) && [ "$status" = "running" ]; then
        if docker exec -i "$container_id" pg_isready -U postgres -d postgres -q 2>/dev/null; then
            health="healthy"
        else
            health="unhealthy"
        fi
    fi
    
    # Get container uptime if running
    local uptime=""
    if [ "$status" = "running" ]; then
        local started_at=$(echo "$container_info" | jq -r '.[0].State.StartedAt // empty' 2>/dev/null)
        if [ -n "$started_at" ]; then
            # Calculate uptime in a POSIX-compliant way
            local now_sec=$(date +%s)
            local started_sec=$(date -d "$started_at" +%s 2>/dev/null || date -d "${started_at%.*}Z" +%s 2>/dev/null || echo 0)
            if [ "$started_sec" -gt 0 ] 2>/dev/null; then
                local diff_sec=$((now_sec - started_sec))
                local hours=$((diff_sec / 3600))
                local minutes=$(( (diff_sec % 3600) / 60 ))
                local seconds=$((diff_sec % 60))
                uptime=$(printf "%02dh %02dm %02ds" $hours $minutes $seconds)
            fi
        fi
    fi
    
    # Output the status
    if [ "$status" = "running" ]; then
        if [ -z "$health" ] || [ "$health" = "healthy" ]; then
            echo -e "  $service: ${GREEN}Running (healthy)${uptime:+ for $uptime}${NC}"
        elif [ "$health" = "starting" ]; then
            echo -e "  $service: ${YELLOW}Starting...${uptime:+ for $uptime}${NC}"
        else
            echo -e "  $service: ${RED}Running ($health)${uptime:+ for $uptime}${NC}"
        fi
    else
        local exit_code=$(echo "$container_info" | jq -r '.[0].State.ExitCode // 0' 2>/dev/null || echo 0)
        if [ "$exit_code" != "0" ]; then
            echo -e "  $service: ${RED}Crashed (Exit code: $exit_code)${NC}"
        else
            echo -e "  $service: ${YELLOW}Stopped${NC} (Status: $status)"
        fi
    fi
}

# =============================================================================
# ACTION FUNCTIONS
# =============================================================================

# Action: Restart (r)
action_restart() {
    local service=$1
    echo -e "${YELLOW}Restarting $service...${NC}"
    
    stop_service "$service"
    start_service "$service"
}

# Action: Redeploy + Restart (rr)
action_redeploy() {
    local service=$1
    echo -e "${YELLOW}Redeploying $service...${NC}"
    
    stop_service "$service"
    remove_service "$service"
    start_service "$service"
}

# Action: Rebuild + Redeploy + Restart (rrr)
action_rebuild() {
    local service=$1
    echo -e "${YELLOW}Rebuilding $service...${NC}"
    
    stop_service "$service"
    remove_service "$service"
    build_service "$service"
    start_service "$service"
}

# Action: Recreate + Rebuild + Redeploy + Restart (rrrr)
action_recreate() {
    local service=$1
    echo -e "${YELLOW}Recreating $service...${NC}"
    
    stop_service "$service"
    remove_service "$service"
    docker rmi local "$(basename $(pwd))-$service" 2>/dev/null || true
    build_service "$service"
    start_service "$service"
}

# Action: Redownload + Recreate + Rebuild + Redeploy + Restart (rrrrr)
action_redownload() {
    local service=$1
    echo -e "${YELLOW}Redownloading and recreating $service...${NC}"
    
    stop_service "$service"
    remove_service "$service"
    # Remove only the specific service image
    docker rmi "$(basename $(pwd))-$service" 2>/dev/null || true
    docker rmi "bantora-$service" 2>/dev/null || true
    # Remove service-specific volumes (if any)
    docker volume ls --filter "name=bantora.*$service" -q | xargs -r docker volume rm 2>/dev/null || true
    build_service "$service"
    start_service "$service"
}

# Display service information and credentials
display_service_info() {
    echo -e "\n${GREEN}============================================${NC}"
    echo -e "${GREEN}         BANTORA SERVICES INFORMATION         ${NC}"
    echo -e "${GREEN}============================================${NC}"
    
    # Load environment variables if not already loaded
    if [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
        source_env
    fi
    
    # Web Interface
    echo -e "\n${YELLOW}Web Interface:${NC}"
    echo -e "  URL: ${BLUE}http://localhost:${WEB_PORT}${NC}"
    
    # API
    echo -e "\n${YELLOW}API:${NC}"
    echo -e "  URL: ${BLUE}http://localhost:${API_PORT}${NC}"
    echo -e "  Swagger UI: ${BLUE}http://localhost:${API_PORT}/swagger-ui.html${NC}"
    
    # Gateway
    echo -e "\n${YELLOW}Gateway:${NC}"
    echo -e "  URL: ${BLUE}http://localhost:${GATEWAY_PORT}${NC}"
    
    # Database
    echo -e "\n${YELLOW}Database:${NC}"
    echo -e "  Type: PostgreSQL"
    echo -e "  Host: localhost"
    echo -e "  Port: ${DB_PORT}"
    echo -e "  Name: ${DB_NAME}"
    echo -e "  Username: ${DB_USERNAME}"
    echo -e "  Password: ${DB_PASSWORD}"
    echo -e "  Connection URL: postgresql://${DB_USERNAME}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}"
    
    # Mail Interface (Mailpit)
    echo -e "\n${YELLOW}Mail Interface:${NC}"
    echo -e "  Web UI: ${BLUE}http://localhost:8025${NC}"
    echo -e "  SMTP Server: localhost:1025"
    
    # JWT Configuration
    echo -e "\n${YELLOW}JWT Configuration:${NC}"
    echo -e "  Issuer: ${JWT_ISSUER}"
    echo -e "  Audience: ${JWT_AUDIENCE}"
    echo -e "  Expiration: ${JWT_EXPIRATION_MS}ms ($((JWT_EXPIRATION_MS/86400000)) days)"
    
    echo -e "\n${GREEN}============================================${NC}\n"
}

# Execute action on services in dependency order
execute_action() {
    local action=$1
    shift
    local services_to_process=("$@")
    
    # If no services specified, use all services
    if [ ${#services_to_process[@]} -eq 0 ]; then
        services_to_process=("${SERVICES[@]}")
    fi
    
    # Validate all services before starting
    for service in "${services_to_process[@]}"; do
        if ! is_valid_service "$service"; then
            echo -e "${RED}Error: Invalid service: $service${NC}"
            print_usage
            exit 1
        fi
    done
    
    # Process each service in dependency order
    for service in "${SERVICES[@]}"; do
        # Only process if service is in the list of services to process
        if [[ " ${services_to_process[*]} " =~ " ${service} " ]]; then
            echo -e "\n${BLUE}Processing $service...${NC}"
            
            case $action in
            "restart"|"r"|"-r")
                    action_restart "$service"
                    ;;
            "redeploy"|"rr"|"-rr")
                    action_redeploy "$service"
                    ;;
            "rebuild"|"rrr"|"-rrr")
                    action_rebuild "$service"
                    ;;
            "recreate"|"rrrr"|"-rrrr")
                    action_recreate "$service"
                    ;;
            "redownload"|"rrrrr"|"-rrrrr")
                    action_redownload "$service"
                    ;;
                *)
                    echo -e "${RED}Error: Unknown action: $action${NC}"
                    print_usage
                    exit 1
                    ;;
            esac
            
            # If any step fails, exit with error
            if [ $? -ne 0 ]; then
                echo -e "${RED}Error: Failed to process $service${NC}"
                exit 1
            fi
        fi
    done
    
    # Display service information after successful build/start
    if [[ "$action" == "-rrr" || "$action" == "-rrrr" || "$action" == "-rrrrr" ]]; then
        display_service_info
    fi
}

# =============================================================================
# TEST ENVIRONMENT MANAGEMENT FUNCTIONS
# =============================================================================

# Start full test environment
start_test_environment() {
    echo -e "${BLUE}Starting test environment...${NC}"
    
    # Load test environment variables
    source_test_env
    
    echo -e "${GREEN}Test environment configuration loaded:${NC}"
    echo "  Database Port: ${DB_PORT}"
    echo "  API Port: ${API_INTERNAL_PORT}"
    echo "  Web Port: ${WEB_INTERNAL_PORT}"
    echo "  Gateway Port: ${GATEWAY_INTERNAL_PORT}"
    
    # Start services in dependency order using test configuration
    # Core services required for all tests
    local core_services=("bantora-database" "bantora-api" "bantora-web" "bantora-gateway")
    # Optional services that can fail without breaking tests
    local optional_services=()
    
    for service in "${core_services[@]}"; do
        echo -e "${YELLOW}Starting test service: $service${NC}"
        if ! start_service "$service"; then
            echo -e "${RED}Failed to start test service: $service${NC}"
            return 1
        fi
    done
    
    # Start optional services - don't fail if they don't start
    for service in "${optional_services[@]}"; do
        echo -e "${YELLOW}Starting optional test service: $service${NC}"
        if ! start_service "$service"; then
            echo -e "${YELLOW}Optional service $service failed to start, continuing...${NC}"
        fi
    done
    
    echo -e "${GREEN}Test environment started successfully${NC}"
    show_test_environment_status
}

# Stop test environment
stop_test_environment() {
    echo -e "${BLUE}Stopping test environment...${NC}"
    
    # Test environment should already be loaded by calling function
    # Test environment should already be loaded by calling function
    local test_services=("bantora-gateway" "bantora-web" "bantora-api" "bantora-database")
    
    for service in "${test_services[@]}"; do
        echo -e "${YELLOW}Stopping test service: $service${NC}"
        stop_service "$service"
        remove_service "$service"
    done
    
    # Remove anonymous volumes to ensure clean initialization on next start
    echo -e "${YELLOW}Removing test environment volumes...${NC}"
    docker volume ls -q --filter "name=bantora" | xargs -r docker volume rm 2>/dev/null || true
    docker volume ls -q --filter "dangling=true" | xargs -r docker volume rm 2>/dev/null || true
    
    echo -e "${GREEN}Test environment stopped and cleaned${NC}"
}

# Reset test environment (rebuild and restart)
reset_test_environment() {
    echo -e "${BLUE}Resetting test environment...${NC}"
    
    # Test environment should already be loaded by calling function
    stop_test_environment
    
    # Clean up test containers and images (project-specific only)
    echo -e "${YELLOW}Cleaning up test containers and images...${NC}"
    # Remove only stopped bantora containers
    docker ps -a --filter "name=bantora" --filter "status=exited" -q | xargs -r docker rm 2>/dev/null || true
    # Remove only dangling bantora images
    docker images --filter "dangling=true" --filter "reference=*bantora*" -q | xargs -r docker rmi 2>/dev/null || true
    # Remove unused bantora networks
    docker network ls --filter "name=bantora" -q | xargs -r docker network rm 2>/dev/null || true
    
    # Rebuild and start
    # Rebuild and start
    local test_services=("bantora-database" "bantora-api" "bantora-web" "bantora-gateway")
    
    for service in "${test_services[@]}"; do
        echo -e "${YELLOW}Rebuilding test service: $service${NC}"
        if ! build_service "$service"; then
            echo -e "${RED}Failed to rebuild test service: $service${NC}"
            return 1
        fi
    done
    
    start_test_environment
}

# Show test environment status
show_test_environment_status() {
    echo -e "${BLUE}Test Environment Status:${NC}"
    
    # Test environment should already be loaded by calling function
    # Test environment should already be loaded by calling function
    local test_services=("bantora-database" "bantora-api" "bantora-web" "bantora-gateway")
    
    for service in "${test_services[@]}"; do
        get_service_status "$service"
    done
    
    echo ""
    echo -e "${BLUE}Test Environment URLs:${NC}"
    echo "  Web Interface: http://localhost:${WEB_INTERNAL_PORT}"
    echo "  API Base: http://localhost:${API_INTERNAL_PORT}/api"
    echo "  Gateway: http://localhost:${GATEWAY_INTERNAL_PORT}"
    echo "  Database: localhost:${DB_PORT}"
    echo "  Communication Web: http://localhost:${COMMUNICATION_WEB_INTERNAL_PORT}"
}

# =============================================================================
# MULTI-LANGUAGE TESTING FUNCTIONS
# =============================================================================

# Multi-language unit tests
run_multilang_unit_tests() {
    echo -e "${BLUE}Running multi-language unit tests...${NC}"
    
    # Define supported languages for testing
    local languages=("en" "de" "fr" "es" "it" "ru" "sn" "zh" "ar" "hi" "pt" "ja" "ko")
    local failed_languages=()
    
    for lang in "${languages[@]}"; do
        echo -e "${YELLOW}Testing language: $lang${NC}"
        
        # Run unit tests with specific language
        if [ -n "$TESTS_PATTERN" ]; then
            if ! ./gradlew :bantora-api:test --tests "$TESTS_PATTERN" -Dspring.profiles.active=test -Duser.language=${lang:0:2} -Duser.country=${lang:2}; then
                failed_languages+=("$lang")
            fi
        else
            if ! ./gradlew :bantora-api:test -Dspring.profiles.active=test -Duser.language=${lang:0:2} -Duser.country=${lang:2}; then
                failed_languages+=("$lang")
            fi
        fi
    done
    
    # Report results
    if [ ${#failed_languages[@]} -eq 0 ]; then
        echo -e "${GREEN}All languages passed unit tests successfully${NC}"
        return 0
    else
        echo -e "${RED}The following languages failed unit tests: ${failed_languages[*]}${NC}"
        return 1
    fi
}

# Multi-language integration tests
run_multilang_integration_tests() {
    echo -e "${BLUE}Running multi-language integration tests...${NC}"
    
    # Ensure test environment is running (environment should already be loaded)
    start_test_environment
    
    # Define supported languages for testing
    local languages=("en" "de" "fr" "es" "it" "ru" "sn" "zh" "ar" "hi" "pt" "ja" "ko")
    local failed_languages=()
    
    for lang in "${languages[@]}"; do
        echo -e "${YELLOW}Testing integration for language: $lang${NC}"
        
        # Test API endpoints with specific language headers
        if ! test_api_endpoints_for_language "$lang"; then
            failed_languages+=("$lang")
        fi
    done
    
    # Report results
    if [ ${#failed_languages[@]} -eq 0 ]; then
        echo -e "${GREEN}All languages passed integration tests successfully${NC}"
        return 0
    else
        echo -e "${RED}The following languages failed integration tests: ${failed_languages[*]}${NC}"
        return 1
    fi
}

# Multi-language UI tests
run_multilang_ui_tests() {
    echo -e "${BLUE}Running multi-language UI tests...${NC}"
    
    # Ensure test environment is running (environment should already be loaded)
    start_test_environment
    
    # Define supported languages for testing
    local languages=("en" "de" "fr" "es" "it" "ru" "sn" "zh")
    local failed_languages=()
    
    for lang in "${languages[@]}"; do
        echo -e "${YELLOW}Testing UI for language: $lang${NC}"
        
        # Run Playwright tests with language-specific validation
        if ! run_playwright_tests_for_language "$lang"; then
            failed_languages+=("$lang")
        fi
    done
    
    # Report results
    if [ ${#failed_languages[@]} -eq 0 ]; then
        echo -e "${GREEN}All languages passed UI tests successfully${NC}"
        return 0
    else
        echo -e "${RED}The following languages failed UI tests: ${failed_languages[*]}${NC}"
        return 1
    fi
}

# Run all multi-language tests
run_multilang_all_tests() {
    echo -e "${BLUE}Running comprehensive multi-language test suite...${NC}"
    
    local failed_test_types=()
    
    # Run multi-language unit tests
    if ! run_multilang_unit_tests; then
        failed_test_types+=("unit")
    fi
    
    # Run multi-language integration tests
    if ! run_multilang_integration_tests; then
        failed_test_types+=("integration")
    fi
    
    # Run multi-language UI tests
    if ! run_multilang_ui_tests; then
        failed_test_types+=("ui")
    fi
    
    # Report final results
    if [ ${#failed_test_types[@]} -eq 0 ]; then
        echo -e "${GREEN}All multi-language tests passed successfully${NC}"
        return 0
    else
        echo -e "${RED}The following test types failed: ${failed_test_types[*]}${NC}"
        return 1
    fi
}

# Test API endpoints for specific language
test_api_endpoints_for_language() {
    local lang="$1"
    local base_url="http://localhost:${API_INTERNAL_PORT}/api"
    
    echo "Testing API endpoints for language: $lang"
    
    # Test user registration with language header
    local test_username="testuser_${lang}_$(date +%s)"
    local test_email="${test_username}@test.local"
    local test_password="TestPass123!"
    
    # Register user
    local register_response=$(curl -s -w "%{http_code}" -o /tmp/register_response.json \
        -H "Content-Type: application/json" \
        -H "Accept-Language: $lang" \
        -d "{\"username\":\"$test_username\",\"email\":\"$test_email\",\"password\":\"$test_password\"}" \
        "$base_url/v1/auth/register")
    
    if [ "${register_response: -3}" != "201" ] && [ "${register_response: -3}" != "200" ]; then
        echo "Registration failed for language $lang (HTTP ${register_response: -3})"
        return 1
    fi
    
    # Login user and capture session
    local login_response=$(curl -s -w "%{http_code}" -c /tmp/session_${lang}.txt \
        -H "Content-Type: application/json" \
        -H "Accept-Language: $lang" \
        -d "{\"username\":\"$test_username\",\"password\":\"$test_password\"}" \
        "$base_url/v1/auth/login")
    
    if [ "${login_response: -3}" != "200" ]; then
        echo "Login failed for language $lang (HTTP ${login_response: -3})"
        return 1
    fi
    
    # Test menu command with language validation
    local menu_response=$(curl -s -b /tmp/session_${lang}.txt \
        -H "Accept-Language: $lang" \
        "$base_url/v1/game/command/menu")
    
    # Validate response contains language-specific content
    if ! validate_language_response "$menu_response" "$lang" "menu"; then
        echo "Menu response validation failed for language $lang"
        return 1
    fi
    
    # Test finance operations with language validation
    local deposit_response=$(curl -s -b /tmp/session_${lang}.txt \
        -H "Content-Type: application/json" \
        -H "Accept-Language: $lang" \
        -d "{\"command\":\"deposit 1000\"}" \
        "$base_url/v1/game/command")
    
    if ! validate_language_response "$deposit_response" "$lang" "deposit"; then
        echo "Deposit response validation failed for language $lang"
        return 1
    fi
    
    # Cleanup
    rm -f /tmp/session_${lang}.txt /tmp/register_response.json
    
    echo "API tests passed for language: $lang"
    return 0
}

# Validate language-specific response content
validate_language_response() {
    local response="$1"
    local language="$2"
    local message_key="$3"
    
    # Path to language properties file
    local properties_file="bantora-common/bantora-common-shared/src/main/resources/i18n/messages_${language}.properties"
    
    # Check if properties file exists
    if [ ! -f "$properties_file" ]; then
        echo "Warning: Language properties file not found: $properties_file"
        # Fall back to basic validation - response should not be empty
        if [ -n "$response" ] && [ "${#response}" -gt 20 ]; then
            return 0
        fi
        return 1
    fi
    
    # Extract expected message from properties file
    local expected_message
    expected_message=$(grep "^${message_key}=" "$properties_file" | cut -d'=' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    if [ -z "$expected_message" ]; then
        echo "Warning: Message key '$message_key' not found in $properties_file"
        # Fall back to basic validation
        if [ -n "$response" ] && [ "${#response}" -gt 20 ]; then
            return 0
        fi
        return 1
    fi
    
    # Check if response contains the expected message from properties file
    if echo "$response" | grep -q -F "$expected_message"; then
        echo "✓ Language validation passed for $language: found expected message '$expected_message'"
        return 0
    else
        echo "✗ Language validation failed for $language: expected '$expected_message' not found in response"
        return 1
    fi
}

# Run Playwright tests for specific language
run_playwright_tests_for_language() {
    local lang="$1"
    
    echo "Running Playwright tests for language: $lang"
    
    # Set language-specific environment variables
    export TEST_LANGUAGE="$lang"
    export PLAYWRIGHT_LANGUAGE="$lang"
    
    # Run language-specific Playwright tests
    if [ -n "$TESTS_PATTERN" ]; then
        if ! ./gradlew :bantora-web:test --tests "*MultiLanguage*" -Dspring.profiles.active=test -DTEST_LANGUAGE="$lang"; then
            return 1
        fi
    else
        if ! ./gradlew :bantora-web:test --tests "*MultiLanguage*" -Dspring.profiles.active=test -DTEST_LANGUAGE="$lang"; then
            return 1
        fi
    fi
    
    return 0
}

# =============================================================================
# TESTING FUNCTIONS
# =============================================================================

# Run unit tests
run_unit_tests() {
    echo -e "${BLUE}Running Java unit tests...${NC}"
    
    # Load test environment for unit tests
    source_test_env
    
    # Ensure API service is built first
    if ! ./gradlew :bantora-api:build -x test; then
        echo -e "${RED}Failed to build API for tests${NC}"
        return 1
    fi
    
    # Run API unit tests with optional filtering
    echo "Running API unit tests only..."
    
    # Pass all required environment variables as system properties
    local gradle_props="-Dspring.profiles.active=test"
    gradle_props="$gradle_props -DBANTORA_SYSTEM_USER_ID=$BANTORA_SYSTEM_USER_ID"
    gradle_props="$gradle_props -DJWT_SECRET_KEY=$JWT_SECRET_KEY"
    gradle_props="$gradle_props -DJWT_EXPIRATION_MS=$JWT_EXPIRATION_MS"
    gradle_props="$gradle_props -DJWT_ISSUER=$JWT_ISSUER"
    gradle_props="$gradle_props -DJWT_AUDIENCE=$JWT_AUDIENCE"
    gradle_props="$gradle_props -DDB_USERNAME=$DB_USERNAME"
    gradle_props="$gradle_props -DDB_PASSWORD=$DB_PASSWORD"
    gradle_props="$gradle_props -DBANTORA_LOG_DEST=$BANTORA_LOG_DEST"
    gradle_props="$gradle_props -DAPI_INTERNAL_PORT=$API_INTERNAL_PORT"
    gradle_props="$gradle_props -DTEST_USER_USERNAME=$TEST_USER_USERNAME"
    gradle_props="$gradle_props -DTEST_USER_EMAIL=$TEST_USER_EMAIL"
    gradle_props="$gradle_props -DTEST_USER_PASSWORD=$TEST_USER_PASSWORD"
    
    if [ -n "$TESTS_PATTERN" ]; then
        echo "Using test filter pattern: $TESTS_PATTERN"
        echo "Executing: ./gradlew :bantora-api:test --tests \"$TESTS_PATTERN\" $gradle_props"
        if ! ./gradlew :bantora-api:test --tests "$TESTS_PATTERN" $gradle_props; then
            echo -e "${RED}API unit tests failed${NC}"
            return 1
        fi
    else
        echo "Executing: ./gradlew :bantora-api:test $gradle_props"
        if ! ./gradlew :bantora-api:test $gradle_props; then
            echo -e "${RED}API unit tests failed${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}Unit tests completed successfully${NC}"
    return 0
}

# Run integration tests
run_integration_tests() {
    echo -e "${BLUE}Running integration tests against running services...${NC}"
    
    # Always restart test environment to fix authentication issues
    echo -e "${YELLOW}Restarting test environment to ensure clean state...${NC}"
    stop_test_environment
    start_test_environment
    
    # Check if required services are running
    local required_services=("bantora-database" "bantora-api")
    for service in "${required_services[@]}"; do
        local container_name
        container_name=$(get_container_name_for_service "$service")
        local container_id=$(docker ps -q -f "name=^${container_name}$" 2>/dev/null || true)
        if [ -z "$container_id" ]; then
            echo -e "${YELLOW}Service $service is not running, starting it...${NC}"
            start_service "$service"
            if [ $? -ne 0 ]; then
                echo -e "${RED}Failed to start $service for integration tests${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}Service $service is running${NC}"
        fi
    done
    
    # Run integration tests with optional filtering
    echo "Running integration tests..."
    if [ -n "$TESTS_PATTERN" ]; then
        echo "Using test filter pattern: $TESTS_PATTERN"
        if ! ./gradlew :bantora-api:test --tests "$TESTS_PATTERN" -Dspring.profiles.active=test; then
            echo -e "${RED}Integration tests failed${NC}"
            return 1
        fi
    else
        if ! ./gradlew :bantora-api:test -Dspring.profiles.active=test; then
            echo -e "${RED}Integration tests failed${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}Integration tests completed successfully${NC}"
    return 0
}

# Run Playwright UI tests
run_playwright_tests() {
    echo -e "${BLUE}Running Playwright UI tests...${NC}"
    
    # Load test environment for UI tests  
    source_test_env
    
    # Always restart test environment to fix authentication issues
    echo -e "${YELLOW}Restarting test environment to ensure clean state...${NC}"
    stop_test_environment
    start_test_environment
    
    # UI tests only need core services
    local ui_services=("bantora-database" "bantora-api" "bantora-web" "bantora-gateway")
    
    # Check if required services are running
    for service in "${ui_services[@]}"; do
        local container_name
        container_name=$(get_container_name_for_service "$service")
        local container_id=$(docker ps -q -f "name=^${container_name}$" 2>/dev/null || true)
        if [ -z "$container_id" ]; then
            echo -e "${YELLOW}Service $service is not running, starting it...${NC}"
            start_service "$service"
            if [ $? -ne 0 ]; then
                echo -e "${RED}Failed to start $service for UI tests${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}Service $service is running${NC}"
        fi
    done
    
    # Run Playwright tests with test profile
    echo "Running Playwright UI tests..."
    
    echo "Running Java Playwright tests..."
    
    if [ -n "$TESTS_PATTERN" ]; then
        ./gradlew :bantora-web:test --tests "$TESTS_PATTERN"
    else
        ./gradlew :bantora-web:test --no-build-cache --rerun-tasks
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Playwright tests failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Playwright tests completed successfully${NC}"
    return 0
}

# Clean setup test environment with full isolation
setup_clean_test_environment() {
    echo -e "${BLUE}Setting up clean test environment with full isolation...${NC}"
    
    # Load test environment variables
    source_test_env
    
    # Stop all dev containers to ensure no conflicts
    echo -e "${YELLOW}Stopping all dev containers to ensure clean test environment...${NC}"
    local dev_services=("bantora-gateway" "bantora-web" "bantora-api" "bantora-database")
    
    for service in "${dev_services[@]}"; do
        local container_id=$(docker ps -q -f "name=^${service}$" 2>/dev/null || true)
        if [ -n "$container_id" ]; then
            echo -e "${YELLOW}Stopping dev container: $service${NC}"
            docker stop "$service" >/dev/null 2>&1 || true
        fi
    done
    
    # Build and start test containers
    echo -e "${BLUE}Building and starting test containers...${NC}"
    local test_services=("bantora-database" "bantora-api" "bantora-web" "bantora-gateway")
    
    for service in "${test_services[@]}"; do
        echo -e "${BLUE}Setting up test service: $service${NC}"
        if ! execute_action "-rrr" "$service"; then
            echo -e "${RED}Failed to setup test service: $service${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Clean test environment setup completed successfully${NC}"
    show_test_environment_status
    return 0
}

# Show test environment status and conflicts
show_test_environment_status() {
    echo -e "${BLUE}Test Environment Status${NC}"
    echo "======================================="
    
    # Load test environment to get correct container names
    source_test_env >/dev/null 2>&1
    
    echo -e "${BOLD}Test Containers:${NC}"
    local test_services=("bantora-test-database" "bantora-test-api" "bantora-test-web" "bantora-test-gateway")
    
    for service in "${test_services[@]}"; do
        local container_id=$(docker ps -q -f "name=^${service}$" 2>/dev/null || true)
        if [ -n "$container_id" ]; then
            local ports=$(docker port "$service" 2>/dev/null | tr '\n' ' ' || "No ports")
            echo -e "  ✅ $service (${GREEN}running${NC}) - Ports: $ports"
        else
            echo -e "  ❌ $service (${RED}not running${NC})"
        fi
    done
    
    echo ""
    echo -e "${BOLD}Dev Containers:${NC}"
    local dev_services=("bantora-database" "bantora-api" "bantora-web" "bantora-gateway")
    
    for service in "${dev_services[@]}"; do
        local container_id=$(docker ps -q -f "name=^${service}$" 2>/dev/null || true)
        if [ -n "$container_id" ]; then
            local ports=$(docker port "$service" 2>/dev/null | tr '\n' ' ' || "No ports")
            echo -e "  ⚠️  $service (${YELLOW}running${NC}) - Ports: $ports"
        else
            echo -e "  ✅ $service (${GREEN}stopped${NC})"
        fi
    done
    
    echo ""
    echo -e "${BOLD}Port Conflicts:${NC}"
    local test_ports=("15432" "18091" "18080" "17083")
    local conflicts_found=false
    
    for port in "${test_ports[@]}"; do
        local usage=$(netstat -tlnp 2>/dev/null | grep ":${port} " || true)
        if [ -n "$usage" ]; then
            echo -e "  Port $port: ${YELLOW}IN USE${NC} - $usage"
            conflicts_found=true
        else
            echo -e "  Port $port: ${GREEN}AVAILABLE${NC}"
        fi
    done
    
    if [ "$conflicts_found" = false ]; then
        echo -e "  ${GREEN}No port conflicts detected${NC}"
    fi
    
    echo "======================================="
}

# Run all tests
run_all_tests() {
    echo -e "${BLUE}Running all test suites...${NC}"
    
    # Load test environment for all tests
    source_test_env
    
    local failed_tests=()
    
    # Run unit tests
    if ! run_unit_tests; then
        failed_tests+=("unit")
    fi
    
    # Run integration tests
    if ! run_integration_tests; then
        failed_tests+=("integration")
    fi
    
    # Run Playwright tests
    if ! run_playwright_tests; then
        failed_tests+=("playwright")
    fi
    
    # Report results
    if [ ${#failed_tests[@]} -eq 0 ]; then
        echo -e "${GREEN}All test suites passed successfully${NC}"
        return 0
    else
        echo -e "${RED}The following test suites failed: ${failed_tests[*]}${NC}"
        return 1
    fi
}

# =============================================================================
# MAIN
# =============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables first
source_env

# Default values
DETACH_MODE="true"
TESTS_PATTERN=""

# Parse command line arguments
while [ $# -gt 0 ]; do
    case $1 in
        -d|--detach)
            DETACH_MODE="true"
            shift
            ;;
        -a|--attach)
            DETACH_MODE="false"
            shift
            ;;
        --debug)
            set -x
            shift
            ;;
        --status)
            echo "Checking Bantora services..."
            for service in "${SERVICES[@]}"; do
                get_service_status "$service"
            done
            exit 0
            ;;
        --logs)
            shift
            service_for_logs=""
            tail_option="--tail=500"
            follow_option="" # Default to not following logs
            
            # Parse log options
            while [[ $# -gt 0 ]] && [[ "$1" == -* ]]; do
                case "$1" in
                    --tail)
                        if [ -z "$2" ] || [[ "$2" == -* ]]; then
                            echo -e "${RED}Error: --tail option requires a value (e.g., 'all' or a number).${NC}" >&2
                            exit 1
                        fi
                        tail_option="--tail=$2"
                        shift 2
                        ;;
                    -f|--follow)
                        follow_option="-f"
                        shift
                        ;;
                    *)
                        # Stop parsing if we hit a non-option argument
                        break
                        ;;
                esac
            done

            service_for_logs=$1
            if [ -z "$service_for_logs" ]; then
                echo -e "${RED}Error: Please specify a service for logs.${NC}"
                print_usage
                exit 1
            fi

            if is_valid_service "$service_for_logs"; then
                echo -e "${GREEN}Showing logs for $service_for_logs...${NC}"
                # If user specified --tail and also -f, re-add follow
                if [[ " $@ " =~ " -f " ]] || [[ " $@ " =~ " --follow " ]]; then
                    follow_option="-f"
                fi
                docker compose logs $follow_option $tail_option "$service_for_logs"
            else
                echo -e "${RED}Error: Invalid service '$service_for_logs'${NC}"
                print_usage
                exit 1
            fi
            exit 0
            ;;
        --exec)
            if [ $# -lt 3 ]; then
                echo -e "${RED}Error: Service name and command are required for --exec${NC}"
                exit 1
            fi
            service_to_exec_in=$2
            command_to_run="${@:3}"

            if ! is_valid_service "$service_to_exec_in"; then
                echo -e "${RED}Error: Invalid service name: $service_to_exec_in${NC}"
                exit 1
            fi

            container_name="bantora-${service_to_exec_in}"
            container_id=$(docker ps -q -f "name=^${container_name}$")

            if [ -z "$container_id" ]; then
                 container_name="${service_to_exec_in}"
                 container_id=$(docker ps -q -f "name=^${container_name}$")
            fi

            if [ -n "$container_id" ]; then
                echo -e "${BLUE}Executing command in $container_name...${NC}"
                docker exec "$container_id" /bin/bash -c "$command_to_run"
                exit $?
            else
                echo -e "${RED}Container for service '${service_to_exec_in}' not found or not running.${NC}"
                exit 1
            fi
            ;;
        --cleanup|--destroy-all)
            echo "Stopping and removing all services..."
            for service in "${SERVICES[@]}"; do
                stop_service "$service"
                remove_service "$service"
            done
            docker compose down
            echo -e "${GREEN}All containers stopped and removed${NC}"
            exit 0
            ;;
        --full-cleanup)
            echo "Stopping and removing all services..."
            for service in "${SERVICES[@]}"; do
                stop_service "$service"
                remove_service "$service"
            done
            echo "Pruning project-specific Docker resources..."
            # Remove only stopped bantora containers
            docker ps -a --filter "name=bantora" --filter "status=exited" -q | xargs -r docker rm 2>/dev/null || true
            # Remove dangling bantora images
            docker images --filter "dangling=true" --filter "reference=*bantora*" -q | xargs -r docker rmi 2>/dev/null || true
            # Remove unused bantora networks
            docker network ls --filter "name=bantora" -q | xargs -r docker network rm 2>/dev/null || true
            # Remove bantora volumes (if any)
            docker volume ls --filter "name=bantora" -q | xargs -r docker volume rm 2>/dev/null || true
            echo "Full cleanup completed."
            exit 0
            ;;
        --restart-all)
            echo -e "${BLUE}Restarting all services...${NC}"
            execute_action "-r" "${SERVICES[@]}"
            exit $?
            ;;
        --rebuild-all)
            echo -e "${BLUE}Rebuilding all services in dependency order...${NC}"
            execute_action "-rrr" "${SERVICES[@]}"
            exit $?
            ;;
        --test)
            shift
            test_type="$1"
            if [ -z "$test_type" ]; then
                test_type="all"
            fi
            shift
            
            # Continue parsing for --tests option before executing
            while [ $# -gt 0 ]; do
                case $1 in
                    --tests)
                        if [ -z "$2" ] || [[ "$2" == -* ]]; then
                            echo -e "${RED}Error: --tests option requires a pattern (e.g., fully qualified class)${NC}"
                            exit 1
                        fi
                        TESTS_PATTERN="$2"
                        shift 2
                        ;;
                    *)
                        echo -e "${RED}Error: Unknown option after --test: $1${NC}"
                        exit 1
                        ;;
                esac
            done
            
            case "$test_type" in
                "unit")
                    run_unit_tests
                    ;;
                "integration")
                    run_integration_tests
                    ;;
                "playwright")
                    run_playwright_tests
                    ;;
                "all")
                    run_all_tests
                    ;;
                *)
                    echo -e "${RED}Error: Invalid test type '$test_type'. Valid options: unit, integration, playwright, all${NC}"
                    exit 1
                    ;;
            esac
            exit $?
            ;;
        --tests)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --tests option requires a pattern (e.g., fully qualified class)${NC}"
                exit 1
            fi
            TESTS_PATTERN="$2"
            shift 2
            ;;
        --test-unit)
            run_unit_tests
            exit $?
            ;;
        --test-integration)
            run_integration_tests
            exit $?
            ;;
        --test-playwright)
            run_playwright_tests
            exit $?
            ;;
        --test-env-clean)
            setup_clean_test_environment
            exit $?
            ;;
        --test-env-status)
            show_test_environment_status
            exit $?
            ;;
        --test-env)
            shift
            test_env_action="$1"
            if [ -z "$test_env_action" ]; then
                test_env_action="status"
            fi
            shift
            
            case "$test_env_action" in
                "start"|"up")
                    start_test_environment
                    ;;
                "stop"|"down")
                    stop_test_environment
                    ;;
                "restart")
                    stop_test_environment
                    start_test_environment
                    ;;
                "status")
                    show_test_environment_status
                    ;;
                "reset")
                    reset_test_environment
                    ;;
                *)
                    echo -e "${RED}Error: Invalid test environment action '$test_env_action'. Valid options: start, stop, restart, status, reset${NC}"
                    exit 1
                    ;;
            esac
            exit $?
            ;;
        --test-multilang)
            shift
            multilang_test_type="$1"
            if [ -z "$multilang_test_type" ]; then
                multilang_test_type="all"
            fi
            shift
            
            case "$multilang_test_type" in
                "unit")
                    run_multilang_unit_tests
                    ;;
                "integration")
                    run_multilang_integration_tests
                    ;;
                "ui")
                    run_multilang_ui_tests
                    ;;
                "all")
                    run_multilang_all_tests
                    ;;
                *)
                    echo -e "${RED}Error: Invalid multi-language test type '$multilang_test_type'. Valid options: unit, integration, ui, all${NC}"
                    exit 1
                    ;;
            esac
            exit $?
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -r|-rr|-rrr|-rrrr|-rrrrr)
            action=$1
            shift
            
            # Parse remaining options and services
            action_detach_mode="$DETACH_MODE"
            target_services=()
            
            while [ $# -gt 0 ]; do
                case $1 in
                    -d|--detach)
                        action_detach_mode="true"
                        shift
                        ;;
                    -a|--attach)
                        action_detach_mode="false"
                        shift
                        ;;
                    -*)
                        echo -e "${RED}Error: Unknown option in action context: $1${NC}"
                        exit 1
                        ;;
                    *)
                        target_services+=("$1")
                        shift
                        ;;
                esac
            done
            
            if [ ${#target_services[@]} -eq 0 ]; then
                echo -e "${RED}Error: At least one service name required${NC}"
                exit 1
            fi
            
            # Set detach mode for this action
            DETACH_MODE="$action_detach_mode"
            
            # Validate all services before proceeding
            for service in "${target_services[@]}"; do
                if ! is_valid_service "$service"; then
                    echo -e "${RED}Error: Invalid service name: $service${NC}"
                    exit 1
                fi
            done
            
            execute_action "$action" "${target_services[@]}"
            exit $?
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# If we get here, no action was specified
print_usage
exit 1
