FROM ubuntu:16.04
MAINTAINER Andrew Beveridge <andrew@beveridge.uk>

ENV REFRESHED_AT 2017-05-20
ENV HTTPD_PREFIX /etc/apache2

LABEL maintainer="Andrew Beveridge <andrew@beveridge.uk>" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.name="Ubuntu 16.04 with Apache2.4 and PHP 7, optimised using PHP-FPM" \
      org.label-schema.url="https://andrewbeveridge.co.uk" \
      org.label-schema.vcs-url="https://github.com/beveradb/docker-apache-php7-fpm.git"

# Add repository for latest built PHP packages, e.g. 7.1 which isn't otherwise available in Xenial repositories
RUN add-apt-repository ppa:ondrej/php

# Install common / shared packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zip \
    unzip \
    vim \
    locales

# Set up locales
RUN locale-gen en_GB.UTF-8
RUN LANG=en_GB.UTF-8

# Install PHP 7.1 with FPM and other various commonly used modules, including MySQL client
RUN apt-get install -y --force-yes php7.1-bcmath php7.1-bz2 php7.1-cli php7.1-common php7.1-curl \
                php7.1-dev php7.1-fpm php7.1-gd php7.1-gmp php7.1-imap php7.1-intl \
                php7.1-json php7.1-ldap php7.1-mbstring php7.1-mcrypt php7.1-mysql \
                php7.1-odbc php7.1-opcache php7.1-pgsql php7.1-phpdbg php7.1-pspell \
                php7.1-readline php7.1-recode php7.1-soap php7.1-sqlite3 \
                php7.1-tidy php7.1-xml php7.1-xmlrpc php7.1-xsl php7.1-zip \
                libmysqlclient-dev mariadb-client

# Install Apache2 with FastCGI module
RUN apt-get install -y --force-yes apache2 libapache2-mod-fastcgi apache2-utils apache2-mpm-worker

# Modify PHP-FPM configuration files to set common properties and listen on port 9000
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/display_errors = Off/display_errors = On/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini

RUN sed -i -e "s/pid =.*/pid = \/var\/run\/php7.1-fpm.pid/" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i "s/listen = .*/listen = 9000/" /etc/php/7.1/fpm/pool.d/www.conf
RUN sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.1/fpm/pool.d/www.conf

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && chmod a+x /usr/local/bin/composer

# Remove default Apache VirtualHost, configs, and mods not needed
WORKDIR $HTTPD_PREFIX
RUN rm -f \
    	sites-enabled/000-default.conf \
    	conf-enabled/serve-cgi-bin.conf \
    	mods-enabled/autoindex.conf \
    	mods-enabled/autoindex.load

# Enable additional configs and mods
RUN ln -s $HTTPD_PREFIX/mods-available/expires.load $HTTPD_PREFIX/mods-enabled/expires.load \
    && ln -s $HTTPD_PREFIX/mods-available/headers.load $HTTPD_PREFIX/mods-enabled/headers.load \
	&& ln -s $HTTPD_PREFIX/mods-available/rewrite.load $HTTPD_PREFIX/mods-enabled/rewrite.load

# Enable Apache modules and configuration
RUN a2enmod actions fastcgi aliasi proxy_fcgi setenvif

# Clean up apt cache and temp files to save disk space
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND

