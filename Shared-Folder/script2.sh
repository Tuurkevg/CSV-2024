#!/bin/bash
export readonly db_root_password='Test123'
export readonly db_name='chamilo'
export readonly db_user='root'
export readonly db_password='Test123'
export readonly APACHE_CONF_DIR="/etc/apache2/sites-available"
export readonly DOMAIN_NAME="jaakisgeenarthur.com"
export readonly APACHE_LOG_DIR="/var/log/apache2"

sudo apt update -y
sudo apt install apache2 software-properties-common unzip -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y
sudo apt install php7.4 libapache2-mod-php7.4 php7.4-{cli,common,curl,zip,gd,mysql,xml,mbstring,json,intl,ldap,apcu,soap} -y


echo "------------mariadb isntallatie-------------"

sudo apt install mariadb-server unzip -y
echo "-------------------Controleren of MariaDB-service is ingeschakeld en actief is----------------------------"
# Controleer of de apache2 service al actief is

sudo systemctl start mariadb

sudo systemctl enable --now mariadb

is_mysql_root_password_empty() {
  mysqladmin --user=root status > /dev/null 2>&1
}
if is_mysql_root_password_empty; then
mysql <<_EOF_
  SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${db_root_password}');
  DELETE FROM mysql.user WHERE User=''; 
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
_EOF_
fi

echo "----------------Creating and user----------------------"

mysql --user=root --password="${db_root_password}" << _EOF_
CREATE DATABASE IF NOT EXISTS ${db_name};
GRANT ALL ON ${db_name}.* TO '${db_user}' IDENTIFIED BY '${db_password}';
FLUSH PRIVILEGES;
_EOF_

sudo systemctl restart mairadb
#---------------------------------------------------------------#


if [ -d "/var/www/html/chamilo" ]; then
    echo "---------------------chamlilo zip bestand is al uitgepakt.-----------------------"
else
    # Download en pak het zipbestand uit
    sudo wget -v -P /home/osboxes https://github.com/chamilo/chamilo-lms/releases/download/v1.11.18/chamilo-1.11.18-php74.zip
    sudo unzip /home/osboxes/chamilo-1.11.18-php74.zip -d /home/osboxes/

    # Verplaats de uitgepakte map naar de juiste locatie
    sudo mv /home/osboxes/chamilo-1.11.18 /var/www/html/chamilo --verbose
    sudo rm -rf /home/osboxes/chamilo-1.11.18-php74.zip
    sudo rm -rf /home/osboxes/chamilo-1.11.18
fi

echo "-------------------------------apache site chamilo----------------------"
VHOST_CONF="${APACHE_CONF_DIR}/chamilo.conf"
VHOST_CONTENT=$(cat <<EOF
<VirtualHost *:80>
    ServerAdmin admin@jaakisgeenarthur.com
    DocumentRoot /var/www/html/chamilo/

    ServerName jaakisgeenarthur.com
    ServerAlias www.jaakisgeenarthur.com

    <Directory /var/www/html/chamilo/> 
        AllowOverride All
        Require all granted
    </Directory> 

    ErrorLog /var/log/apache2/jaakisgeenarthur.com-error_log
    CustomLog /var/log/apache2/jaakisgeenarthur.com-access_log common

</VirtualHost>
EOF
)
# Schrijf de VirtualHost-configuratie naar het bestand
echo "${VHOST_CONTENT}" |  tee "${VHOST_CONF}"

echo "------------------configuratie chamilo---------------------------------"
sudo a2enmod rewrite
sudo a2ensite chamilo.conf
sudo systemctl restart apache2

echo "database dumo importeren"
mariadb chamilo < /media/sf_gedeelde_map/chamilodb.sql
cp /media/sf_gedeelde_map/configuration.php /var/www/html/chamilo/app/config/

chown -R www-data:www-data /var/www/html/chamilo
chmod -R 755 /var/www/html/chamilo

# Controleer of LibreOffice al is geïnstalleerd
if [ -e "/usr/bin/libreoffice4.2" ]; then
    echo "---------------LibreOffice4.2 is al geïnstalleerd. Geen actie nodig.---------------------"
else
    # Download LibreOffice
    echo "-----------------------------------------------------LibreOffice wordt gedownload...-----------------------------------------------------------------------"
    sudo wget -v -P /home/osboxes http://downloadarchive.documentfoundation.org/libreoffice/old/4.2.8.2/deb/x86_64/LibreOffice_4.2.8.2_Linux_x86-64_deb.tar.gz
    
    # Pak het archief uit
    echo "------------------------------------LibreOffice wordt uitgepakt...------------------------------------"
    tar -xvf /home/osboxes/LibreOffice_4.2.8.2_Linux_x86-64_deb.tar.gz -C /home/osboxes/ 
    
    # Ga naar de map met de pakketten
    cd /home/osboxes/LibreOffice_4.2.8.2_Linux_x86-64_deb/DEBS
    
    # Installeer de deb-pakketten
    echo "LibreOffice wordt geïnstalleerd..."
    sudo dpkg -i *.deb
    echo "-------files verwijderen di eonnodig zijn-------------------------------"
    rm -rf /home/osboxes/LibreOffice_4.2.8.2_Linux_x86-64_deb
    rm -rf /home/osboxes/LibreOffice_4.2.8.2_Linux_x86-64_deb.tar.gz
fi


echo "-----------------------------------instalaltie java dependecys en screen---------------------------"
sudo apt install screen -y
sudo apt install libxinerama1 -y
sudo apt install default-jre -y
sudo apt-get install libdbus-glib-1-2 -y
sudo systemctl restart apache2
echo "socket openen en op achtergrond zetten........"
nohup /opt/libreoffice4.2/program/soffice.bin --accept="socket,host=127.0.0.1,port=2002,tcpNoDelay=1;urp;" --headless --nodefault --nofirststartwizard --nolockcheck --nologo --norestore > /dev/null 2>&1 &


echo "--------------------SCRIPT2 SUCCESVOL AFGEROND-------------------------------"