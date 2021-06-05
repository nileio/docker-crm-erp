FROM alpine:3.11
# downloads and install vtenext ce
# note: it also produces phpinfo.php file on the root for testing

LABEL maintainer="nileio@nileio.io"

ARG DUMB_INIT_VERSION=1.2.5
ARG PACKAGENAME=vtenext20ce.tgz
ENV TIMEZONE=Australia/Melbourne
# Set the lang, you can also specify it as as environment variable through docker-compose.yml
ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

ENV MYSQLROOT_PASSWORD="root" DATABASE_NAME=vtenext DBUSER_NAME=vtenextuser DBUSER_PASSWORD=stRongPass1rd

WORKDIR /tmp

# **** INSTALL ****
#REQUIRED PACKAGES INSTALLATION
RUN apk add --update --no-cache && apk upgrade && \
    apk add wget curl openssl tzdata \
    mysql mysql-client apache2 php7-apache2 \
    php7-cli php7-curl php7-gd php7-imagick php7-imap php7-ldap php7-mbstring \
    php7-phar php7-zlib php7-zip php7-bz2 php7-ctype php7-mysqli php7-pdo_mysql \
    php7-opcache php7-pdo php7-json php7-gmp php7-mcrypt php7-openssl php7-dom php7-xdebug \
    php7-simplexml php7-xml php7-iconv php7-fileinfo php7-posix php7-session php7-apcu php7-bcmath php7-intl php7-memcached \
    && rm -rf /var/cache/apk/*

#set server timezone
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone
# ****

# **** MYSQL ****
#initialise mysql db
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mysql_install_db  --skip-test-db --auth-root-authentication-method=normal --user=mysql --verbose=1 --basedir=/usr --datadir=/var/lib/mysql --rpm > /dev/null && \
    ln -s /usr/lib/libxml2.so.2 /usr/lib/libxml2.so
#configure mysql
COPY ./mariadb-cnf-overrides.conf /etc/my.cnf.d/mariadb-server.cnf
#create database
# Note: root user access from external host in the same network is enabled using GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQLROOT_PASSWORD}' WITH GRANT OPTION; \
# without this statement phpmyadmin or any other client on a different host cannot connect
# combine this with skip-networking (tcp level) option to close out root user access from any other host
RUN (nohup mysqld --bind-address 0.0.0.0 --user mysql > /dev/null 2>&1 &) && \
    mysqladmin --silent --wait=2 ping || exit 1 && \
    mysqladmin -uroot password "${MYSQLROOT_PASSWORD}" && \
    mysql -uroot -p"${MYSQLROOT_PASSWORD}" -e "CREATE DATABASE ${DATABASE_NAME} DEFAULT CHARACTER SET utf8 default collate utf8_general_ci;\
    CREATE USER ${DBUSER_NAME}@localhost IDENTIFIED BY '${DBUSER_PASSWORD}';\
    GRANT ALL PRIVILEGES ON ${DATABASE_NAME}.* TO ${DBUSER_NAME}@localhost; \
    DELETE FROM mysql.user WHERE User=''; \
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQLROOT_PASSWORD}' WITH GRANT OPTION; \
    GRANT PROXY ON ''@'%' TO 'root'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
# ****

# **** APACHE & PHP **** 
#APACHE: configure apache2
RUN sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf && \
    sed -i 's#ServerName www.example.com:80#\nServerName localhost:80#' /etc/apache2/httpd.conf && \
    sed -i 's#^DocumentRoot ".*#DocumentRoot "/www"#g' /etc/apache2/httpd.conf && \
    sed -i 's#/var/www/localhost/htdocs#/www#g' /etc/apache2/httpd.conf && \
    sed -i 's@^#LoadModule rewrite_module modules/mod_rewrite.so@LoadModule rewrite_module modules/mod_rewrite.so@g' /etc/apache2/httpd.conf && \
    sed -i 's@^#LoadModule ssl_module modules/mod_ssl.so@LoadModule ssl_module modules/mod_ssl.so@g'  /etc/apache2/httpd.conf && \
    mkdir -p /run/apache2 && \
    mkdir -p /tmp/sessions && \
    chown -R apache:apache /run/apache2 /tmp/sessions
#PHP-7: configure php7
COPY ./php-ini-overrides.ini /etc/php7/conf.d/
RUN mkdir -p /tmp/xdebug && chown -R apache:apache /tmp/xdebug
# ****

# **** START SCRIPT ****
# copy a start script for services
COPY ./start.sh /start.sh 
# Add dumb-init
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 && \
    chmod +x /usr/local/bin/dumb-init && \
    chmod u+x /start.sh 
# ****

# **** PACKAGE COPY ****
# download the package

RUN mkdir /www && wget https://sourceforge.net/projects/vtecrm/files/${PACKAGENAME} && \
    tar xzf vtenext20ce.tgz --strip-components=1 -C /www  && \
    chown -R apache:apache /www && \
    && rm vtenext20ce.tgz
#create phpinfo.php [remove this when you dont need it]
RUN echo "<?php phpinfo(); ?>" > /www/phpinfo.php
# ****

WORKDIR /www
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/dumb-init", "/start.sh"]
