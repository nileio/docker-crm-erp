FROM ubuntu:latest

LABEL maintainer="nileio@nileio.com"

ARG DEBIAN_FRONTEND=noninteractive
ARG DUMB_INIT_VERSION=1.2.5

ARG MYSQL_ROOT_PASSWORD=root
ARG DBUSER_PASSWORD=stRongPass1rd

ENV PHP_MEMORY_LIMIT=256M
ENV MAX_UPLOAD=50M
ENV PHP_MAX_FILE_UPLOAD=200
ENV PHP_MAX_POST=100M
ENV TIMEZONE=Australia/Melbourne

ENV DATABASE_NAME=vtenext
ENV DBUSER_NAME=vtenextuser

ENV MYSQL_ALLOW_EMPTY_PASSWORD='yes' MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} DBUSER_PASSWORD=${DBUSER_PASSWORD}

WORKDIR /tmp

#install apache and php including required php modules for vtiger crm
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y wget expect && \
    apt-get install -y apache2 mysql-server && \
    apt-get install -y php php-cli php-gd php-apcu php-memcached php-intl php-bcmath \
    php-imap php-ldap php-mysql php-curl php-imagick php-mbstring php-xml libapache2-mod-php
#configure mysql
RUN usermod -d /var/lib/mysql/ mysql && \
    mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld && \
    echo '[mysqld]\nsql_mode = NO_ENGINE_SUBSTITUTION' >> /etc/mysql/my.cnf && \
    echo 'local_infile = ON' >> /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a log_error = \/var\/lib\/mysql\/error.log' /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a general_log = ON' /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a general_log_file = \/var\/lib\/mysql\/query.log' /etc/mysql/my.cnf && \
    #   sed -i 's|.*skip-networking.*|skip-networking|g' /etc/mysql/my.cnf && \
    ln -s /usr/lib/libxml2.so.2 /usr/lib/libxml2.so

#configure apache2
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# configure php.ini
RUN sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/display_errors = Off/display_errors = On/g" /etc/php/7.4/apache2/php.ini && \
    sed -i 's/log_errors = .*/log_errors = 'On'/' /etc/php/7.4/apache2/php.ini && \
    sed -i "s/short_open_tag = Off/short_open_tag = On/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s/max_execution_time = 30/max_execution_time = 600/g" /etc/php/7.4/apache2/php.ini && \
    sed -i 's/^error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/' /etc/php/7.4/apache2/php.ini && \
    sed -i "s/bcmath.scale = 0/bcmath.scale = 2/g" /etc/php/7.4/apache2/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php/7.4/apache2/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php/7.4/apache2/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php/7.4/apache2/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php/7.4/apache2/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php/7.4/apache2/php.ini && \
    sed -i "s|;*session.save_path =.*|session.save_path= /tmp/sessions|i" /etc/php/7.4/apache2/php.ini && \
    mkdir -p /tmp/sessions

#secure mysql
COPY ./mysql_secure.sh mysql_secure.sh
RUN chmod +x /tmp/mysql_secure.sh 
#&& \
#    /tmp/mysql_secure.sh "${MYSQL_ROOT_PASSWORD}"

#create database
RUN (mysqld_safe &) && \
    mysqladmin --silent --wait=5 ping || exit 1 && \
    mysql -uroot -e "CREATE DATABASE ${DATABASE_NAME} DEFAULT CHARACTER SET utf8 default collate utf8_general_ci; \
    CREATE USER ${DBUSER_NAME}@localhost IDENTIFIED BY '${DBUSER_PASSWORD}'; \
    GRANT ALL PRIVILEGES on ${DATABASE_NAME}.* TO ${DBUSER_NAME}@localhost;FLUSH PRIVILEGES;"



RUN wget https://sourceforge.net/projects/vtecrm/files/vtenext20ce.tgz  && \
    mkdir /var/www/vtenext && \
    tar xzf vtenext20ce.tgz --strip-components=1 -C /var/www/vtenext/  && \
    chown -R www-data:www-data /var/www/vtenext /tmp/sessions && \
    rm vtenext20ce.tgz

# copy site configuration
COPY ./site.conf /etc/apache2/sites-available/site.conf


#Disable default Apache site & enable site;
#Enable Apache Rewrite Module;
RUN phpenmod imap && \
    a2dissite 000-default.conf && \ 
    a2ensite site.conf && \
    a2enmod rewrite && dpkg-reconfigure libapache2-mod-php



RUN echo "#!/bin/sh" > /start.sh && \
    echo "mysqld_safe &" >> /start.sh && \
    echo "apachectl start" >> /start.sh && \
    echo "tail -f /var/log/apache2/access.log" >> /start.sh && \
    chmod u+x /start.sh

# Add dumb-init
#RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 && \
#    chmod +x /usr/local/bin/dumb-init

WORKDIR /var/www

COPY ./start.sh /usr/bin/start.sh
RUN chmod +x /usr/bin/start.sh

CMD ["start.sh"]

EXPOSE 80




