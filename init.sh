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

# Init apache
service apache2 start &

# Init Grafana
/usr/sbin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini &

# Keep container alive
tail -f /dev/null
