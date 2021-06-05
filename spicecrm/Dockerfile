FROM alpine:3.11

LABEL maintainer="nileio@nileio.io"

ARG DUMB_INIT_VERSION=1.2.5
ARG PACKAGENAME=spicecrm.tgz
ENV TIMEZONE=Australia/Melbourne
# Set the lang, you can also specify it as as environment variable 
# through docker-compose.yml
ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8
#find a way to remove those environments so they dont show up in server
ENV MYSQLROOT_PASSWORD="root"
#DATABASE_NAME=spicecrm DBUSER_NAME=spicecrmuser DBUSER_PASSWORD=stRongPass1rd

WORKDIR /tmp

# **** INSTALL **** 
#REQUIRED PACKAGES INSTALLATION
RUN apk add --update --no-cache && apk upgrade && \
    apk add wget curl openssl git tzdata \
    mysql mysql-client apache2 php7-apache2 \
    php7-cli php7-curl php7-gd php7-imagick php7-imap php7-ldap php7-mbstring \
    php7-phar php7-zlib php7-zip php7-bz2 php7-ctype php7-mysqli php7-pdo_mysql \
    php7-opcache php7-pdo php7-json php7-mcrypt php7-openssl php7-xdebug \
    php7-iconv php7-fileinfo php7-posix php7-session php7-apcu php7-bcmath php7-intl \
    php7-simplexml php7-xml  \
    su-exec elasticsearch

#RUN curl -sS https://getcomposer.org/installer | \
#   php -- --install-dir=/usr/bin --filename=composer

#set server timezone
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone
#this is required only if you want to install different locales in the server so locale -a returns locales
# we dont need it
#ENV MUSL_LOCPATH=/usr/local/share/i18n/locales/musl
#RUN apk add --update git cmake make musl-dev gcc gettext-dev libintl && \ 
#    git clone https://gitlab.com/rilian-la-te/musl-locales.git && \ 
#    cd musl-locales && cmake . && make && make install
# ****

# **** MYSQL **** 

#initialise mysql db
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mysql_install_db --skip-test-db --auth-root-authentication-method=normal --user=mysql --verbose=1 --basedir=/usr --datadir=/var/lib/mysql --rpm > /dev/null && \
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
    mysql -uroot -p"${MYSQLROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQLROOT_PASSWORD}' WITH GRANT OPTION; \
    GRANT PROXY ON ''@'%' TO 'root'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
# ****

# **** ELASTICSEARCH **** 
#configure elasticsearch
RUN cd /usr/share/java/elasticsearch && mkdir data && rm plugins && mkdir plugins && \
    ln -s /etc/elasticsearch/ config && chown -R elastico:elastico ../elasticsearch /etc/elasticsearch && \
    sed -i 's#path.data: /path/to/data#\npath.data: /usr/share/java/elasticsearch/data#' /etc/elasticsearch/elasticsearch.yml
ENV PATH /usr/share/java/elasticsearch/bin/:$PATH
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
# enable this if you will NOT use phpmyadmin
#  sed -i 's|.*skip-networking.*|skip-networking|g' /etc/mysql/my.cnf && \
RUN mkdir -p /tmp/xdebug && chown -R apache:apache /tmp/xdebug
# ****

# **** START SCRIPT ****
# create a start script
RUN echo "#!/bin/sh" > /start.sh && \
    echo "httpd" >> /start.sh && \
    echo "nohup mysqld --bind-address 0.0.0.0 --user mysql > /dev/null 2>&1 &" >> /start.sh && \
    echo "su-exec elastico elasticsearch > /dev/null 2>&1 &" >> /start.sh && \
    echo "tail -f /var/log/apache2/access.log" >> /start.sh && \
    chmod u+x /start.sh

# Add dumb-init
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 && \
    chmod +x /usr/local/bin/dumb-init

# ****

# **** PACKAGE COPY ****
# download or COPY the package
#https://janakerman.co.uk/docker-git-clone/
#COPY ./${PACKAGENAME} ${PACKAGENAME}
RUN git clone https://github.com/spicecrm/spicecrm && \
    mv spicecrm /www && \
    chown -R apache:apache /www && \
    apk del git

# create phpinfo.php [remove this when you dont need it]
RUN echo "<?php phpinfo(); ?>" > /www/phpinfo.php
# ****

WORKDIR /www

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/dumb-init", "/start.sh"]
