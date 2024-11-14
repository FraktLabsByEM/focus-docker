FROM ubuntu:20.04

# copy init file
COPY init.sh /init.sh
RUN chmod +x /init.sh

# Set console only
RUN DEBIAN_FRONTEND=noninteractive
# update system dependencies
RUN apt update && apt install -y wget curl gnupg software-properties-common nano snapd tzdata unzip
# configure time zone
RUN ln -fs /usr/share/zoneinfo/America/Bogota /etc/localtime && dpkg-reconfigure -f noninteractive tzdata
                            # INSTALL GRAFANA
# add grafana repositories
RUN wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key && \
    echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list && \
    apt update
# install grafana
RUN apt install -y -f grafana
# set up grafana to work with mysql
RUN sed -i 's/;type = sqlite3/;type = mysql/' /etc/grafana/grafana.ini && \
    sed -i 's/;user = root/;user = focus/' /etc/grafana/grafana.ini && \
    sed -i 's/;password =/;password = focus-user2024/' /etc/grafana/grafana.ini && \
    sed -i 's/;name = grafana/;name = focus/' /etc/grafana/grafana.ini
                            # INSTALL MYSQL
# install mysql
RUN apt install -y -f mysql-server && \
    # give external access
    sed -i '0,/bind-address/s/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
                            # INSTALL INFLUX
# Use curl to download the influx binary.
RUN curl --location -O \
https://download.influxdata.com/influxdb/releases/influxdb2-2.7.10_linux_amd64.tar.gz && \
    # Download and import influx key
    curl --silent --location https://repos.influxdata.com/influxdata-archive.key \
    | gpg --import - 2>&1 \
    | grep 'InfluxData Package Signing Key <support@influxdata.com>' && \
    # Download and verify influx binary's signature file
    curl --silent --location "https://download.influxdata.com/influxdb/releases/influxdb2-2.7.10_linux_amd64.tar.gz.asc" \
    | gpg --verify - influxdb2-2.7.10_linux_amd64.tar.gz \
    2>&1 | grep 'InfluxData Package Signing Key <support@influxdata.com>'
# Extract influx binary
RUN tar xvzf ./influxdb2-2.7.10_linux_amd64.tar.gz && \
    # copy influx files into user bin
    cp ./influxdb2-2.7.10/usr/bin/influxd /usr/local/bin/ && \
    # remove influx tar file and extracted folder
    rm influxdb2-2.7.10_linux_amd64.tar.gz && \
    rm -r influxdb2-2.7.10
# Install mosquitto mosquitto
RUN apt install -y mosquitto
# Install nvm -> node -> node red
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install v19.9.0 && \
    npm install -g --unsafe-perm node-red

# install ngingx
RUN apt install -y nginx

# install php - php my admin
RUN add-apt-repository ppa:ondrej/php && \
    apt install -y php8.3-fpm php8.3-mysql && \
    # install php my admin
    wget https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.zip && \
    unzip phpMyAdmin-5.2.0-all-languages.zip -d /usr/share/ && \
    mv /usr/share/phpMyAdmin-5.2.0-all-languages /usr/share/phpmyadmin && \
    rm phpMyAdmin-5.2.0-all-languages.zip 

# configure php my admin
RUN touch /usr/share/phpmyadmin/config.inc.php && \
    echo "<?php" >> /usr/share/phpmyadmin/config.inc.php && \
    echo "\$cfg['blowfish_secret'] = 'my_secret_key_12345';" >> /usr/share/phpmyadmin/config.inc.php && \
    echo "\$cfg['Servers'][1]['auth_type'] = 'cookie';" >> /usr/share/phpmyadmin/config.inc.php

# configure nginx to serve php
RUN touch /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "server {" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "    listen 80;" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "    server_name localhost;" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "    location /phpmyadmin {" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "        alias /usr/share/phpmyadmin;" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "        index index.php index.html index.htm;" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "    }" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "    location ~ \\.php$ {" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "        include snippets/fastcgi-php.conf;" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "    }" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "    location ~ /\\.ht {" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "        deny all;" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "    }" >> /etc/nginx/sites-available/phpmyadmin.conf && \
    echo "}" >> /etc/nginx/sites-available/phpmyadmin.conf

# enable php config
RUN ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/



EXPOSE 3001 3307 8087 1883 1880 80
# Iniciar servicios
ENTRYPOINT ["/init.sh"]