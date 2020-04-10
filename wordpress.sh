#!/bin/bash


# STEP-1: Installation of all prerequisites.

if [[ "${UID}" -eq 0 ]]
then
	echo 'You are a root user'
else
	echo 'You are not a root user'
	exit 1
fi

echo "Database Name: "
read -e dbname
echo "Database User: "
read -e dbuser
echo "Database Password: "
read -s dbpass

yum install php-mysqlnd php-fpm mysql mysqld httpd php-json


# Step-2: Open HTTP(80) and HTTPS (443) ports in our Firewall.

firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

# Step-3: Start both Apache Webserver and and the MariaDB services.

systemctl start mysqld
systemctl start httpd

# Step-4: Enable MariaDB and httpd to start after system reboots.

systemctl enable mysqld
systemctl enable httpd


# Step-5: Download and extract WordPress. Also copy the extracted Wordpress directory into the 'var/www/html' directory.

curl https://wordpress.org/latest.tar.gz --output wordpress.tar.gz
tar -xzvf wordpress.tar.gz
rm wordpress.tar.gz

cd wordpress
mv wp-config-sample.php wp-config.php

#set database details with perl find and replace
perl -pi -e "s/database_name_here/${dbname}/g" wp-config.php
perl -pi -e "s/username_here/${dbuser}/g" wp-config.php
perl -pi -e "s/password_here/${dbpass}/g" wp-config.php

#Back to parent directory
cd ..

cp -r wordpress /var/www/html


# Step-6 Change permissions and change file SELinux security context.

chown -R apache:apache /var/www/html/wordpress
chcon -t httpd_sys_rw_content_t /var/www/html/wordpress -R
