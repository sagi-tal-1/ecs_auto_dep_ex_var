 #!/bin/bash
set -e

# Set default values
SERVICE_LABEL="${SERVICE_LABEL:-service=nodejs}"
SERVICE_IDENTITY="${SERVICE_IDENTITY:-service_Identity}"
NGINX_CONFIG_DIR="/etc/nginx/conf.d"
TEMP_CONFIG_PATH="${NGINX_CONFIG_DIR}/upstream.conf"

# Ensure required directories exist
mkdir -p /var/log/discovery
mkdir -p "$NGINX_CONFIG_DIR"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a /var/log/discovery/service.log
}

# Function to update Nginx configuration
update_nginx_config() {
    local CONTAINERS=$1
    
    {
        echo "# Auto-generated upstream configuration"
        echo "upstream ${SERVICE_IDENTITY} {"
        echo "    least_conn;"
        
        for container in $CONTAINERS; do
            IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
            echo "    server ${IP}:3000;"
        done
        echo "}"
        
        # Individual container upstreams
        local counter=1
        for container in $CONTAINERS; do
            IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
            echo
            echo "upstream ${SERVICE_IDENTITY}${counter} {"
            echo "    server ${IP}:3000;"
            echo "}"
            counter=$((counter + 1))
        done
    } > "${NGINX_CONFIG_DIR}/upstream.conf"
    
    {
        echo "server {"
        echo "    listen 80;"
        echo "    server_name _;"
        
        echo "    # Root path - load balanced"
        echo "    location / {"
        echo "        proxy_pass http://${SERVICE_IDENTITY};"
        echo "        proxy_http_version 1.1;"
        echo "        proxy_set_header Connection '';"
        echo "        proxy_set_header Host \$host;"
        echo "        proxy_set_header X-Real-IP \$remote_addr;"
        echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
        echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
        echo "    }"
        
        # Individual container locations
        local counter=1
        for container in $CONTAINERS; do
            echo
            echo "    # Container ${counter} direct access"
            echo "    location ~ ^/service_Identity${counter}(/|$) {"
            echo "        rewrite ^/service_Identity${counter}(/?(.*))$ /\$2 break;"
            echo "        proxy_pass http://${SERVICE_IDENTITY}${counter};"
            echo "        proxy_http_version 1.1;"
            echo "        proxy_set_header Connection '';"
            echo "        proxy_set_header Host \$host;"
            echo "        proxy_set_header X-Real-IP \$remote_addr;"
            echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
            echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
            echo "    }"
            counter=$((counter + 1))
        done
        
        echo "}"
    } > "${NGINX_CONFIG_DIR}/default.conf"
}

# Main loop
while true; do
    log "Starting service discovery..."
    
    # Get current containers
    CONTAINERS=$(docker ps -q --filter "label=${SERVICE_LABEL}")
    
    if [ -n "$CONTAINERS" ]; then
        log "Found containers: $CONTAINERS"
        update_nginx_config "$CONTAINERS"
        
        # Test and reload nginx
        if nginx -t; then
            log "Nginx configuration test passed"
            nginx -s reload
            log "Nginx configuration reloaded"
        else
            log "Nginx configuration test failed"
        fi
    else
        log "No containers found with label ${SERVICE_LABEL}"
    fi
    
    # Wait before next check
    sleep 30
done