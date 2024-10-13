# Hosting a WordPress Website on AWS using EC2 and 3-Tier VPC Architecture

This repository contains scripts and configuration details for deploying a highly available and scalable WordPress site on AWS using a 3-tier VPC architecture. The setup includes EC2 instances for the web and application layers, RDS for the database layer, EFS for shared file storage, and an Application Load Balancer for managing traffic across multiple availability zones.

## Project Overview

The following AWS resources and services were used to host the WordPress website:

- **Amazon EC2**: For hosting the WordPress application.
- **Amazon RDS**: Managed database for the WordPress backend.
- **Amazon EFS**: Shared file system for web content.
- **Application Load Balancer**: For distributing incoming traffic.
- **Auto Scaling Group**: Ensures scalability and fault tolerance.
- **Amazon Route 53**: DNS and domain management.
- **AWS Certificate Manager (ACM)**: SSL certificate management for HTTPS traffic.
- **Amazon VPC**: Configured with public and private subnets across two availability zones.
- **NAT Gateway**: Allows instances in private subnets to access the internet.
- **Security Groups**: Act as virtual firewalls for controlling inbound and outbound traffic.

---


## Deployment Steps

### Step 1: Select the AWS Region

Choose the region where you want to deploy your WordPress site.

### Step 2: Create a 3-Tier VPC

1. **VPC Creation**: Create a Virtual Private Cloud (VPC) to host your WordPress application.
2. **DNS Hostname Setting**: Enable DNS hostnames for your VPC to support public DNS resolution.
3. **Internet Gateway**: Create and attach an internet gateway to the VPC for internet access.

#### Subnets Creation:

- **Public Subnets**: Create public subnets in two availability zones (AZ1 and AZ2) for your NAT Gateway and Application Load Balancer.
- **Private App Subnets**: Create private subnets in both AZ1 and AZ2 for hosting your application (WordPress) EC2 instances.
- **Private Data Subnets**: Create private subnets in both AZ1 and AZ2 for the RDS database.

### Step 3: Networking and Routing

1. **Auto-Assign IPs**: Enable auto-assign public IPs in public subnets.
2. **Public Subnet Route Table**: Route internet-bound traffic to the internet gateway and associate the public subnets.
3. **NAT Gateway Creation**: Create a NAT Gateway in the public subnet for internet access from the private subnets.
4. **Private Subnet Route Table**: Route traffic from private subnets to the NAT Gateway.

### Step 4: Security Groups Configuration

Create the following security groups to secure your AWS environment:

- **ALB SG**: Allows inbound HTTP (port 80) and HTTPS (port 443) traffic from the internet.
- **EC2 Instance SG**: Allows SSH (port 22) and web traffic (ports 80 and 443) from the VPC CIDR block and ALB.
- **DB SG**: Allows MySQL traffic (port 3306) only from the app server SG.
- **EFS SG**: Allows NFS traffic (port 2049) from the app server SG and SSH traffic for maintenance.

### Step 5: EC2 Instance Setup

1. **EC2 Instance Connect Endpoint**: Set up an EC2 instance connect endpoint in the private subnet for secure SSH access to instances.
2. **Launch EC2 Instance**: Launch an EC2 instance in a private subnet to test the connection.
3. **SSH Access**: SSH into the instance via the AWS Management Console or AWS CLI to verify connectivity.
4. **Terminate EC2 Instance**: After testing, terminate the instance.

### Step 6: Create EFS and RDS

1. **Create EFS**: Set up Elastic File System (EFS) for shared storage.
2. **Create RDS Subnet Group**: Define a subnet group for RDS.
3. **Create RDS Instance**: Launch an RDS instance (MySQL) for your WordPress database.

### Step 7: Configure Application Load Balancer (ALB)

1. **Create Target Group**: Create a target group for your EC2 instances.
2. **Launch EC2 Instances**: Deploy EC2 instances in the private subnets to serve the WordPress application.
3. **Associate EC2 Instances with ALB**: Register the EC2 instances to the ALB.
4. **Create Application Load Balancer**: Set up the ALB to handle incoming traffic and forward it to the EC2 instances.

### Step 8: Install WordPress

1. **Access WordPress Installation Requirements**:
   - AWS Docs: [AWS WordPress Hosting](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hosting-wordpress.html)
   - WordPress Docs: [WordPress Requirements](https://wordpress.org/about/requirements/)
2. **Prepare Installation Script**: Use the provided script to install WordPress on your EC2 instances.
3. **Verify EFS Mounting**: Use `df -h` to confirm that EFS is mounted correctly.
4. **Install Apache, PHP, and MySQL**: Set up the necessary components to run WordPress.
5. **Edit `wp-config.php`**: Update the `wp-config.php` file with database credentials.
6. **Restart Web Server**: Restart Apache to apply changes.

### Step 9: DNS and SSL Setup

1. **Route 53 DNS Configuration**: Register a domain and set up DNS records.
2. **SSL Certificate**: Request an SSL certificate from AWS Certificate Manager (ACM).
3. **HTTPS Listener**: Add an HTTPS listener to the ALB and redirect HTTP traffic to HTTPS.
4. **Update WordPress URL**: Update the WordPress site URL in the admin panel.

### Step 10: Auto Scaling Group

1. **Create Launch Template**: Prepare a launch template with a user data script for auto-scaling.
2. **Create Auto Scaling Group**: Set up an auto-scaling group to manage EC2 instances.
3. **Configure SNS for Notifications**: Set up an SNS topic for alerts about scaling activities.
4. **Verify Target Group**: Check the target group to ensure EC2 instances are being added.

---

## Scripts and Resources

- **WordPress Installation Script**: See [`install_wordpress.sh`](#wordPress-installation-script) for the script used to install and configure WordPress.
- **Auto Scaling Launch Template Script**: The script to be added to the Auto Scaling launch template can be found in [`launch_template.sh`](#auto-scaling-launch-template-script).

---

## WordPress Installation Script

```bash
#!/bin/bash
# Switch to root user
sudo su

# Update the software packages on the EC2 instance
sudo yum update -y

# Create the web root directory
sudo mkdir -p /var/www/html

# Set the EFS DNS name (replace with your EFS DNS)
EFS_DNS_NAME=fs-064e9505819af10a4.efs.us-east-1.amazonaws.com

# Mount the EFS to the html directory
sudo mount -t nfs4 -o \
nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
"$EFS_DNS_NAME":/ /var/www/html

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

# Set permissions
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
sudo find /var/www -type f -exec sudo chmod 0664 {} \;
sudo chown apache:apache -R /var/www/html

# Download WordPress files
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo cp -r wordpress/* /var/www/html/

# Create the wp-config.php file
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

# Edit the wp-config.php file with your database credentials
sudo vi /var/www/html/wp-config.php

# Restart the web server
sudo systemctl restart httpd
```

---

## Auto Scaling Launch Template Script

```bash
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
```

---

## Project Summary

By the end of this project, you will have deployed a highly available WordPress website using AWS infrastructure, including EC2, RDS, EFS, and an Application Load Balancer, all within a secure VPC. The architecture is designed for scalability, with an auto-scaling group ensuring that your WordPress site can handle traffic spikes efficiently.

---

## Reference Links

- [AWS WordPress Hosting Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hosting-wordpress.html)
- [WordPress Requirements](https://wordpress.org/about/requirements/)



---

## Contributing

Feel free to contribute by submitting issues or pull requests. Collaboration is welcome to improve the project and expand its features.

---


**Note**: Replace placeholders like `fs-064e9505819af10a4.efs.us-east-1.amazonaws.com`, `your_db_name`, `your_db_user`, `your_db_password`, `your_rds_endpoint`, `[Your Name]`, and `[your-email@example.com]` with your actual configuration details.
