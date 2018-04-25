function package-install {
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
}
package-install

function configure-services {
    # Move original config to backup
    mv /etc/powerdns/pdns.conf /etc/powerdns/_orgi.pdns.conf
    # Create config files
    cp ./pdns.conf /etc/powerdns/pdns.conf
    cp ./pdns.gmysql.conf /etc/powerdns/pdns.d/pdns.gmysql.conf 



    while [ $1 !=  "0" ]
    do
        if [ $1 == "master" ]
        then
            sed -i -e "s/1.1.1.1/$2/g" /etc/powerdns/pdns.conf
            sed -i -e "s/slave=yes/slave=no/g" /etc/powerdns/pdns.conf
        elif [ $1 == "slave" ]
        then
            sed -i -e "s/1.1.1.1/0.0.0.0/g" /etc/powerdns/pdns.conf
            sed -i -e "s/master=yes/master=no/g" /etc/powerdns/pdns.conf
        else
            echo "Wronge server type (`0` for aborting server configuration) or"
            read -p "Pleas enter the the server typre [master|slave]: " 1
        fi
    done

    # Edit gmysql config
    sed -i -e "s/powerdns_user/$3/g" /etc/powerdns/pdns.conf
    sed -i -e "s/powerdns_user_password/$4/g" /etc/powerdns/pdns.conf
    
    # Create database
    mysql -u root -p$4 < ./schema.sql
}
configure-services $type $slaveip $MYSQL_DB_USER $MYSQL_DB_PASSWORD


function create-ipv4-zone {
    # Create zone
    if [ $1 == "master" ]
    then
        # Edit Zone
        sed -i -e "s/example.com/$2/g" ./master.sql
        sed -i -e "s/placeNS0.com/$3/g" ./master.sql
        sed -i -e "s/placeNS1.com/$4/g" ./master.sql
        sed -i -e "s/placeA/$5/g" ./master.sql
        # Create Zone
        mysql -u root < ./master.sql
        echo "Mster zone IPv4 created for $2"
        # Reset Zone
        sed -i -e "s/$2/example.com/g" ./master.sql
        sed -i -e "s/$3/placeNS0.com/g" ./master.sql
        sed -i -e "s/$4/placeNS1.com/g" ./master.sql
        sed -i -e "s/$5/placeA/g" ./master.sql
    elif [ $1 == "slave" ]
    then
        # Edit Zone
        sed -i -e "s/example.com/$2/g" ./slave.sql
        sed -i -e "s/placeNS0.com/$3/g" ./slave.sql
        # Create Zone
        mysql -u root < ./slave.sql
        echo "Slave zone IPv4 created for $2"
        # Reset Zone
        sed -i -e "s/$2/example.com/g" ./slave.sql
        sed -i -e "s/$3/placeNS0.com/g" ./slave.sql
    fi
}
create-ipv4-zone $type $domain $masterip $slaveip $ARecord

function create-ipv6-zone {
    # Create zone
    if [ $1 == "master" ]
    then
        # Edit Zone
        sed -i -e "s/example.com/$2/g" ./masterv6.sql
        sed -i -e "s/placeNS0v6.com/$3/g" ./masterv6.sql
        sed -i -e "s/placeNS1v6.com/$4/g" ./masterv6.sql
        sed -i -e "s/placeAAAA/$5/g" ./masterv6.sql
        # Create Zone
        mysql -u root < ./masterv6.sql
        echo "Mster zone IPv4 created for $2"
        # Reset Zone
        sed -i -e "s/$2/example.com/g" ./master.sql
        sed -i -e "s/$3/placeNS0v6.com/g" ./masterv6.sql
        sed -i -e "s/$4/placeNS1v6.com/g" ./masterv6.sql
        sed -i -e "s/$5/placeAAAA/g" ./masterv6.sql
    elif [ $1 == "slave" ]
    then
        # Edit Zone
        sed -i -e "s/example.com/$2/g" ./slavev6.sql
        sed -i -e "s/placeNS0v6.com/$3/g" ./slavev6.sql
        # Create Zone
        mysql -u root < ./slavev6.sql
        echo "Slave zone IPv4 created for $2"
        # Reset Zone
        sed -i -e "s/$2/example.com/g" ./slavev6.sql
        sed -i -e "s/$3/placeNS0v6.com/g" ./slavev6.sql
    fi
}
create-ipv4-zone $type $domain $masterIPv6 $slaveIPv6 $AAAARecord 
