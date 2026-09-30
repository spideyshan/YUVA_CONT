#!/bin/sh
# setup.sh — build and launch the SSH challenge container.
# Usage: ./setup.sh [host_port]
#   host_port  Host port to map to the container's SSH (default: 2222)

set -e

IMAGE_NAME="ssh_challenge"
CONTAINER_NAME="ssh_challenge_instance"
HOST_PORT="${1:-2222}"

# Flag stays inside the container. Override per-instance if your platform
# injects a dynamic flag; otherwise the built-in default is used.
FLAG_VALUE="${CHALLENGE_FLAG:-YUVA{event_is_good}}"

echo "[setup] Building image '$IMAGE_NAME'..."
docker build -t "$IMAGE_NAME" .

# Remove any previous instance
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[setup] Removing existing container '$CONTAINER_NAME'..."
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

echo "[setup] Starting container '$CONTAINER_NAME' on host port $HOST_PORT..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${HOST_PORT}:22" \
    -e CHALLENGE_FLAG="$FLAG_VALUE" \
    "$IMAGE_NAME"

echo ""
echo "[setup] Challenge is up!"
echo "        SSH:      ssh ctf@localhost -p ${HOST_PORT}"
echo "        Password: ctf"
echo "        Stop:     docker rm -f ${CONTAINER_NAME}"
