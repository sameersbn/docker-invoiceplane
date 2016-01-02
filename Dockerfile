FROM sameersbn/php5-fpm:latest
MAINTAINER sameer@damagehead.com

ENV INVOICE_PLANE_VERSION=1.4.4 \
    INVOICE_PLANE_USER=${PHP_FPM_USER} \
    INVOICE_PLANE_INSTALL_DIR=/var/www/invoiceplane \
    INVOICE_PLANE_DATA_DIR=/var/lib/invoiceplane \
    INVOICE_PLANE_CACHE_DIR=/etc/docker-invoiceplane

ENV INVOICE_PLANE_BUILD_DIR=${INVOICE_PLANE_CACHE_DIR}/build \
    INVOICE_PLANE_RUNTIME_DIR=${INVOICE_PLANE_CACHE_DIR}/runtime

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y php5-mysql php5-mcrypt mysql-client \
 && php5enmod mcrypt \
 && rm -rf /var/lib/apt/lists/*

COPY assets/build/ ${INVOICE_PLANE_BUILD_DIR}/
RUN bash ${INVOICE_PLANE_BUILD_DIR}/install.sh

COPY assets/runtime/ ${INVOICE_PLANE_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

VOLUME ["${INVOICE_PLANE_INSTALL_DIR}", "${INVOICE_PLANE_DATA_DIR}"]

WORKDIR ${INVOICE_PLANE_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
