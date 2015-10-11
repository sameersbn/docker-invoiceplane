FROM quay.io/sameersbn/php5-fpm:latest
MAINTAINER sameer@damagehead.com

ENV INVOICE_PLANE_VERSION=1.4.3 \
    INVOICE_PLANE_USER=${PHP_FPM_USER} \
    INVOICE_PLANE_INSTALL_DIR=/var/www/invoiceplane \
    INVOICE_PLANE_DATA_DIR=/var/lib/invoiceplane

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y php5-mysql php5-mcrypt mysql-client \
 && php5enmod mcrypt \
 && rm -rf /var/lib/apt/lists/*

COPY install.sh /var/cache/invoiceplane/install.sh
RUN bash /var/cache/invoiceplane/install.sh

COPY conf/ /var/cache/invoiceplane/conf/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

VOLUME ["${INVOICE_PLANE_INSTALL_DIR}", "${INVOICE_PLANE_DATA_DIR}"]

WORKDIR ${INVOICE_PLANE_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
