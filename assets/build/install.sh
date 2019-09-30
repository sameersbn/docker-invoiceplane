#!/bin/bash
set -e

if [[ ! -f ${INVOICEPLANE_BUILD_DIR}/v${INVOICEPLANE_VERSION}.zip ]]; then
  echo "Downloading InvoicePlane ${INVOICEPLANE_VERSION}..."
  wget -nv "https://github.com/InvoicePlane/InvoicePlane/releases/download/v${INVOICEPLANE_VERSION}/v${INVOICEPLANE_VERSION}.zip" \
    -O ${INVOICEPLANE_BUILD_DIR}/v${INVOICEPLANE_VERSION}.zip
fi

echo "Extracting InvoicePlane ${INVOICEPLANE_VERSION}..."
unzip ${INVOICEPLANE_BUILD_DIR}/v${INVOICEPLANE_VERSION}.zip
mv ip ${INVOICEPLANE_INSTALL_DIR}

mv ${INVOICEPLANE_INSTALL_DIR}/uploads ${INVOICEPLANE_INSTALL_DIR}/uploads.template
mv ${INVOICEPLANE_INSTALL_DIR}/application/views/invoice_templates ${INVOICEPLANE_INSTALL_DIR}/application/views/invoice_templates.template
mv ${INVOICEPLANE_INSTALL_DIR}/application/views/quote_templates ${INVOICEPLANE_INSTALL_DIR}/application/views/quote_templates.template

rm -rf ${INVOICEPLANE_BUILD_DIR}/InvoicePlane-${INVOICEPLANE_VERSION}.tar.gz

(
  echo "default_charset = 'UTF-8'"
  echo "output_buffering = off"
  echo "date.timezone = {{INVOICEPLANE_TIMEZONE}}"
) > ${INVOICEPLANE_INSTALL_DIR}/.user.ini

mkdir -p /run/php/

# remove default nginx virtualhost
rm -rf /etc/nginx/sites-enabled/default

# set directory permissions
cp ${INVOICEPLANE_INSTALL_DIR}/ipconfig.php.example ${INVOICEPLANE_INSTALL_DIR}/ipconfig.php
find ${INVOICEPLANE_INSTALL_DIR}/ -type f -print0 | xargs -0 chmod 0640
find ${INVOICEPLANE_INSTALL_DIR}/ -type d -print0 | xargs -0 chmod 0750
chown -R root:${INVOICEPLANE_USER} ${INVOICEPLANE_INSTALL_DIR}/
chown -R ${INVOICEPLANE_USER}: ${INVOICEPLANE_INSTALL_DIR}/application/config/
chown -R ${INVOICEPLANE_USER}: ${INVOICEPLANE_INSTALL_DIR}/application/logs/
chown root:${INVOICEPLANE_USER} ${INVOICEPLANE_INSTALL_DIR}/.user.ini
chmod 0644 ${INVOICEPLANE_INSTALL_DIR}/.user.ini
chmod 0660 ${INVOICEPLANE_INSTALL_DIR}/ipconfig.php
chmod 1777 ${INVOICEPLANE_INSTALL_DIR}/vendor/mpdf/mpdf/tmp/
