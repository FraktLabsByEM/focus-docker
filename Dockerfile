FROM ubuntu:20.04

# copy init file
COPY init.sh /init.sh
RUN chmod +x /init.sh

# Set console only
ENV DEBIAN_FRONTEND=noninteractive
# update system dependencies
RUN apt update && apt install -y wget curl gnupg software-properties-common \
    nano snapd tzdata unzip maven git openjdk-11-jre default-jre libwebkit2gtk-4.0-37 xfonts-base && \
    # configure time zone
    ln -fs /usr/share/zoneinfo/America/Bogota /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

                            # INSTALL VNC VIEWER
# set user as root
ENV USER=root
# Install VNC and XFCE desktop environment
RUN apt install -y tightvncserver xfce4 xfce4-goodies xfonts-base xfonts-75dpi xfonts-100dpi && \
    # Configure VNC and XFCE desktop environment
    mkdir -p /root/.vnc && \
    echo '#!/bin/bash\nxrdb $HOME/.Xresources\nstartxfce4 &' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup && \
    # Configure VNC password automatically
    echo "focus-user2024" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    # Create .Xauthority file and set permissions
    touch /root/.Xauthority && \
    chmod 600 /root/.Xauthority && \
    # Set font path in the VNC server script
    sed -i 's|^# $fontPath.*|$fontPath = "/usr/share/fonts/X11/misc,/usr/share/fonts/X11/75dpi,/usr/share/fonts/X11/100dpi,/usr/share/fonts/X11/Type1,/usr/share/fonts/X11/Speedo,/usr/share/fonts/X11/100dpi,/usr/share/fonts/X11/75dpi";|' /usr/bin/vncserver

                        
                            # INSTALL GRAFANA
# add grafana repositories
RUN wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key && \
    echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list && \
    apt update && \
    # install grafana
    apt install -y -f grafana && \
    # set up grafana to work with mysql
    sed -i 's/;type = sqlite3/;type = mysql/' /etc/grafana/grafana.ini && \
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
    2>&1 | grep 'InfluxData Package Signing Key <support@influxdata.com>' && \
    # Extract influx binary
    tar xvzf ./influxdb2-2.7.10_linux_amd64.tar.gz && \
    # copy influx files into user bin
    mv ./influxdb2-2.7.10/usr/bin/influxd /usr/local/bin/ && \
    # remove influx tar file and extracted folder
    rm influxdb2-2.7.10_linux_amd64.tar.gz

                            # INSTALL MOSQUITTO
# Install mosquitto mosquitto
RUN apt install -y mosquitto

                            # INSTALL NODE RED
# Install nvm -> node -> node red
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install v19.9.0 && \
    npm install -g --unsafe-perm node-red

                            # INSTALL APACHE - PHPMYADMIN
# ngnix throws a lot of problems, so its replaced with apache
# Install Apache
RUN apt update && \
    apt install -y apache2 libapache2-mod-php && \
    # install php - php my admin
    add-apt-repository ppa:ondrej/php && \
    apt install -y php8.3 php8.3-mysql && \
    # install php my admin
    wget https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.zip && \
    unzip phpMyAdmin-5.2.0-all-languages.zip -d /usr/share/ && \
    mv /usr/share/phpMyAdmin-5.2.0-all-languages /usr/share/phpmyadmin && \
    rm phpMyAdmin-5.2.0-all-languages.zip  && \
    # Configure PHPMyAdmin in Apache
    echo "<Directory /usr/share/phpmyadmin>" > /etc/apache2/conf-available/phpmyadmin.conf && \
    echo "    Options Indexes FollowSymLinks" >> /etc/apache2/conf-available/phpmyadmin.conf && \
    echo "    AllowOverride All" >> /etc/apache2/conf-available/phpmyadmin.conf && \
    echo "    Require all granted" >> /etc/apache2/conf-available/phpmyadmin.conf && \
    echo "</Directory>" >> /etc/apache2/conf-available/phpmyadmin.conf && \
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin && \
    a2enconf phpmyadmin && \
    # delete php7 -> configure servername
    rm /etc/apache2/mods-enabled/php7.* && \
    rm /etc/apache2/mods-available/php7.* && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    # Create php my admin config file
    touch /usr/share/phpmyadmin/config.inc.php && \
    echo "<?php" > /usr/share/phpmyadmin/config.inc.php && \
    # echo "\$cfg['Servers'][1]['host'] = 'localhost';" >> /usr/share/phpmyadmin/config.inc.php && \ NOT WORKING
    echo "\$cfg['Servers'][1]['host'] = '127.0.0.1';" >> /usr/share/phpmyadmin/config.inc.php && \
    echo "\$cfg['Servers'][1]['auth_type'] = 'cookie';" >> /usr/share/phpmyadmin/config.inc.php && \
    echo "\$cfg['blowfish_secret'] = 'focus_by_sanolivar_2024';" >> /usr/share/phpmyadmin/config.inc.php && \
    # Enable required php modules
    RUN a2enmod php8.3 && a2enmod rewrite

                            # INSTALL PENTAHO SPOON
# # Clone the official Pentaho Kettle repository from GitHub
# RUN git clone --depth 1 --branch master https://github.com/pentaho/pentaho-kettle.git /opt/pentaho-kettle
# # Change working directory to the cloned repository
# WORKDIR /opt/pentaho-kettle
# # Build the Pentaho Spoon binaries using Maven
# RUN mvn clean install -DskipTests

# # Extract the built binaries to the data-integration directory
# RUN unzip assembly/target/pdi-ce-*.zip -d /opt/data-integration && \
#     rm assembly/target/pdi-ce-*.zip
# WORKDIR /


# curl -I http://localhost:80/phpmyadmin
EXPOSE 3001 3307 8087 1883 1880 80 5901
# Iniciar servicios
ENTRYPOINT ["/init.sh"]