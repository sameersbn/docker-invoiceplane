#!/bin/bash
set -e

mkdir -p ${INVOICE_PLANE_INSTALL_DIR}
echo "Downloading InvoicePlane ${INVOICE_PLANE_VERSION}..."
wget "https://github.com/InvoicePlane/InvoicePlane/archive/v${INVOICE_PLANE_VERSION}.tar.gz" -O /tmp/invoice-plane-${INVOICE_PLANE_VERSION}.tar.gz
echo "Extracting InvoicePlane ${INVOICE_PLANE_VERSION}..."
tar -xf /tmp/invoice-plane-${INVOICE_PLANE_VERSION}.tar.gz --strip=1 -C ${INVOICE_PLANE_INSTALL_DIR}
rm -rf /tmp/invoice-plane-${INVOICE_PLANE_VERSION}.tar.gz

echo "Setting strong directory permissions..."
find ${INVOICE_PLANE_INSTALL_DIR}/ -type f -print0 | xargs -0 chmod 0640
find ${INVOICE_PLANE_INSTALL_DIR}/ -type d -print0 | xargs -0 chmod 0750

chown -R ${INVOICE_PLANE_USER}:${INVOICE_PLANE_USER} ${INVOICE_PLANE_INSTALL_DIR}/
