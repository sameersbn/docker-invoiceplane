FROM sameersbn/php5-fpm:latest
MAINTAINER sameer@damagehead.com

ENV INVOICEPLANE_VERSION=1.4.4 \
    INVOICEPLANE_USER=${PHP_FPM_USER} \
    INVOICEPLANE_INSTALL_DIR=/var/www/invoiceplane \
    INVOICEPLANE_DATA_DIR=/var/lib/invoiceplane \
    INVOICEPLANE_CACHE_DIR=/etc/docker-invoiceplane

ENV INVOICEPLANE_BUILD_DIR=${INVOICEPLANE_CACHE_DIR}/build \
    INVOICEPLANE_RUNTIME_DIR=${INVOICEPLANE_CACHE_DIR}/runtime

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y php5-mysql php5-mcrypt mysql-client \
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
