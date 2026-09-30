#!/bin/sh
# solve.sh — automated reference solution for the SSH challenge.
# SSHes in as the player, locates the hidden vault, and prints the flag.
# Usage: ./solve.sh [host_port]
#   host_port  Host port the challenge is mapped to (default: 2222)

set -e

HOST="localhost"
PORT="${1:-2222}"
USER="ctf"
PASS="ctf"

# Need sshpass for non-interactive password auth
if ! command -v sshpass >/dev/null 2>&1; then
    echo "[solve] 'sshpass' is required. Install it, e.g.:"
    echo "        Debian/Ubuntu: sudo apt-get install -y sshpass"
    echo "        Alpine:        apk add sshpass"
    echo "        macOS:         brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -p ${PORT}"

echo "[solve] Connecting to ${USER}@${HOST}:${PORT} ..."

# Solution steps, run remotely over SSH:
#   1. Read the breadcrumb README in the home directory.
#   2. Search the filesystem for files owned by us that others can't read.
#   3. Read the flag out of the hidden vault.
FLAG=$(sshpass -p "$PASS" ssh $SSH_OPTS "${USER}@${HOST}" '
    echo "[remote] --- README ---";
    cat ~/README.txt 2>/dev/null;
    echo "[remote] --- searching for owned, private files ---";
    HIT=$(find / -type f -user "$(id -un)" -perm -0400 ! -perm -0044 2>/dev/null | grep -i vault | head -n1);
    echo "[remote] found: $HIT";
    cat "$HIT";
')

echo "$FLAG"

# Extract and verify the flag format
FOUND=$(printf "%s\n" "$FLAG" | grep -oE "YUVA\{[^}]*\}" | head -n1)

echo ""
if [ -n "$FOUND" ]; then
    echo "[solve] SUCCESS — flag captured: $FOUND"
    exit 0
else
    echo "[solve] FAILED — flag not found. Is the container running on port ${PORT}?"
    exit 1
fi
