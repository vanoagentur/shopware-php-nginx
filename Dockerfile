FROM ubuntu:xenial

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get autoclean && apt-get update -qqy && apt-get install -qqy software-properties-common python-software-properties



# Add colours to bashrc
RUN  sed -i -e "s/#force_color_prompt=yes/force_color_prompt=yes/g" /root/.bashrc

# Install nginx
RUN nginx=stable && \
    add-apt-repository ppa:nginx/$nginx && \
    apt-get update && \
    apt-get install -qqy nginx


# Install php7 packages
RUN apt-get install -y language-pack-en-base && export LC_ALL=en_US.UTF-8 && export LANG=en_US.UTF-8 && add-apt-repository ppa:ondrej/php && apt-get update -qqy && \
    apt-get install -qqy \
    php7.1-fpm \
    php7.1-cli \
    php7.1-common \
    php7.1-curl \
    php7.1-json \
    php7.1-gd \
    php7.1-mcrypt \
    php7.1-mbstring \
    php7.1-odbc \
    php7.1-pgsql \
    php7.1-mysql \
    php7.1-sqlite3 \
    php7.1-xmlrpc \
    php7.1-opcache \
    php7.1-intl \
    php7.1-xml \
    php7.1-soap \
    php7.1-zip \
    php7.1-bz2 \
    php7.1-dev 


RUN apt-get update && apt-get install -qqy \
        libfreetype6-dev \        
        libmcrypt-dev \
        libpng12-dev \      
        imagemagick \
        libxslt-dev \
        libcurl4-gnutls-dev \
        unzip \
        wget \
        mysql-client \
        php-pear \
        libssl-dev
    # && docker-php-ext-install iconv \
    #             mcrypt \
    #             opcache \
    #             zip \
    #             curl \
    #             pdo \
    #             pdo_mysql \
    #             mbstring \
    #             soap \
    #             ftp \
    # && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    # && docker-php-ext-install gd \
    # && rm -rf /var/lib/apt/lists/*


RUN apt-get update && apt-get install -y libmagickwand-6.q16-dev --no-install-recommends \
    && ln -s /usr/lib/x86_64-linux-gnu/ImageMagick-6.8.9/bin-Q16/MagickWand-config /usr/bin/ \
    && pecl install imagick \
    && echo "extension=imagick.so" >  /etc/php/7.1/fpm/conf.d/20-imagick.ini \
    && pecl install apcu \
    && echo "extension=apcu.so" > /etc/php/7.1/fpm/conf.d/20-apcu.ini \
    && rm -rf /var/lib/apt/lists/*


 # Install other software
RUN add-apt-repository universe && apt-get update && apt-get install -qqy \    
    curl \
    mysql-client \
    git \
    supervisor 
   

# tweak nginx config
RUN sed -i -e "s/worker_processes  1/worker_processes 5/" /etc/nginx/nginx.conf && \
    sed -i -e "s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
    sed -i -e "s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.1/fpm/php.ini && \    
    sed -i -e "s/cgi.fix_pathinfo=0/cgi.fix_pathinfo=1/g" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.1/cli/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.1/cli/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/;clear_env = no/clear_env = no/g" /etc/php/7.1/fpm/pool.d/www.conf

# fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    find /etc/php/7.1/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# nginx site conf
RUN rm -Rf /etc/nginx/conf.d/* && \
    rm -Rf /etc/nginx/sites-available/default && \
    mkdir -p /etc/nginx/ssl/
ADD ./conf/nginx-site.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf


# Install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer global require hirak/prestissimo

#IONCUBE LOADER
RUN wget -O /tmp/php7-linux-x86-64-beta8.tgz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
RUN tar xvzfC /tmp/php7-linux-x86-64-beta8.tgz /tmp/ \
    && rm /tmp/php7-linux-x86-64-beta8.tgz \
    && mkdir -p /usr/local/ioncube \
    && cp /tmp/ioncube/ioncube_loader_lin_7.1.so /usr/local/ioncube \
    && rm -rf /tmp/ioncube_loader_lin_x86-64_7.0b8.so /tmp/README_PHP7_X86_64_BETA \
    && echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.1.so" >>  /etc/php/7.1/fpm/php.ini



# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# Supervisor Config
ADD ./conf/supervisord.conf /etc/supervisord.conf

# Start Supervisord
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

RUN usermod -u 1000 www-data
RUN usermod -a -G users www-data

RUN mkdir -p /var/www/html
RUN chown -R www-data:www-data /var/www

# add test PHP file
#ADD ./index.php /var/www/html/index.php

RUN mkdir /run/php && chown www-data:www-data -R /run/php

WORKDIR /var/www/html

# Expose Ports
EXPOSE 443
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]