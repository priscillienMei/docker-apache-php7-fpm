FROM silintl/ubuntu:16.04
MAINTAINER Phillip Shipley <phillip_shipley@sil.org>

ENV REFRESHED_AT 2017-03-23
ENV HTTPD_PREFIX /etc/apache2

# install OS packages
RUN apt-get update && apt-get install -y \
    apache2 \
    curl \
    git \
    libapache2-mod-php \
    nano \
    netcat \
    php \
    php-cli \
    php-curl \
    php-dom \
    php-intl \
    php-json \
    php-ldap \
    php-mbstring \
    php-mcrypt \
    php-mysql \
    php-sqlite3 \
    php-zip \
    s3cmd \
    rsyslog-gnutls \
    && phpenmod mcrypt \
    && apt-get clean

# Install extra utils
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && chmod a+x /usr/local/bin/composer \
    && composer global require fxp/composer-asset-plugin:^1.3.1 \
    && curl -o /usr/local/bin/whenavail https://bitbucket.org/silintl/docker-whenavail/raw/master/whenavail \
    && chmod a+x /usr/local/bin/whenavail

# Remove default site, configs, and mods not needed
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

EXPOSE 80

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
