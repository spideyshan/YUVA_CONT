FROM alpine:3.18

# Install OpenSSH server, bash, and shadow
RUN apk update && \
    apk add --no-cache openssh-server bash shadow && \
    mkdir -p /var/run/sshd

# Configure SSH daemon: allow password auth, disallow root login (player uses 'ctf'),
# and show the story banner on connect.
RUN sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config && \
    echo "" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "KbdInteractiveAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "Banner /etc/ssh/banner.txt" >> /etc/ssh/sshd_config

# Create the non-privileged 'ctf' login user with password 'ctf'
RUN adduser -D -s /bin/bash ctf && \
    echo "ctf:ctf" | chpasswd

# --- Plant the flag INSIDE the image at BUILD time (survives entrypoint being bypassed) ---
# The flag lives in a hidden vault only the 'ctf' user can read.
RUN mkdir -p /opt/.vault && \
    echo "YUVA{event_is_good}" > /opt/.vault/flag.txt && \
    chown ctf:ctf /opt/.vault/flag.txt && \
    chmod 400 /opt/.vault/flag.txt

# Breadcrumb note in the player's home directory
RUN printf '%s\n' \
    "Welcome, challenger." \
    "" \
    "The vault key you seek is not in this room, but it is close." \
    "Somewhere on this machine a hidden vault holds what you need." \
    "Tools like \`find\`, \`grep\`, and \`ls -la\` are your friends." \
    "" \
    "Hint: search the filesystem for files you own that others cannot read." \
    > /home/ctf/README.txt && \
    chown ctf:ctf /home/ctf/README.txt && \
    chmod 644 /home/ctf/README.txt

# Story banner shown at SSH login
RUN printf '%s\n' \
    "===============================================================" \
    "                   YUVA CTF :: The Forgotten Vault" \
    "===============================================================" \
    "A decommissioned server was never wiped. The old admin vanished" \
    "after the last event, leaving one low-privilege account behind" \
    "and a rumor: the master vault key is still stashed on this box," \
    "locked so tightly that only its owner can ever read it." \
    "" \
    "Follow his trail. Recover the key." \
    "===============================================================" \
    > /etc/ssh/banner.txt

# Working directory for the player
WORKDIR /home/ctf

# Copy the (optional) entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose standard SSH port
EXPOSE 22

# If the platform honors the entrypoint, it re-affirms setup and starts sshd.
# If the platform launches sshd itself, the flag/README/banner are already baked in.
ENTRYPOINT ["/entrypoint.sh"]
