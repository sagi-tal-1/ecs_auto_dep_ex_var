#!/bin/bash

TEMP_CONFIG_PATH="/etc/nginx/conf.d/upstream.conf"

# Ensure the directory exists
mkdir -p "$(dirname "$TEMP_CONFIG_PATH")"

# Generate upstream configuration
{
  echo '# Auto-generated upstream configuration'
  echo 'upstream nodejs_backend {'
  container_index=1

  # Loop through containers and generate upstream entries
  readarray -t CONTAINERS < <(docker ps -q --filter label=service=nodejs)
  for container in "${CONTAINERS[@]}"; do
    HOST_PORT=$(docker port "$container" 3000 | head -n 1 | cut -d ":" -f 2)
    if [[ -n "$HOST_PORT" ]]; then
      echo "    server 127.0.0.1:$HOST_PORT max_fails=3 fail_timeout=30s;"
    fi
  done

  echo '    least_conn;'
  echo '    keepalive 32;'
  echo '}'

  # Add server block
  echo ''
  echo 'server {'
  echo '    listen 80 default_server;'
  echo '    server_name _;'
  echo '    error_log /var/log/nginx/error.log debug;'
  echo '    access_log /var/log/nginx/access.log combined;'
  echo '    location = /health {'
  echo '        access_log off;'
  echo '        add_header Content-Type text/plain;'
  echo "        return 200 'healthy';"
  echo '    }'
  echo '    location /nodejs/ {'
  echo '        proxy_pass http://nodejs_backend/;'
  echo '        proxy_http_version 1.1;'
  echo "        proxy_set_header Connection '';"
  echo '        proxy_set_header Host $host;'
  echo '        proxy_set_header X-Real-IP $remote_addr;'
  echo '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;'
  echo '        proxy_set_header X-Forwarded-Proto $scheme;'
  echo '        proxy_next_upstream error timeout http_500;'
  echo '        proxy_next_upstream_tries 3;'
  echo '        proxy_next_upstream_timeout 10s;'
  echo '    }'
  echo '}'
} > "$TEMP_CONFIG_PATH"
