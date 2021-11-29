#!/bin/bash

efs_id="${efs_id}"
db_admin_username="${db_admin_username}"
db_admin_password="${db_admin_password}"
db_host="${db_host}"
db_name="${db_name}"

sudo yum update -y
sudo yum install amazon-efs-utils docker -y

# Docker
sudo systemctl enable docker
sudo systemctl start docker
sleep 60

# EFS mount
sudo mkdir /efs
sudo mount -t efs $efs_id:/ /efs
sudo echo $efs_id:/ /efs efs defaults,_netdev 0 0 >> /etc/fstab
sleep 10

# Wordpress
sudo docker run -e WORDPRESS_DB_USER=$db_admin_username -e WORDPRESS_DB_PASSWORD="$db_admin_password" -e WORDPRESS_DB_HOST="$db_host" -e WORDPRESS_DB_NAME="$db_name" --name wordpress -p 80:80 -v /efs:/var/www/html -d wordpress