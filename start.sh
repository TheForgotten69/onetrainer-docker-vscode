#!/bin/bash
set -e # Exit the script if any statement returns a non-true return value
echo "Pod Started"

# Start NGINX service
echo "Starting NGINX service..."
service nginx start

# Setup SSH
echo "Setting up SSH Keys..."
if [[ -n $PUBLIC_KEY ]]; then
    echo "Setting up SSH..."
    mkdir -p ~/.ssh
    echo "$PUBLIC_KEY" >>~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys

    # Generate all missing SSH keys
    ssh-keygen -A

    service ssh start

    echo "SSH host keys:"
    for key in /etc/ssh/*.pub; do
        echo "Key: $key"
        ssh-keygen -lf $key
    done
fi

# Export environment variables
echo "Exporting environment variables..."
printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >>/etc/rp_environment
echo 'source /etc/rp_environment' >>~/.bashrc

# Execute post start script if exists
if [[ -f /post_start.sh ]]; then
    echo "Running post-start script..."
    bash /post_start.sh
fi

echo "Start script finished, pod is ready to use."

sleep infinity
