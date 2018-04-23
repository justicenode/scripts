#!/bin/bash

#Get configuration from user
echo 	"Script to setup powrdns [master|slave] nameserver"
read -p "Pleas enter the master IPv4: " masterip
read -p "Pleas enter the slave IPv4: " slaveip
read -p "Pleas enter the domain: " domain
read -p "Pleas enter the A Records IP: " ARecord
read -p "Pleas enter the your new MYSQL Root password:  " -r -s MYSQL_ROOT_PASSWORD && echo ""
read -p "Pleas enter the your new DB user: " MYSQL_DB_USER
read -p "Pleas enter the the new password for the DB user: " -r -s MYSQL_DB_PASSWORD && echo ""
read -p "Pleas enter the the server typre [master|slave]" type
read -p "Do you want to create a basic IPv4 zone [yes|no]" zonev4 

# Install expect needed for interaction between script an UIs
apt update && apt -y install expect

# Install packages 
# Automatically yes to installation and no to the pdns-mysql-backend configurator 
install_packages=$(expect -c "
spawn apt install mariadb-client mariadb-server pdns-server pdns-backend-mysql
expect \"Do you want to continue? \"
send \"y\r\"
expect \"Package configuration\"
sleep 1
send \(\"\{TAB\}\"\)
sleep 1
send \(\"\{Enter\}\"\)
expect eof
")
echo "$install_packages"

# Setup mariadb
# Set root password
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MYSQL\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password: \"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password: \"
send \"$MYSQL_ROOT_PASSWORD\r\"
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
# Remove expect and its dependencies
apt -y purge expect
apt -y autoremove 

# Move original config to backup
mv /etc/powerdns/pdns.conf /etc/powerdns/_orgi.pdns.conf
# Create config files
cp ./pdns.conf /etc/powerdns/pdns.conf
cp ./pdns.gmysql.conf /etc/powerdns/pdns.d/pdns.gmysql.conf 



while [ $type !=  "0" ]
do
	if [ $type == "master" ]
	then
        sed -i -e "s/1.1.1.1/$slaveip/g" /etc/powerdns/pdns.conf
        sed -i -e "s/slave=yes/slave=no/g" /etc/powerdns/pdns.conf
	elif [ $type == "slave" ]
	then
        sed -i -e "s/1.1.1.1/0.0.0.0/g" /etc/powerdns/pdns.conf
        sed -i -e "s/master=yes/master=no/g" /etc/powerdns/pdns.conf
	else
		echo "Wronge server type (`0` for aborting server configuration) or"
		read -p "Pleas enter the the server typre [master|slave]: " type
	fi
done

# Edit gmysql config
sed -i -e "s/powerdns_user/$MYSQL_DB_USER/g" /etc/powerdns/pdns.conf
sed -i -e "s/powerdns_user_password/$MYSQL_DB_PASSWORD/g" /etc/powerdns/pdns.conf


# Create database
mysql -u root -p$MYSQL_ROOT_PASSWORD < ./schema.sql

# Create zone
if [ $zonev4 == "yes" ]
then
    if [ $type == "master" ]
    then
        # Edit Zone
        sed -i -e "s/example.com/$domain/g" ./master.sql
        sed -i -e "s/placeNS0.com/$masterip/g" ./master.sql
        sed -i -e "s/placeNS1.com/$slaveip/g" ./master.sql
        sed -i -e "s/placeA/$ARecord/g" ./master.sql
        # Create Zone
        mysql -u root -p$MYSQL_ROOT_PASSWORD < ./master.sql
        echo "mMster zone IPv4 created for $domain"
        # Reset Zone
        sed -i -e "s/$domain/example.com/g" ./master.sql
        sed -i -e "s/$masterip/placeNS0.com/g" ./master.sql
        sed -i -e "s/$slaveip/placeNS1.com/g" ./master.sql
        sed -i -e "s/$ARecord/placeA/g" ./master.sql
    elif [ $type == "slave" ]
    then
        # Edit Zone
        sed -i -e "s/example.com/$domain/g" ./slave.sql
        sed -i -e "s/placeNS0.com/$masterip/g" ./master.sql
        # Create Zone
        mysql -u root -p$MYSQL_ROOT_PASSWORD < ./slave.sql
        echo "Slave zone IPv4 created for $domain"
        # Reset Zone
        sed -i -e "s/$domain/example.com/g" ./slave.sql
        sed -i -e "s/$masterip/placeNS0.com/g" ./master.sql
    fi
else
    echo "No zone created" 
fi 
