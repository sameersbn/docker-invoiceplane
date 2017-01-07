#!/bin/bash
set -e

mkdir -p ${INVOICEPLANE_INSTALL_DIR}

if [[ ! -f ${INVOICEPLANE_BUILD_DIR}/InvoicePlane-${INVOICEPLANE_VERSION}.tar.gz ]]; then
  echo "Downloading InvoicePlane ${INVOICEPLANE_VERSION}..."
  wget -nv "https://github.com/InvoicePlane/InvoicePlane/archive/v${INVOICEPLANE_VERSION}.tar.gz" \
    -O ${INVOICEPLANE_BUILD_DIR}/InvoicePlane-${INVOICEPLANE_VERSION}.tar.gz
fi

echo "Extracting InvoicePlane ${INVOICEPLANE_VERSION}..."
tar -xf ${INVOICEPLANE_BUILD_DIR}/InvoicePlane-${INVOICEPLANE_VERSION}.tar.gz --strip=1 -C ${INVOICEPLANE_INSTALL_DIR}
mv ${INVOICEPLANE_INSTALL_DIR}/uploads ${INVOICEPLANE_INSTALL_DIR}/uploads.template
rm -rf ${INVOICEPLANE_BUILD_DIR}/InvoicePlane-${INVOICEPLANE_VERSION}.tar.gz

echo "Installing composer dependencies..."
cd ${INVOICEPLANE_INSTALL_DIR}
composer install --prefer-source --no-interaction --no-dev -o

(
  echo "default_charset = 'UTF-8'"
  echo "output_buffering = off"
  echo "date.timezone = {{INVOICEPLANE_TIMEZONE}}"
) > ${INVOICEPLANE_INSTALL_DIR}/.user.ini

mkdir -p /run/php/

# remove default nginx virtualhost
rm -rf /etc/nginx/sites-enabled/default

# set directory permissions
find ${INVOICEPLANE_INSTALL_DIR}/ -type f -print0 | xargs -0 chmod 0640
find ${INVOICEPLANE_INSTALL_DIR}/ -type d -print0 | xargs -0 chmod 0750
chown -R root:${INVOICEPLANE_USER} ${INVOICEPLANE_INSTALL_DIR}/
chown -R ${INVOICEPLANE_USER}: ${INVOICEPLANE_INSTALL_DIR}/application/config/
chown -R ${INVOICEPLANE_USER}: ${INVOICEPLANE_INSTALL_DIR}/application/logs/
chown root:${INVOICEPLANE_USER} ${INVOICEPLANE_INSTALL_DIR}/.user.ini
chmod 0644 ${INVOICEPLANE_INSTALL_DIR}/.user.ini
