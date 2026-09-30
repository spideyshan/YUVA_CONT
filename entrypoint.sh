#!/bin/sh

# 1. Generate SSH host keys dynamically if they do not exist
ssh-keygen -A

# 2. Grab variables injected by the platform (with aliases / fallbacks).
#    Default flag is YUVA{event_is_good} for local runs; the platform can
#    override it per-instance via CHALLENGE_FLAG / FLAG / DYNAMIC_FLAG.
USER="${SSH_USER:-${SHELL_USER:-${USER_NAME:-${USERNAME:-ctf}}}}"
PASS="${SSH_PASSWORD:-${SHELL_PASSWORD:-${PASSWORD:-${USER_PASSWORD:-ctf}}}}"
FLAG_VAL="${CHALLENGE_FLAG:-${FLAG:-${DYNAMIC_FLAG:-YUVA{event_is_good}}}}"

# 3. Create the login user if it does not already exist
if ! id "$USER" >/dev/null 2>&1; then
    echo "[Entrypoint] Creating user account: $USER"
    adduser -D -s /bin/bash "$USER" 2>/dev/null || useradd -m -s /bin/bash "$USER" 2>/dev/null
fi
echo "$USER:$PASS" | chpasswd

# 4. Plant the flag INSIDE the container only.
#    A short breadcrumb sits in the home directory; the flag itself lives in a
#    hidden vault that only the player's user can read.
HOME_DIR="/home/$USER"
mkdir -p "$HOME_DIR" /opt/.vault

echo "$FLAG_VAL" > /opt/.vault/flag.txt
chown "$USER":"$USER" /opt/.vault/flag.txt
chmod 400 /opt/.vault/flag.txt

cat > "$HOME_DIR/README.txt" <<'EOF'
Welcome, challenger.

The vault key you seek is not in this room, but it is close.
Somewhere on this machine a hidden vault holds what you need.
Tools like `find`, `grep`, and `ls -la` are your friends.

Hint: search the filesystem for files you own that others cannot read.
EOF
chown "$USER":"$USER" "$HOME_DIR/README.txt"
chmod 644 "$HOME_DIR/README.txt"

# 5. Ensure SSH allows password login for the player and keeps root login off
sed -i '/^#*PasswordAuthentication/d' /etc/ssh/sshd_config 2>/dev/null || true
sed -i '/^#*PermitRootLogin/d' /etc/ssh/sshd_config 2>/dev/null || true
sed -i '/^#*KbdInteractiveAuthentication/d' /etc/ssh/sshd_config 2>/dev/null || true
sed -i '/^#*UsePAM/d' /etc/ssh/sshd_config 2>/dev/null || true

echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "KbdInteractiveAuthentication yes" >> /etc/ssh/sshd_config
echo "UsePAM no" >> /etc/ssh/sshd_config

# 6. Unset sensitive environment variables so players can't read them from
#    /proc/self/environ or `env`
unset SSH_PASSWORD SHELL_PASSWORD PASSWORD USER_PASSWORD
unset SSH_USER SHELL_USER USER_NAME USERNAME
unset FLAG CHALLENGE_FLAG DYNAMIC_FLAG FLAG_VAL

echo "[Entrypoint] SSH challenge ready. Login user: $USER"

# 7. Start SSH daemon in the foreground
exec /usr/sbin/sshd -D -e
