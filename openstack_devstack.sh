#!/bin/bash

# Determine the package manager
if [ -f /etc/debian_version ]; then
    PKG_MANAGER="apt-get"
    UPDATE_CMD="apt-get update"
    INSTALL_CMD="apt-get install -y"
elif [ -f /etc/redhat-release ]; then
    PKG_MANAGER="yum"
    UPDATE_CMD="yum update -y"
    INSTALL_CMD="yum install -y"
else
    echo "Unsupported Linux distribution"
    exit 1
fi

# Update the system
sudo $UPDATE_CMD

# Install dependencies
sudo $INSTALL_CMD git curl wget vim

# Create a stack user
sudo useradd -s /bin/bash -d /opt/stack -m stack
sudo echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

# Switch to the stack user
sudo su - stack <<EOF

# Clone DevStack repository
git clone https://opendev.org/openstack/devstack.git
cd devstack

# Create local.conf configuration file
cat <<EOL > local.conf
[[local|localrc]]
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=\$ADMIN_PASSWORD
RABBIT_PASSWORD=\$ADMIN_PASSWORD
SERVICE_PASSWORD=\$ADMIN_PASSWORD
EOL

# Run stack.sh to deploy OpenStack
./stack.sh
EOF

# Print completion message
echo "OpenStack deployment completed. Access the dashboard at http://<your-ip>/dashboard with username 'admin' and password 'secret'"
