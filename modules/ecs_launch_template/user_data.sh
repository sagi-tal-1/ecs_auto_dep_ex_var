#!/bin/bash

# Configure ECS Agent
cat <<'ECSCONFIG' >> /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_ENGINE_AUTH_TYPE=docker
ECS_ENGINE_AUTH_DATA={"https://index.docker.io/v1/":{"username":"${dockerhub_username}","password":"${dockerhub_password}","email":"email@example.com"}}
ECS_LOGLEVEL=debug
ECS_WARM_POOLS_CHECK=true
ECS_CONTAINER_METADATA_URI_ENDPOINT=v4
ECSCONFIG

# Configure Docker Daemon
cat <<'DOCKERCONFIG' >/etc/docker/daemon.json
{
    "debug": true,
    "userland-proxy": false
}
DOCKERCONFIG

# Restart Docker daemon
systemctl restart docker --no-block
