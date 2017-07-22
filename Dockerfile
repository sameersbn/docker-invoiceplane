FROM sameersbn/ubuntu:14.04.20170123
MAINTAINER sameer@damagehead.com

ENV PHP_VERSION=7.0 \
    INVOICEPLANE_VERSION=1.5.3 \
    INVOICEPLANE_USER=www-data \
    INVOICEPLANE_INSTALL_DIR=/var/www/invoiceplane \
    INVOICEPLANE_DATA_DIR=/var/lib/invoiceplane \
    INVOICEPLANE_CACHE_DIR=/etc/docker-invoiceplane

ENV INVOICEPLANE_BUILD_DIR=${INVOICEPLANE_CACHE_DIR}/build \
    INVOICEPLANE_RUNTIME_DIR=${INVOICEPLANE_CACHE_DIR}/runtime

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 14AA40EC0831756756D7F66C4F4EA0AAE5267A6C \
 && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-mysql \
      php${PHP_VERSION}-gd php${PHP_VERSION}-json php${PHP_VERSION}-mbstring \
      php${PHP_VERSION}-mcrypt php${PHP_VERSION}-recode php${PHP_VERSION}-xmlrpc \      
      php${PHP_VERSION}-curl mysql-client nginx gettext-base git \
      nano curl \
 && sed -i 's/^listen = .*/listen = 0.0.0.0:9000/' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
 && phpenmod -v ALL mcrypt \
 && wget -nv "https://getcomposer.org/composer.phar" -O /usr/local/bin/composer \
 && chmod +x /usr/local/bin/composer \
 && rm -rf /var/lib/apt/lists/* \
 && curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - \
 && apt-get install -y nodejs
 
COPY assets/build/ ${INVOICEPLANE_BUILD_DIR}/
RUN bash ${INVOICEPLANE_BUILD_DIR}/install.sh

COPY assets/runtime/ ${INVOICEPLANE_RUNTIME_DIR}/
COPY assets/tools/ /usr/bin/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

VOLUME ["${INVOICEPLANE_DATA_DIR}"]
WORKDIR ${INVOICEPLANE_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:invoiceplane"]

EXPOSE 9000
