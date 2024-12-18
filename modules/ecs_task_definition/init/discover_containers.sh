!/bin/bash
set -x

# Set default values
ECS_CLUSTER="${ECS_CLUSTER:-demo-cluster-b24edafc}"
NODEJS_SERVICE_NAME="${NODEJS_SERVICE_NAME:-ECS_service-ecs-service-node-b24edafc}"
DISCOVERY_INTERVAL="${DISCOVERY_INTERVAL:-30}"
TEMP_CONFIG_PATH="/etc/nginx/conf.d/upstream.conf"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> /var/log/discover_containers.log
}

discover_containers() {
    log "Starting container discovery process"

    # Get tasks
    TASKS=$(aws ecs list-tasks \
        --cluster "$ECS_CLUSTER" \
        --service-name "$NODEJS_SERVICE_NAME" \
        --region "$REGION" \
        --query 'taskArns[]' \
        --output text)

    if [ -z "$TASKS" ]; then
        log "No tasks found"
        return 1
    fi

    # Generate Nginx configuration
    {
        echo "# Auto-generated upstream configuration"
        echo "upstream nodejs_backend {"
        echo "    server 10.0.2.176:3000 max_fails=3 fail_timeout=30s;"
        echo "}"

        echo "server {"
        echo "    listen 80;"
        echo "    server_name _;"

        echo "    # Enable error logging"
        echo "    error_log /var/log/nginx/error.log debug;"
        echo "    access_log /var/log/nginx/access.log combined;"
 Get task IDs for specific routes
        echo "$TASKS" | tr ' ' '\n' | while read -r task; do
            TASK_ID=$(echo "$task" | awk -F'/' '{print $NF}')
            if [ -n "$TASK_ID" ]; then
                echo "    location = /$TASK_ID {"
                echo "        proxy_pass http://nodejs_backend/$TASK_ID;"
                echo "        proxy_http_version 1.1;"
                echo "        proxy_set_header Host \$host;"
                echo "        proxy_set_header X-Real-IP \$remote_addr;"
                echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
                echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
                echo "        proxy_connect_timeout 5s;"
                echo "        proxy_send_timeout 5s;"
                echo "        proxy_read_timeout 5s;"
                echo "    }"
            fi
        done

        # Health check endpoint
        echo "    location = /health {"
        echo "        proxy_pass http://nodejs_backend/health;"
        echo "        proxy_http_version 1.1;"
        echo "        proxy_set_header Host \$host;"
        echo "        proxy_set_header X-Real-IP \$remote_addr;"
        echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
        echo "        proxy_connect_timeout 5s;"
        echo "        proxy_send_timeout 5s;"
        echo "        proxy_read_timeout 5s;"
        echo "    }"

        # Default location
        echo "    location / {"
        echo "        proxy_pass http://nodejs_backend/;"
        echo "        proxy_http_version 1.1;"
        echo "        proxy_set_header Host \$host;"
        echo "        proxy_set_header X-Real-IP \$remote_addr;"
        echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
        echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
        echo "        proxy_connect_timeout 5s;"
        echo "        proxy_send_timeout 5s;"
        echo "        proxy_read_timeout 5s;"
        echo "        proxy_buffers 8 16k;"
        echo "        proxy_buffer_size 32k;"
        echo "    }"
        echo "}"
    } > "$TEMP_CONFIG_PATH"
    # Log the generated configuration
    log "Generated Nginx configuration:"
    cat "$TEMP_CONFIG_PATH" >> /var/log/discover_containers.log

    # Test and reload nginx
    if nginx -t; then
        log "Nginx configuration test PASSED"
        nginx -s reload
        log "Nginx configuration RELOADED"
    else
        log "ERROR: Nginx configuration test FAILED"
        nginx -t >> /var/log/discover_containers.log 2>&1
    fi
}

# Create log directories
mkdir -p /var/log/nginx

# Main execution
discover_containers

# Main discovery loop
while true; do
    log "Sleeping for $DISCOVERY_INTERVAL seconds"
    sleep "$DISCOVERY_INTERVAL"
    discover_containers
done