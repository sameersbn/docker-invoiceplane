FROM sameersbn/php5-fpm:latest
MAINTAINER sameer@damagehead.com

ENV INVOICEPLANE_VERSION=1.4.4 \
    INVOICEPLANE_USER=${PHP_FPM_USER} \
    INVOICEPLANE_INSTALL_DIR=/var/www/invoiceplane \
    INVOICEPLANE_DATA_DIR=/var/lib/invoiceplane \
    INVOICEPLANE_CACHE_DIR=/etc/docker-invoiceplane

ENV INVOICEPLANE_BUILD_DIR=${INVOICEPLANE_CACHE_DIR}/build \
    INVOICEPLANE_RUNTIME_DIR=${INVOICEPLANE_CACHE_DIR}/runtime

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      php5-mysql php5-mcrypt mysql-client nginx \
 && php5enmod mcrypt \
 && rm -rf /var/lib/apt/lists/*

COPY assets/build/ ${INVOICEPLANE_BUILD_DIR}/
RUN bash ${INVOICEPLANE_BUILD_DIR}/install.sh

COPY assets/runtime/ ${INVOICEPLANE_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

VOLUME ["${INVOICEPLANE_INSTALL_DIR}", "${INVOICEPLANE_DATA_DIR}"]

WORKDIR ${INVOICEPLANE_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:invoiceplane"]
