#!/bin/sh
httpd
nohup mysqld --bind-address 0.0.0.0 --user mysql >/dev/null 2>&1 &
tail -f /var/log/apache2/access.log
