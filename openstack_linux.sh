#!/bin/bash

# Production-Grade Single Node OpenStack Installation

# Detect package manager and set variables
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

# Set environment variables (Replace with actual production values)****************
MYSQL_ROOT_PASS="ReplaceWithSecurePassword"
RABBIT_PASS="ReplaceWithSecureRabbitMQPassword"
ADMIN_PASS="ReplaceWithSecureAdminPassword"
MY_IP="ReplaceWithServerIP"

# Install dependencies
sudo $INSTALL_CMD python3-dev python3-pip libffi-dev gcc libssl-dev crudini memcached

# Install OpenStack client
sudo pip3 install python-openstackclient

# Secure MySQL installation
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASS"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASS"
sudo $INSTALL_CMD mysql-server

# Configure MySQL for better performance and remote access
sudo sed -i "/^bind-address/s/127.0.0.1/0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# Install and configure RabbitMQ
sudo $INSTALL_CMD rabbitmq-server
sudo rabbitmqctl add_user openstack $RABBIT_PASS
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Install and configure Keystone
sudo $INSTALL_CMD keystone
sudo cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig
sudo crudini --set /etc/keystone/keystone.conf database connection "mysql+pymysql://keystone:$MYSQL_ROOT_PASS@localhost/keystone"

# Configure Keystone authentication
sudo crudini --set /etc/keystone/keystone.conf token provider fernet

# Bootstrap Keystone
sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo su -s /bin/sh -c "keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone" keystone
sudo su -s /bin/sh -c "keystone-manage credential_setup --keystone-user keystone --keystone-group keystone" keystone
sudo su -s /bin/sh -c "keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://$MY_IP:5000/v3/ \
  --bootstrap-internal-url http://$MY_IP:5000/v3/ \
  --bootstrap-public-url http://$MY_IP:5000/v3/ \
  --bootstrap-region-id RegionOne" keystone

# Configure Apache for Keystone
sudo $INSTALL_CMD apache2 libapache2-mod-wsgi-py3
sudo crudini --set /etc/apache2/apache2.conf Global ServerName $MY_IP
sudo systemctl restart apache2

# Set Keystone environment variables (Replace with actual admin credentials)**************
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$MY_IP:5000/v3
export OS_IDENTITY_API_VERSION=3

# Install and configure Glance
sudo $INSTALL_CMD glance
sudo cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig
sudo crudini --set /etc/glance/glance-api.conf database connection "mysql+pymysql://glance:$MYSQL_ROOT_PASS@localhost/glance"
sudo glance-manage db_sync

# Restart Glance services
sudo systemctl restart glance-api

# Install and configure Nova
sudo $INSTALL_CMD nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-placement-api nova-compute
sudo cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
sudo crudini --set /etc/nova/nova.conf database connection "mysql+pymysql://nova:$MYSQL_ROOT_PASS@localhost/nova"
sudo crudini --set /etc/nova/nova.conf DEFAULT transport_url "rabbit://openstack:$RABBIT_PASS@localhost"
sudo crudini --set /etc/nova/nova.conf DEFAULT my_ip "$MY_IP"
sudo nova-manage api_db sync

# Enable and restart services
sudo systemctl enable mysql rabbitmq-server apache2 memcached
sudo systemctl restart mysql rabbitmq-server apache2 memcached

# Print completion message
echo "Production-grade OpenStack single-node deployment completed successfully."
