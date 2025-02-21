# OpenStack Deployment Scripts

## Overview
This repository contains two methods for deploying OpenStack on a single-node Ubuntu or RHEL-based system:

1. **Manual OpenStack Installation Script** (`openstack_install.sh`)
   - Installs OpenStack components manually, including Keystone, Glance, Nova, MySQL, and RabbitMQ.
   - Suitable for detailed configuration and production-like environments.

2. **DevStack Installation Script** (`devstack_install.sh`)
   - Deploys OpenStack using DevStack, which is ideal for testing and development.
   - Automatically sets up OpenStack with minimal configuration effort.

## System Requirements
- A fresh installation of **Ubuntu 20.04+** or **RHEL 8+/CentOS 8+**
- At least **8GB RAM** and **50GB Disk Space**
- A stable internet connection

## Installation Steps

### 1. Manual OpenStack Installation
This method provides full control over the installation process, configuring each component individually.

#### Usage:
```bash
chmod +x openstack_install.sh
sudo ./openstack_install.sh
```

#### Components Installed:
- **Keystone (Identity Service)**
- **Glance (Image Service)**
- **Nova (Compute Service)**
- **MySQL (Database Backend)**
- **RabbitMQ (Messaging Service)**

#### Configuration Details:
- The script automatically detects the package manager (**APT** for Ubuntu/Debian, **YUM** for RHEL/CentOS) and installs required dependencies accordingly.
- You **must** replace the following placeholders in `openstack_install.sh` with your production values before running:
  ```bash
  MYSQL_ROOT_PASS="ReplaceWithSecurePassword"
  RABBIT_PASS="ReplaceWithSecureRabbitMQPassword"
  ADMIN_PASS="ReplaceWithSecureAdminPassword"
  MY_IP="ReplaceWithServerIP"
  ```
- Default Keystone admin credentials:
  ```bash
  export OS_USERNAME=admin
  export OS_PASSWORD=ReplaceWithSecureAdminPassword
  export OS_PROJECT_NAME=admin
  export OS_USER_DOMAIN_NAME=Default
  export OS_PROJECT_DOMAIN_NAME=Default
  export OS_AUTH_URL=http://ReplaceWithServerIP:5000/v3
  export OS_IDENTITY_API_VERSION=3
  ```
- The script configures **Apache, MySQL, and RabbitMQ** for production-grade performance.
- Services like **Keystone, Glance, Nova** are enabled and restarted automatically after installation.

### 2. DevStack Installation
DevStack is a fast way to deploy OpenStack for testing and development.

#### Usage:
```bash
chmod +x devstack_install.sh
./devstack_install.sh
```

#### Notes:
- This script installs DevStack with default configurations.
- It requires a **non-root user with sudo privileges**.
- Configuration settings can be adjusted in the `local.conf` file before running the script.

## Deployment Type
- **Single-Node Deployment**: Both scripts set up OpenStack on a single machine, suitable for testing and small-scale deployments.

## Troubleshooting
- Check logs for errors:
  ```bash
  sudo journalctl -u apache2 --no-pager | tail -n 50
  sudo systemctl status mysql rabbitmq-server keystone glance-api nova-api
  ```
- Verify Keystone is working:
  ```bash
  openstack token issue
  ```
- Restart services if needed:
  ```bash
  sudo systemctl restart apache2 mysql rabbitmq-server keystone glance-api nova-api
  ```

## License
This repository is licensed under the MIT License. See `LICENSE` for details.

## Disclaimer
These scripts are intended for **educational and testing purposes only**. They may not be suitable for production environments without additional security and optimization steps.
