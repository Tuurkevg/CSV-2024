
export readonly db_root_password='IcAgWaict9?slamrol'
export readonly db_name='wordpress_db'
export readonly db_user='wordpress_user'
export readonly db_password='Kof3Cup.ByRu'
# Pad naar de Apache-configuratiebestanden
export readonly  APACHE_CONF_DIR="/etc/apache2/sites-available"
export readonly DOMAIN_NAME="arthurisgeenjaak.com"
export readonly APACHE_LOG_DIR="/var/log/apache2"
# wordpress configuratie pad
export readonly WP_CONFIG="/var/www/html/wordpress/wp-config.php"
export readonly WP_TITLE="arthur"
export readonly WP_ADMIN="arthur"
export readonly WP_PASSWORD="arthur"
export readonly WP_EMAIL="arthur@plopkoek.internal"


apt update
apt install -y mariadb-server unzip
echo "-------------------Controleren of MariaDB-service is ingeschakeld en actief is----------------------------"
# Controleer of de apache2 service al actief is

systemctl start mariadb.service ssh

systemctl enable --now mariadb.service

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

systemctl restart mairadb

echo "-----------------------installeren van alle benodigde software voor de webserver----------------------------------"
apt install -y apache2 php php-curl php-bcmath php-gd php-soap php-zip php-curl php-mbstring php-mysqlnd php-gd php-xml php-intl php-zip

# echo het starten van de apache service
echo "------------------starten van apache2 service apache---------------------"

# Controleer of de apache2 service al actief is

systemctl start apache2
# Controleer of de apache2 service al ingeschakeld is om bij opstart te starten
systemctl enable apache2

echo "-------------------apache2 service is geactiveerd en actief----------------------" 

echo "-----------------------installatie van WORDPRESS---------------------------------"
# Controleer of WordPress nog niet is geïnstalleerd
if [ ! -d "/var/www/html/wordpress" ]; then
    # Download en installeer WordPress
     wget -P /var/www/html/ https://wordpress.org/latest.zip
     unzip /var/www/html/latest.zip -d /var/www/html/
     chown www-data:www-data  -R /var/www/html/wordpress/* # Let Apache be owner
     chmod +755 /var/www/html/
     rm /var/www/html/latest.zip  # Verwijder het zip-bestand na extractie
else
    echo "WordPress is al geïnstalleerd."
fi
# Apache configuratie wordpress
echo "------------------configuratie wordpress---------------------------------"
VHOST_CONF="${APACHE_CONF_DIR}/wordpress.conf"
VHOST_CONTENT=$(cat <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@${DOMAIN_NAME}
    ServerName ${DOMAIN_NAME}
    ServerAlias www.${DOMAIN_NAME}
    DocumentRoot /var/www/html/wordpress

    <Directory /var/www/html/wordpress/>
        Options FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/${DOMAIN_NAME}_error.log
    CustomLog ${APACHE_LOG_DIR}/${DOMAIN_NAME}_access.log combined
</VirtualHost>
EOF
)

# Schrijf de VirtualHost-configuratie naar het bestand
echo "${VHOST_CONTENT}" |  tee "${VHOST_CONF}"
sudo systemctl reload apache2
sudo a2ensite wordpress.conf
#--------------------------------------------------------------------------------
#volledige config van wordpress --> skip manual installation

# WordPress-configuratie inhoud met omgevingsvariabelen
WP_CONFIG_CONTENT=$(cat <<'EOF'
<?php
define( 'DB_NAME', '${db_name}' );
define( 'DB_USER', '${db_user}' );
define( 'DB_PASSWORD', '${db_password}' );
define( 'DB_HOST', '127.0.0.1' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

$table_prefix = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
# Controleer of de array-sleutel bestaat voordat je deze gebruikt http_forwarder
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
    $_SERVER['HTTPS'] = 'on';
}
#controleer of de array sleutel bestaat voordat je deze gebruikt httpost
if (isset($_SERVER['HTTP_HOST'])) {
    $http_host = $_SERVER['HTTP_HOST'];
} else {
    // Set a default value or handle the case when HTTP_HOST is not set
    $http_host = 'your_default_host';
}
require_once ABSPATH . 'wp-settings.php';
EOF
)

# Vervang omgevingsvariabelen in de WordPress-configuratie
WP_CONFIG_CONTENT=$(echo "${WP_CONFIG_CONTENT}" | \
    sed "s/'\${db_name}'/'${db_name}'/g" | \
    sed "s/'\${db_user}'/'${db_user}'/g" | \
    sed "s/'\${db_password}'/'${db_password}'/g" | \
    sed "s/'\$127.0.0.1'/'127.0.0.1'/g")

# Schrijf de WordPress configuratie naar het configuratiebestand
echo "${WP_CONFIG_CONTENT}" |  tee "${WP_CONFIG}" >/dev/null



# Download WP-CLI lokaal als het nog niet bestaat
if [ ! -f "/usr/local/bin/wp/wp-cli.phar" ]; then
    mkdir -p /usr/local/bin/wp/
    echo "Downloaden van WP-CLI voor configuratie van WordPress account"
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp/wp-cli.phar
    chmod +x  /usr/local/bin/wp/wp-cli.phar
else 
    echo "wp-cli al geinstalleerd"
fi

# Stel de juiste permissies in voor de uploads map
chmod -R 755 /var/www/html/wordpress/wp-content/*
cd /usr/local/bin/wp/
echo "Controleer of WordPress al geïnstalleerd is voordat je doorgaat"
if ! $(/usr/local/bin/wp/wp-cli.phar core is-installed --path=/var/www/html/wordpress --allow-root ); then
    # Voer de WP core installatie uit
    echo "WordPress core installatie"
    #echo "/usr/local/bin/wp/wp-cli.phar core install --path="/var/www/html/wordpress/" --url="${DOMAIN_NAME}" --title="${WP_TITLE}" --admin_user="${WP_ADMIN}" --admin_password="${WP_PASSWORD}" --admin_email="${WP_EMAIL}""
    /usr/local/bin/wp/wp-cli.phar core install --path="/var/www/html/wordpress/" --url="${DOMAIN_NAME}" --title="${WP_TITLE}" --admin_user="${WP_ADMIN}" --admin_password="${WP_PASSWORD}" --admin_email="${WP_EMAIL}" --quiet --skip-email --allow-root
else
echo "---------------wordpress installatieoverslaan: al gebeurd--------------------"
fi
systemctl restart apache2

echo "-------------aanpassing voor wp-json met .htacces---------------------"
cat << EOF > /var/www/html/wordpress/.htaccess
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
EOF

chown www-data:www-data  -R /var/www/html/wordpress/.htaccess # Let Apache be owner
chmod +755 /var/www/html/
sudo a2enmod rewrite
systemctl restart apache2
/usr/local/bin/wp/wp-cli.phar rewrite structure '/%postname%/' --hard --allow-root --path="/var/www/html/wordpress/"

echo "-------------------------installatie plugin met vulnability-----------------------"
/usr/local/bin/wp/wp-cli.phar plugin install /media/sf_gedeelde_map/woocommerce-payments.5.6.1.zip --allow-root --path="/var/www/html/wordpress/"
/usr/local/bin/wp/wp-cli.phar plugin activate woocommerce-payments --allow-root  --path="/var/www/html/wordpress/"
echo "--------------------------EINDE BASH SCRIPT SCRIPT1.SH --> WORDPRESS + APACHE + MARIADB + WP-CLI + PLUGIN INSTALLATIE + CONFIGURATIE---------------------------"


