#!/bin/bash
set -x

# Set default values
NODEJS_SERVICE_NAME="${NODEJS_SERVICE_NAME:-nodejs-service}"
DISCOVERY_INTERVAL="${DISCOVERY_INTERVAL:-30}"
TEMP_CONFIG_PATH="/etc/nginx/conf.d/upstream.conf"
SERVICE_LABEL="${SERVICE_LABEL:-service=nodejs}"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> /var/log/discover_containers.log
}

discover_containers() {
    log "Starting container discovery process"
    CONTAINERS=$(docker ps -q --filter "label=${SERVICE_LABEL}")

    if [ -z "$CONTAINERS" ]; then
        log "No containers found with label ${SERVICE_LABEL}"
        create_fallback_config
        return
    fi

    # Create temporary file
    {
        echo "# Auto-generated upstream configuration"
        
        # Create a general upstream for all containers
        echo "upstream nodejs_backend {"
        for container in $CONTAINERS; do
            CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
            if [ -n "$CONTAINER_IP" ]; then
                log "Adding backend: ${CONTAINER_IP}:3000"
                echo "    server ${CONTAINER_IP}:3000 max_fails=3 fail_timeout=30s;"
            fi
        done
        echo "    least_conn;"
        echo "    keepalive 32;"
        echo "}"

        # Create individual upstreams for specific routing
        COUNTER=1
        for container in $CONTAINERS; do
            CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
            if [ -n "$CONTAINER_IP" ]; then
                echo "upstream nodejs_backend_${COUNTER} {"
                echo "    server ${CONTAINER_IP}:3000;"
                echo "    keepalive 32;"
                echo "}"
                COUNTER=$((COUNTER + 1))
            fi
        done

        generate_server_config
    } > "$TEMP_CONFIG_PATH"

    # Test and reload nginx
    if nginx -t; then
        log "Nginx configuration test PASSED"
        nginx -s reload
        log "Nginx configuration RELOADED"
    else
        log "ERROR: Nginx configuration test FAILED"
        nginx -t >> /var/log/discover_containers.log
    fi
}

generate_server_config() {
    echo "server {"
    echo "    listen 80 default_server;"
    echo "    server_name _;"

    echo "    # Enable error logging"
    echo "    error_log /var/log/nginx/error.log debug;"
    echo "    access_log /var/log/nginx/access.log combined;"

    # Root location block
    echo "    location / {"
    echo "        proxy_pass http://nodejs_backend;"
    echo "        proxy_http_version 1.1;"
    echo "        proxy_set_header Connection '';"
    echo "        proxy_set_header Host \$host;"
    echo "        proxy_set_header X-Real-IP \$remote_addr;"
    echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
    echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
    echo "    }"

    # Health check location
    echo "    location = /health {"
    echo "        access_log off;"
    echo "        add_header Content-Type text/plain;"
    echo "        return 200 'healthy';"
    echo "    }"

    # NodeJS general routing
    echo "    location /nodejs {"
    echo "        proxy_pass http://nodejs_backend;"
    echo "        proxy_http_version 1.1;"
    echo "        proxy_set_header Connection '';"
    echo "        proxy_set_header Host \$host;"
    echo "        proxy_set_header X-Real-IP \$remote_addr;"
    echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
    echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
    echo "    }"

    # Specific container routing - simplified version
    echo "    location ~ ^/nodejs-([0-9]+) {"
    echo "        proxy_pass http://nodejs_backend_\$1;"
    echo "        proxy_http_version 1.1;"
    echo "        proxy_set_header Connection '';"
    echo "        proxy_set_header Host \$host;"
    echo "        proxy_set_header X-Real-IP \$remote_addr;"
    echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
    echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
    echo "    }"

    # Close the server block
    echo "}"
}

create_fallback_config() {
    {
        echo "# Fallback configuration - No backends available"
        echo "upstream nodejs_backend {"
        echo "    server 127.0.0.1:8080 down; # Placeholder server"
        echo "}"

        echo "server {"
        echo "    listen 80 default_server;"
        echo "    server_name _;"

        echo "    location = /health {"
        echo "        access_log off;"
        echo "        add_header Content-Type text/plain;"
        echo "        return 200 'healthy';"
        echo "    }"

        echo "    location / {"
        echo "        return 503 'Service Temporarily Unavailable';"
        echo "    }"
        echo "}"
    } > "$TEMP_CONFIG_PATH"
}

# Handle signals
trap 'log "Received SIGTERM, exiting..."; exit 0' SIGTERM
trap 'log "Received SIGINT, exiting..."; exit 0' SIGINT

# Main loop
while true; do
    discover_containers
    log "Sleeping for ${DISCOVERY_INTERVAL} seconds"
    sleep "$DISCOVERY_INTERVAL"
done