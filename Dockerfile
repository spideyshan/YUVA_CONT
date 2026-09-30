FROM alpine:3.18

# Install OpenSSH server, bash, and shadow
RUN apk update && \
    apk add --no-cache openssh-server bash shadow && \
    mkdir -p /var/run/sshd

# Configure SSH daemon: allow password auth, disallow root login (player uses 'ctf' user)
RUN sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config && \
    echo "" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "KbdInteractiveAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config

# Create the non-privileged 'ctf' login user with default password 'ctf'
RUN adduser -D -s /bin/bash ctf && \
    echo "ctf:ctf" | chpasswd

# Working directory for the player
WORKDIR /home/ctf

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose standard SSH port
EXPOSE 22

# Start using the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
