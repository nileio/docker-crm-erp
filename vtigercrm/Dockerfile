FROM ubuntu:latest

LABEL maintainer="nileio@nileio.com"

ARG DEBIAN_FRONTEND=noninteractive
#defaults that can be modified using env vars
ARG VTIGERVERSION=7.3.0
ARG MYSQL_ROOT_PASSWORD="root"
ARG DBUSER_PASSWORD="myStr0nGp@ss"


ENV VTIGERVERSION=${VTIGERVERSION}
ENV MYSQL_ALLOW_EMPTY_PASSWORD='yes' MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" DBUSER_PASSWORD="${DBUSER_PASSWORD}"
ENV PORT=80

WORKDIR /tmp

#install apache and php including required php modules for vtiger crm
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y wget && \
    apt-get install -y apache2 php php-imap php-curl php-xml php-mysql php-mbstring libapache2-mod-php

# configure php.ini for apache
RUN sed -i 's/memory_limit = .*/memory_limit = '256M'/' /etc/php/7.4/apache2/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = '60'/' /etc/php/7.4/apache2/php.ini && \
    sed -i 's/log_errors = .*/log_errors = 'Off'/' /etc/php/7.4/apache2/php.ini && \
    sed -i 's/display_errors = .*/display_errors = 'Off'/' /etc/php/7.4/apache2/php.ini && \
    sed -i 's/short_open_tag = .*/short_open_tag = 'Off'/' /etc/php/7.4/apache2/php.ini

# install mysql and configure
RUN apt-get install -y mysql-server && \
    apt-get install -y expect && \
    usermod -d /var/lib/mysql/ mysql && \
    mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld && \
    echo '[mysqld]\nsql_mode = NO_ENGINE_SUBSTITUTION' >> /etc/mysql/my.cnf && \
    echo 'local_infile = ON' >> /etc/mysql/my.cnf && \
    echo 'ServerName localhost' >> /etc/apache2/apache2.conf

#create database and user
#Grant all privileges to Vtiger database use on the Vtiger database.
#Reload the privileges table and exit the database;

RUN (mysqld_safe &) && \
    mysqladmin --silent --wait=5 ping || exit 1 && \
    mysql -uroot -e "CREATE DATABASE vtiger DEFAULT CHARACTER SET utf8 default collate utf8_general_ci; \
    CREATE USER vtigeradm@localhost IDENTIFIED WITH mysql_native_password BY '${DBUSER_PASSWORD}'; \
    GRANT ALL PRIVILEGES on vtiger.* TO vtigeradm@localhost;flush privileges;"


#secure mysql
COPY ./mysql_secure.sh mysql_secure.sh
RUN chmod +x /tmp/mysql_secure.sh && \
    /tmp/mysql_secure.sh "${MYSQL_ROOT_PASSWORD}"

#configure vtiger site

RUN wget https://sourceforge.net/projects/vtigercrm/files/vtiger%20CRM%20${VTIGERVERSION}/Core%20Product/vtigercrm${VTIGERVERSION}.tar.gz  && \
    mkdir /var/www/vtigercrm && \
    tar xzf vtigercrm${VTIGERVERSION}.tar.gz --strip-components=1 -C /var/www/vtigercrm/  && \
    chown -R www-data:www-data /var/www/vtigercrm/

# copy vtigercrm site configuration
COPY ./vtigercrm.conf /etc/apache2/sites-available/vtigercrm.conf


#Disable default Apache site & enable vtiger site;
#Enable Apache Rewrite Module;
RUN a2dissite 000-default.conf && \ 
    a2ensite vtigercrm.conf && \
    a2enmod rewrite


COPY ./start-services.sh /usr/bin/start-services.sh
RUN chmod +x /usr/bin/start-services.sh

CMD ["start-services.sh"]

EXPOSE 80

