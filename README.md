# Docker Image: silintl/php7 #
I created this Docker image to start testing our apps with PHP7. 
If I did not include a module or something you need let me know by 
creating an issue or submitting a pull request. You'll notice I 
removed the default site so I could load in my own vhost config, 
so when you extend this you'll probably want to use ```ADD``` or 
```COPY``` to put a file into ```/etc/apache2/sites-enabled```.

# Getting Started #
A full tutorial on using Docker is way beyond the scope of this 
quick guide, but I'm happy to incorporate suggestions on how to 
make this more thorough and easy for people to get started with.

1. [Install Docker](https://docs.docker.com/installation/)
2. Start the Docker host - on Linux just start the docker service, 
   on Mac or Windows run ```boot2docker up```. You'll also need
   to setup your shell to know how to talk to the Docker host on 
   Mac/Win, on Mac this looks like running $(boot2docker shellinit)
   which will load the Docker host environment variables into your
   session to make it easier to interact with.
3. Download this Docker image by running ```docker pull silintl/php7```
4. Now you'll need to incorporate your application. The easiest way 
   to do that is to create a simple Dockerfile for your project
   that is based on this image. See below for an example.
5. Build a Docker image for your application by running ```docker build -t="namespace/app-name" .```
6. Finally, run your application as a Docker container by running:
   ```docker run -d -P namespace/app-name``` 
   
You can check if your 
   container is running by running ```docker ps``` and see what port
   80 got mapped to. Then you should be able to access your application
   in your browser by going to http://(DOCKER-IP-HERE):port
   
## Example Dockerfile for your application ##
```
FROM silintl/php7
MAINTAINER Your Name <your_email@domain.com>

ENV REFRESHED_AT 2015-05-11

# Copy an Apache vhost file into sites-enabled. This should map
# the document root to whatever is right for your app
COPY vhost-config.conf /etc/apache2/sites-enabled/

RUN mkdir -p /data
VOLUME ["/data"]

# Copy your application source into the image
COPY application/ /data/

WORKDIR /data
EXPOSE 80
CMD ["apache2ctl", "-D", "FOREGROUND"]
```

## Example vhost file ##
```
<VirtualHost *:80>
  ServerName myapp.local
  DocumentRoot /data/frontend/web/
  #RewriteEngine On
  DirectoryIndex index.php

  <Directory /data/frontend/web/>
    Options FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

  LogLevel info
  ErrorLog /var/log/apache2/myapp-error.log
  CustomLog /var/log/apache2/myapp-access.log combined

</VirtualHost>

<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>
```