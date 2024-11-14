#!/bin/bash

# Init MySQL
service mysql restart

# Wait for mysql service to be ready
until mysqladmin ping -h "localhost" --silent; do
    echo "Awaiting for MySQL service to start..."
    sleep 2
done
echo "MySQL is ready."

# Create MySQL user
mysql -u root -e "CREATE USER 'focus'@'%' IDENTIFIED BY 'focus-user2024';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'focus'@'%' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

# Init influx
influxd &

# Load nvm and start node-red
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Cargar nvm
node-red &

# Init PHPMyAdmin and nginx
service php8.3-fpm start &
service nginx start &

# Init Grafana
/usr/sbin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini &

# Keep container alive
tail -f /dev/null
