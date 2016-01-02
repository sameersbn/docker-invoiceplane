#!/bin/bash
set -e

mkdir -p ${INVOICE_PLANE_INSTALL_DIR}

if [[ ! -f ${INVOICE_PLANE_BUILD_DIR}/invoiceplane-${INVOICE_PLANE_VERSION}.tar.gz ]]; then
  echo "Downloading InvoicePlane ${INVOICE_PLANE_VERSION}..."
  wget "https://github.com/InvoicePlane/InvoicePlane/archive/v${INVOICE_PLANE_VERSION}.tar.gz" \
    -O ${INVOICE_PLANE_BUILD_DIR}/invoiceplane-${INVOICE_PLANE_VERSION}.tar.gz
fi

echo "Extracting InvoicePlane ${INVOICE_PLANE_VERSION}..."
tar -xf ${INVOICE_PLANE_BUILD_DIR}/invoiceplane-${INVOICE_PLANE_VERSION}.tar.gz --strip=1 -C ${INVOICE_PLANE_INSTALL_DIR}
rm -rf ${INVOICE_PLANE_BUILD_DIR}/invoiceplane-${INVOICE_PLANE_VERSION}.tar.gz

(
  echo "default_charset = 'UTF-8'"
  echo "output_buffering = off"
  echo "date.timezone = {{INVOICE_PLANE_TIMEZONE}}"
) > ${INVOICE_PLANE_INSTALL_DIR}/.user.ini

# set directory permissions
find ${INVOICE_PLANE_INSTALL_DIR}/ -type f -print0 | xargs -0 chmod 0640
find ${INVOICE_PLANE_INSTALL_DIR}/ -type d -print0 | xargs -0 chmod 0750
chown -R root:${INVOICE_PLANE_USER} ${INVOICE_PLANE_INSTALL_DIR}/
chown -R ${INVOICE_PLANE_USER}:${INVOICE_PLANE_USER} ${INVOICE_PLANE_INSTALL_DIR}/application/config/
chown -R ${INVOICE_PLANE_USER}:${INVOICE_PLANE_USER} ${INVOICE_PLANE_INSTALL_DIR}/application/helpers/mpdf/tmp/
chown -R ${INVOICE_PLANE_USER}:${INVOICE_PLANE_USER} ${INVOICE_PLANE_INSTALL_DIR}/application/helpers/mpdf/ttfontdata/
chown -R ${INVOICE_PLANE_USER}:${INVOICE_PLANE_USER} ${INVOICE_PLANE_INSTALL_DIR}/application/helpers/mpdf/graph_cache/
chown -R ${INVOICE_PLANE_USER}:${INVOICE_PLANE_USER} ${INVOICE_PLANE_INSTALL_DIR}/application/logs/
chown root:${INVOICE_PLANE_USER} ${INVOICE_PLANE_INSTALL_DIR}/.user.ini
chmod 0644 ${INVOICE_PLANE_INSTALL_DIR}/.user.ini
