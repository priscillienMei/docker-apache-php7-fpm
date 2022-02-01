FROM ubuntu:20.04
MAINTAINER Adam <>

ENV REFRESHED_AT 2021-09-02
ENV HTTPD_PREFIX=/etc/apache2 \ 
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid 

# Dont prompt for any installs
# The ARG directive sets variables that only live during the build
ARG DEBIAN_FRONTEND=noninteractive
ARG HOME="/root"

LABEL maintainer="tecfu <>" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.name="Ubuntu 20.04 with Apache2.4 and PHP 7.4, optimised using PHP-FPM" \
      org.label-schema.url="https://twitter.com/tecfu0" \
      org.label-schema.vcs-url="https://github.com/priscillienMei/docker-apache-php7-fpm.git"

# Initial apt update
RUN apt-get update && apt-get install -y apt-utils

# Install common / shared packages
RUN apt-get install -y \
    curl \
    git \
    zip \
    unzip \
    locales \
    software-properties-common

# Set up locales
RUN locale-gen en_US.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8
RUN /usr/sbin/update-locale

# Add repositories 

# nodejs repo
#RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

# RUN add-apt-repository -y ppa:pi-rho/dev

# PHP repo
RUN add-apt-repository -y ppa:ondrej/php

RUN apt-get update

# Install vim 8 
RUN apt install vim -y

# Install Vim plugins
#RUN vim +PlugInstall +qall 
#RUN apt-get install -y vim 

# Install tmux
RUN apt-get -y install tmux

# Install nodejs, pm2 for API daemonization
#RUN apt-get install -y nodejs 
#RUN npm install pm2 -g

# Install PHP 7.4 with FPM and other various commonly used modules, including MySQL client
RUN apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
                php7.4-bcmath php7.4-bz2 php7.4-cli php7.4-common php7.4-curl \
                php7.4-dev php7.4-fpm php7.4-gd php7.4-gmp php7.4-imap php7.4-intl \
                php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql \
                php7.4-odbc php7.4-opcache php7.4-pgsql php7.4-phpdbg php7.4-pspell \
                php7.4-readline php7.4-recode php7.4-soap php7.4-sqlite3 \
                php7.4-tidy php7.4-xml php7.4-xmlrpc php7.4-xsl php7.4-zip

# Install Apache2 with FastCGI module and MySQL client for convenience
RUN apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
                apache2 apache2-utils \
                libmysqlclient-dev mysql-client

# Modify PHP-FPM configuration files to set common properties and listen on socket
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.4/cli/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.4/fpm/php.ini
RUN sed -i "s/display_errors = Off/display_errors = On/" /etc/php/7.4/fpm/php.ini
RUN sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/" /etc/php/7.4/fpm/php.ini
RUN sed -i "s/post_max_size = .*/post_max_size = 52M/" /etc/php/7.4/fpm/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.4/fpm/php.ini

RUN sed -i "s/pid =.*/pid = \/var\/run\/php7.4-fpm.pid/" /etc/php/7.4/fpm/php-fpm.conf
RUN sed -i "s/error_log =.*/error_log = \/var\/log\/php_error.log/" /etc/php/7.4/fpm/php-fpm.conf
# RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf
RUN sed -i "s/listen = .*/listen = \/var\/run\/php\/php7.4-fpm.sock/" /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.4/fpm/pool.d/www.conf

# Append error log value for PHP-CLI scripts
RUN echo "error_log = /var/log/php_cli_errors.log" >> /etc/php/7.4/cli/php.ini
RUN touch /var/log/php_cli_errors.log 

# Install Composer globally
#RUN curl -S https://getcomposer.org/installer | php \
#    && mv composer.phar /usr/local/bin/composer \
#    && chmod a+x /usr/local/bin/composer

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

# Configure Apache to use our PHP-FPM socket for all PHP files
COPY php7.4-fpm.conf /etc/apache2/conf-available/php7.4-fpm.conf
RUN a2enconf php7.4-fpm

# Enable Apache modules and configuration
RUN a2dismod mpm_event
RUN a2enmod alias actions proxy_fcgi setenvif mpm_worker

# Symlink apache access and error logs to stdout/stderr so Docker logs shows them
RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log

# EXPOSE 80 9000 3000


# Terminal, Vim Customization
WORKDIR $HOME
RUN git clone https://github.com/tecfu/dotfiles 

# Create symlinks to bash config
RUN mv $HOME/.bashrc $HOME/.bashrc.saved
RUN ln -s $HOME/dotfiles/terminal/.bashrc $HOME/.bashrc
RUN ln -s $HOME/dotfiles/terminal/.inputrc $HOME/.inputrc

# Vim
# Create symlinks to vim config
RUN ln -s $HOME/dotfiles/.vim $HOME/.vim
RUN ln -s $HOME/dotfiles/.vim/.vimrc $HOME/.vimrc

# Change apache's index priority
RUN echo "<Directory /var/www/>\nDirectoryIndex index.php index.html\n</Directory>" \
  >> /etc/apache2/apache2.conf

# Clean up apt cache and temp files to save disk space
# RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get clean && apt-get autoremove -y

# Run the following scripts when container is started
COPY ./boot.sh $HOME/boot.sh
RUN chmod +x $HOME/boot.sh
ENTRYPOINT $HOME"/boot.sh"
