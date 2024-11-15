#!/bin/bash
# Init MySQL
service mysql restart

# Wait for mysql service to be ready
until mysqladmin ping -h "localhost" --silent; do
    echo "Awaiting for MySQL service to start..."
    sleep 2
done
echo "MySQL is ready."

# Create MySQL user for local and external access
mysql -u root -e "CREATE DATABASE bonita;"
mysql -u root -e "CREATE USER 'focus'@'localhost' IDENTIFIED WITH mysql_native_password BY 'focus-user2024';"
mysql -u root -e "CREATE USER 'focus'@'%' IDENTIFIED WITH mysql_native_password BY 'focus-user2024';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'focus'@'localhost' WITH GRANT OPTION;"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'focus'@'%' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"


service mysql restart

# Init influx
influxd &

# Load nvm and start node-red
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Cargar nvm
node-red &


# Configure PHPMyAdmin in Apache
echo "<Directory /usr/share/phpmyadmin>"  > /etc/apache2/conf-available/phpmyadmin.conf
echo "    Options Indexes FollowSymLinks"  >> /etc/apache2/conf-available/phpmyadmin.conf
echo "    AllowOverride All"  >> /etc/apache2/conf-available/phpmyadmin.conf
echo "    Require all granted"  >> /etc/apache2/conf-available/phpmyadmin.conf
echo "</Directory>" >> /etc/apache2/conf-available/phpmyadmin.conf
# Configure PHPMyAdmin
touch /usr/share/phpmyadmin/config.inc.php
echo "<?php"  > /usr/share/phpmyadmin/config.inc.php
echo "\$cfg['Servers'][1]['host'] = '127.0.0.1';"  >> /usr/share/phpmyadmin/config.inc.php
echo "\$cfg['Servers'][1]['auth_type'] = 'cookie';"  >> /usr/share/phpmyadmin/config.inc.php
echo "\$cfg['blowfish_secret'] = 'focus_by_sanolivar_2024';" >> /usr/share/phpmyadmin/config.inc.php
# Init apache
service apache2 restart &

# Init pentaho spoon
/opt/data-integration/spoon.sh &

# Init VNC
# Configure VNC and XFCE desktop environment
mkdir -p /root/.vnc
echo -e '#!/bin/bash\nxrdb $HOME/.Xresources\nstartxfce4 &' > /root/.vnc/xstartup
chmod +x /root/.vnc/xstartup
# Configure VNC password automatically
echo "focus-user2024" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
# Create .Xauthority file and set permissions
touch /root/.Xauthority
chmod 600 /root/.Xauthority
# Set font path in the VNC server script
sed -i 's|^# $fontPath.*|$fontPath = "/usr/share/fonts/X11/misc,/usr/share/fonts/X11/75dpi,/usr/share/fonts/X11/100dpi,/usr/share/fonts/X11/Type1,/usr/share/fonts/X11/Speedo,/usr/share/fonts/X11/100dpi,/usr/share/fonts/X11/75dpi";|' /usr/bin/vncserver
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1
vncserver :1 -geometry 1920x1080 &

# # Init Bonita
# Rutas de configuración
DB_PROPERTIES_PATH="/opt/bonita/setup/database.properties"
CUSTOM_PROPERTIES_PATH="/opt/bonita/setup/platform_conf/initial/tenants/1/bonita-platform-community-custom.properties"
# Configurar el archivo database.properties para MySQL
cat <<EOL > $DB_PROPERTIES_PATH
db.vendor=mysql
db.database.name=bonita
db.user=focus
db.password=focus-user2024
db.server.name=127.0.0.1
db.server.port=3306
bdm.db.vendor=mysql
bdm.db.database.name=bonita
bdm.db.user=focus
bdm.db.password=focus-user2024
bdm.db.server.name=127.0.0.1
bdm.db.server.port=3306
EOL
# Descargar e instalar el conector JDBC de MySQL si no está presente
if [ ! -f /opt/bonita/lib/mysql-connector-java-8.0.28.jar ]; then
    wget -O /opt/bonita/lib/mysql-connector-java-8.0.28.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.28/mysql-connector-java-8.0.28.jar
fi
# Crear el archivo de configuración si no existe
mkdir -p "$(dirname "$CUSTOM_PROPERTIES_PATH")"
> "$CUSTOM_PROPERTIES_PATH"  # Limpiar el archivo
echo "org.bonitasoft.platform.admin.username=focus" >> "$CUSTOM_PROPERTIES_PATH"
echo "org.bonitasoft.platform.admin.password=focus-user2024" >> "$CUSTOM_PROPERTIES_PATH"
# Aplicar la configuración para que Bonita use MySQL
/opt/bonita/setup/setup.sh configure
# Limpiar logs para facilitar depuración
echo -n > /opt/bonita/server/logs/bonita.log
echo -n > /opt/bonita/server/logs/catalina.out
# Iniciar Bonita
echo "Iniciando Bonita..."
/opt/bonita/start-bonita.sh -Dh2.noconfirm


# Init Grafana
/usr/sbin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini &

# Keep container alive
tail -f /dev/null
