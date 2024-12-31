#!/bin/bash

# Configuration
DISCOVERY_INTERVAL=30
TEMP_CONFIG_PATH="/etc/nginx/conf.d/upstream.conf"
LOG_FILE="/var/log/discover_containers.log"
SERVICE_NAME="node"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

discover_containers() {
    log "Starting container discovery process"
    
    # First collect all container information
    declare -a BACKENDS=()
    
    for CONTAINER_ID in $(docker ps -q -f "name=${SERVICE_NAME}"); do
        CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_ID")
        CONTAINER_PORT=$(docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{if eq $p "3000/tcp"}}{{(index $conf 0).HostPort}}{{end}}{{end}}' "$CONTAINER_ID")
        
        if [ ! -z "$CONTAINER_IP" ]; then
            BACKENDS+=("${CONTAINER_IP}:3000")
            log "Found backend: ${CONTAINER_IP}:3000"
        fi
    done
    
    # Then generate the configuration file
    {
        echo "# Auto-generated upstream configuration"
        echo "upstream nodejs_backend {"
        echo "    least_conn;"
        echo "    keepalive 32;"
        
        for BACKEND in "${BACKENDS[@]}"; do
            echo "    server ${BACKEND} max_fails=3 fail_timeout=30s;"
        done
        
        echo "}"
        
        cat << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Enable error logging
    error_log /var/log/nginx/error.log debug;
    access_log /var/log/nginx/access.log combined;

    location = /health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 'healthy';
    }

    location / {
        proxy_pass http://nodejs_backend/;
        proxy_http_version 1.1;
        proxy_set_header Connection '';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_next_upstream error timeout http_500;
        proxy_next_upstream_tries 3;
        proxy_next_upstream_timeout 10s;
        proxy_connect_timeout 5s;
        proxy_send_timeout 5s;
        proxy_read_timeout 5s;
        proxy_buffers 8 16k;
        proxy_buffer_size 32k;
    }
}
EOF
    } > "$TEMP_CONFIG_PATH"

    log "Generated new nginx configuration"
    
    if nginx -t; then
        nginx -s reload
        log "Nginx configuration test PASSED"
        log "Nginx configuration RELOADED"
    else
        log "Nginx configuration test FAILED"
        return 1
    fi
}

# Main loop
while true; do
    discover_containers
    log "Sleeping for $DISCOVERY_INTERVAL seconds"
    sleep "$DISCOVERY_INTERVAL"
done