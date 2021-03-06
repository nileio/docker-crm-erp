# BUILDER ( xdebug, ssh2)
FROM alpine:3.7 as builder

RUN apk --no-cache add \
    gcc\
    libc-dev\
    autoconf\
    make\
    libssh2-dev\
    php5\
    php5-cli\
    php5-pear\
    php5-openssl\
    php5-dev

RUN ln -s /usr/bin/php5 /usr/bin/php && \
    pecl channel-update pecl.php.net && \
    pecl install ssh2-0.13

FROM alpine:3.7

LABEL maintainer="nileio@nileio.io"


ENV X2CRMVERSION=6.9
ENV DUMB_INIT_VERSION=1.2.5

ENV TIMEZONE=Australia/Melbourne
ENV PHP_MEMORY_LIMIT=512M
ENV MAX_UPLOAD=50M
ENV PHP_MAX_FILE_UPLOAD=200
ENV PHP_MAX_POST=100M

ENV X2CRMDBUSER_PASSWORD=strongPass1rd
ENV MYSQLROOT_PASSWORD="root"

RUN apk add --update --no-cache && apk upgrade && \
    apk add wget tzdata \
    mysql mysql-client apache2 \
    curl openssl \
    php5 php5-apache2 php5-openssl \
    php5-fpm php5-cli php5-mysql php5-pgsql php5-sqlite3 php5-phar \
    php5-apcu php5-intl php5-mcrypt php5-json php5-gd php5-curl \
    php5-zlib php5-zip php5-bz2 \
    php5-imap php5-iconv php5-imap php5-posix php5-pdo php5-ctype php5-pdo_mysql

COPY --from=builder /usr/lib/php5/modules/ssh2.so /usr/lib/php5/modules/
# add ssh and xdebug extensions.
# change xdebug configuration as required below
RUN echo "extension=ssh2.so" > /etc/php5/conf.d/ssh2.ini && \
    echo "zend_extension=xdebug.so" >  /etc/php5/conf.d/xdebug.ini &&\
    echo -e "\n[XDEBUG]"  >> /etc/php5/conf.d/xdebug.ini && \ 
    echo "xdebug.remote_autostart=On" >> /etc/php5/conf.d/xdebug.ini && \ 
    echo "xdebug.remote_host=host.docker.internal" >> /etc/php5/conf.d/xdebug.ini && \
    echo "xdebug.remote_enable=1" >> /etc/php5/conf.d/xdebug.ini && \  
    echo "xdebug.remote_connect_back=0" >> /etc/php5/conf.d/xdebug.ini && \ 
    echo "xdebug.idekey=VSCODE" >> /etc/php5/conf.d/xdebug.ini && \
    echo "xdebug.remote_log=\"/tmp/xdebug/xdebug.log\"" >> /etc/php5/conf.d/xdebug.ini


RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

#configure mysql
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mysql_install_db --user=mysql --verbose=1 --basedir=/usr --datadir=/var/lib/mysql --rpm > /dev/null && \
    echo 'Database initialized' && \
    sed -i '/skip-external-locking/a log_error = \/var\/lib\/mysql\/error.log' /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a general_log = ON' /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a general_log_file = \/var\/lib\/mysql\/query.log' /etc/mysql/my.cnf && \
    sed -i 's|.*skip-networking.*|skip-networking|g' /etc/mysql/my.cnf && \
    ln -s /usr/lib/libxml2.so.2 /usr/lib/libxml2.so

#configure apache & php
RUN sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf && \
    sed -i 's#ServerName www.example.com:80#\nServerName localhost:80#' /etc/apache2/httpd.conf && \
    sed -i 's#^DocumentRoot ".*#DocumentRoot "/www"#g' /etc/apache2/httpd.conf && \
    sed -i 's#/var/www/localhost/htdocs#/www#g' /etc/apache2/httpd.conf && \
    sed -i 's@^#LoadModule rewrite_module modules/mod_rewrite.so@LoadModule rewrite_module modules/mod_rewrite.so@g' /etc/apache2/httpd.conf && \
    sed -i 's@^#LoadModule ssl_module modules/mod_ssl.so@LoadModule ssl_module modules/mod_ssl.so@g'  /etc/apache2/httpd.conf && \
    sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php${PHP_VERSION}/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php${PHP_VERSION}/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php${PHP_VERSION}/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php${PHP_VERSION}/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php${PHP_VERSION}/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php${PHP_VERSION}/php.ini && \
    sed -i "s|;*session.save_path =.*|session.save_path= /tmp/sessions|i" /etc/php${PHP_VERSION}/php.ini && \ 
    mkdir -p /run/apache2 && \
    mkdir -p /tmp/sessions && \
    chown -R apache:apache /run/apache2 /tmp/sessions


# create a start script for apache and mysql
# it creates a db called db on mysql start
RUN echo "#!/bin/sh" > /start.sh && \
    echo "httpd" >> /start.sh && \
    echo "nohup mysqld --skip-grant-tables --bind-address 0.0.0.0 --user mysql > /dev/null 2>&1 &" >> /start.sh && \
    echo "sleep 3 && mysql -uroot -e \"CREATE DATABASE x2crm;CREATE USER x2crmuser@localhost IDENTIFIED BY '${X2CRMDBUSER_PASSWORD}';GRANT ALL ON x2crm.* TO x2crmuser@localhost;\"" >> /start.sh && \
    echo "mysqladmin -uroot password ${MYSQLROOT_PASSWORD}" >> /start.sh && \
    echo "tail -f /var/log/apache2/access.log" >> /start.sh && \
    chmod u+x /start.sh

# Add dumb-init

RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 && \
    chmod +x /usr/local/bin/dumb-init

#

RUN wget https://phoenixnap.dl.sourceforge.net/project/x2engine/X2CRM-${X2CRMVERSION}.zip && \
    unzip X2CRM-${X2CRMVERSION}.zip -oq  && \
    mv x2engine /www && \
    sed -i '/^#.*SetEnv HTTP_MOD_REWRITE 1/s/^#//' /www/.htaccess && \
    chown -R apache:apache /www

WORKDIR /www

EXPOSE 80


ENTRYPOINT ["/usr/local/bin/dumb-init", "/start.sh"]
