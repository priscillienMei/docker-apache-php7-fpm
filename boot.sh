#!/bin/bash
#if [ ! -d "$APACHE_RUN_DIR" ]; then
#	mkdir "$APACHE_RUN_DIR"
#	chown $APACHE_RUN_USER:$APACHE_RUN_GROUP "$APACHE_RUN_DIR"
#fi

if [ -f "$APACHE_PID_FILE" ]; then
  # remove stale apache PID file left behind when docker stops container
	rm -f "$APACHE_PID_FILE"
fi

# Start PHP-FPM worker service and run Apache in foreground so any error output is sent to stdout for Docker logs
service php7.1-fpm start && /usr/sbin/apache2ctl -D FOREGROUND

#/usr/sbin/apache2ctl -D FOREGROUND
