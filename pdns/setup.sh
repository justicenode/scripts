#!/bin/bash

#Get configuration from user
echo 	"Script to setup powrdns [master|slave] nameserver"
read -p "Pleas enter the master IP" masterip
read -p "Pleas enter the slave IP" slaveip
read -p "Pleas enter the domain" domain
read -p "Pleas enter the A Records IP" ARecord
read -p "Pleas enter the your new MYSQL Root password" MYSQL_ROOT_PASSWORD
read -p "Pleas enter the your new DB user" MYSQL_DB_USER
read -p "Pleas enter the the new password for the DB user" MYSQL_DB_PASSWORD
read -p "Pleas enter the the server typre [master|slave]("0" for aborting zone creation)" type

# Install packages
apt update && apt install mariadb-client mariadb-server pdns-server pdns-backend-mysql

# Setup mariadb
apt -y install expect
// Not required in actual script
# Set password
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MYSQL\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"
apt -y purge expect
apt -y autoremove 

# Configure hosts file
echo "
$masterip 	ns0.$domain
$slaveip 	ns1.$domain" >> /etc/hosts

# Configuring pdns server
mv /etc/powerdns/pdns.conf /etc/powerdns/_orgi.pdns.conf
cp ./pdns.conf /etc/powerdns/pdns.conf
cp ./pdns.gmysql.conf /etc/powerdns/pdns.d/pdns.gmysql.conf 

# Edit server config 
sed -i -e "s/1.1.1.1/$slaveip/g" /etc/powerdns/pdns.conf
# Edit gmysql config
sed -i -e "s/powerdns_user/$MYSQL_DB_USER/g" /etc/powerdns/pdns.conf
sed -i -e "s/powerdns_user_password/$MYSQL_DB_PASSWORD/g" /etc/powerdns/pdns.conf

# Create database
mysql -u root -p123.qwe < ./schema.sql

# Create zone
while [ $type !=  "0" ]
do
	if [ $type == "master" ]
	then
		# Edit Zone
		sed -i -e "s/example.com/$domain/g" ./master.sql
		sed -i -e "s/placeNS0.com/$masterip/g" ./master.sql
		sed -i -e "s/placeNS1.com/$slaveip/g" ./master.sql
		sed -i -e "s/placeA/$ARecord/g" ./master.sql
		# Create Zone
		mysql -u root -p123.qwe < ./master.sql
		# Reset Zone
		sed -i -e "s/$domain/example.com/g" ./master.sql
		sed -i -e "s/$masterip/placeNS0.com/g" ./master.sql
		sed -i -e "s/$slaveip/placeNS1.com/g" ./master.sql
		sed -i -e "s/$ARecord/placeA/g" ./master.sql
	elif [ $type == "slave" ]
	then
		# Edit Zone
		sed -i -e "s/example.com/$domain/g" ./slave.sql
		# Create Zone
		mysql -u root -p123.qwe < ./slave.sql
		# Reset Zone
		sed -i -e "s/$domain/example.com/g" ./slave.sql
	else
		else 	"Wronge server type (`0` for aborting zone creation)"
		read -p "Pleas enter the the server typre [master|slave]" type
	fi
done