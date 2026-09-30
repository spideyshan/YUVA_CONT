#!/bin/sh
# Optional entrypoint. The flag, README, and banner are already baked into the
# image at build time, so the challenge works even if the platform launches
# sshd directly and never runs this script. If it IS run, it regenerates host
# keys and (optionally) lets you override the flag for a specific instance.

# 1. Generate SSH host keys dynamically if they do not exist
ssh-keygen -A

# 2. Optional flag override. Defaults to the baked-in static flag.
FLAG_VAL="${CHALLENGE_FLAG:-${FLAG:-YUVA{event_is_good}}}"

# 3. (Re)plant the flag in the hidden vault, owned by and readable only by ctf
mkdir -p /opt/.vault
echo "$FLAG_VAL" > /opt/.vault/flag.txt
chown ctf:ctf /opt/.vault/flag.txt
chmod 400 /opt/.vault/flag.txt

# 4. Scrub the flag out of the environment before sshd starts
unset FLAG CHALLENGE_FLAG DYNAMIC_FLAG FLAG_VAL

echo "[Entrypoint] SSH challenge ready. Login: ctf / ctf"

# 5. Start SSH daemon in the foreground
exec /usr/sbin/sshd -D -e
