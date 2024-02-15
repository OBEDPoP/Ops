#!/bin/bash

# Update package index
sudo apt update

# Install basic dependencies
sudo apt install -y python3-dev python3-pip libffi-dev gcc libssl-dev crudini

# Install OpenStack client
sudo pip3 install python-openstackclient

# Install MySQL server and configure
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password 0penstack'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password 0penstack'
sudo apt install -y mysql-server

# Install RabbitMQ server
sudo apt install -y rabbitmq-server

# Install and configure Keystone
sudo apt install -y keystone
sudo cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig

# Configure Keystone database
sudo crudini --set /etc/keystone/keystone.conf database connection "mysql+pymysql://keystone:0penstack@localhost/keystone"

# Configure RabbitMQ
sudo crudini --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_host localhost
sudo crudini --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_userid openstack
sudo crudini --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_password 0penstack

# Bootstrap Keystone
sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo su -s /bin/sh -c "keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone" keystone
sudo su -s /bin/sh -c "keystone-manage credential_setup --keystone-user keystone --keystone-group keystone" keystone
sudo su -s /bin/sh -c "keystone-manage bootstrap --bootstrap-password 0penstack \
  --bootstrap-admin-url http://localhost:5000/v3/ \
  --bootstrap-internal-url http://localhost:5000/v3/ \
  --bootstrap-public-url http://localhost:5000/v3/ \
  --bootstrap-region-id RegionOne" keystone

# Configure Apache for Keystone
sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.orig
sudo cp /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-available/wsgi-keystone.conf.orig

sudo crudini --set /etc/apache2/apache2.conf Global ServerName localhost
sudo crudini --set /etc/apache2/sites-available/000-default.conf VirtualHost "ServerName localhost\nServerAdmin webmaster@localhost"
sudo crudini --set /etc/apache2/sites-available/wsgi-keystone.conf VirtualHost "ServerName localhost"

sudo service apache2 restart

# Set Keystone environment variables
export OS_USERNAME=admin
export OS_PASSWORD=0penstack
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://localhost:5000/v3
export OS_IDENTITY_API_VERSION=3

# Install and configure Glance
sudo apt install -y glance
sudo cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig

sudo crudini --set /etc/glance/glance-api.conf database connection "mysql+pymysql://glance:0penstack@localhost/glance"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri "http://localhost:5000"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url "http://localhost:5000"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers "localhost:11211"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type "password"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name "Default"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name "Default"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name "service"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken username "glance"
sudo crudini --set /etc/glance/glance-api.conf keystone_authtoken password "0penstack"

sudo glance-manage db_sync

# Restart Glance services
sudo service glance-api restart
sudo service glance-registry restart

# Verify Glance installation
openstack image create \
  --public \
  --container-format=bare \
  --disk-format=qcow2 \
  --file /etc/cirros/cirros-0.5.1-x86_64-disk.img \
  cirros

# Install and configure Nova
sudo apt install -y nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-placement-api nova-compute
sudo cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
PASS
sudo crudini --set /etc/nova/nova.conf database connection "mysql+pymysql://nova:0penstack@localhost/nova"
sudo crudini --set /etc/nova/nova.conf DEFAULT transport_url "rabbit://openstack:0penstack@localhost"
sudo crudini --set /etc/nova/nova.conf DEFAULT my_ip "10.0.0.1"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri "http://localhost:5000"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken auth_url "http://localhost:5000"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers "localhost:11211"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken auth_type "password"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name "Default"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name "Default"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken project_name "service"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken username "nova"
sudo crudini --set /etc/nova/nova.conf keystone_authtoken password "0penstack"
sudo crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
sudo crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

sudo nova-manage api_db sync
sudo nova-manage cell_v2 map_cell0
sudo nova-manage cell_v2 create_cell --
