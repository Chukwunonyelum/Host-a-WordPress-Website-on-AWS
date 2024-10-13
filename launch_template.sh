#!/bin/bash
# Update the software packages on the EC2 instance
sudo yum update -y

# Install Apache web server
sudo yum install -y httpd
sudo systemctl enable httpd
sudo systemctl start httpd

# Install PHP 8 and necessary extensions
sudo dnf install -y \
php \
php-cli \
php-cgi \
php-curl \
php-mbstring \
php-gd \
php-mysqlnd \
php-gettext \
php-json \
php-xml \
php-fpm \
php-intl \
php-zip \
php-bcmath \
php-ctype \
php-fileinfo \
php-openssl \
php-pdo \
php-tokenizer

# Install MySQL 8 community repository
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

# Install MySQL server
sudo dnf install -y mysql80-community-release-el9-1.noarch.rpm
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
sudo dnf repolist enabled | grep "mysql.*-community.*"
sudo dnf install -y mysql-community-server

# Start and enable MySQL server
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Set the EFS DNS name (replace with your EFS DNS)
EFS_DNS_NAME=fs-02d3268559aa2a318.efs.us-east-1.amazonaws.com

# Mount the EFS to the html directory via fstab
echo "$EFS_DNS_NAME:/ /var/www/html nfs4 \
nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" | sudo tee -a /etc/fstab

sudo mount -a

# Set permissions
sudo chown apache:apache -R /var/www/html

# Restart the web server
sudo systemctl restart httpd
