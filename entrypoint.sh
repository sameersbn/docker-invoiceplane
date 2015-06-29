#!/bin/bash
set -e

INVOICE_PLANE_FQDN=${INVOICE_PLANE_FQDN:-localhost}

DB_HOST=${DB_HOST:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}
DB_NAME=${DB_NAME:-}

# is a mysql container linked?
# requires that the mysql container has exposed port 3306
if [ -n "${MYSQL_PORT_3306_TCP_ADDR}" ]; then
  DB_TYPE=${DB_TYPE:-mysql}
  DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
  DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}

  # support for linked sameersbn/mysql image
  DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
  DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
  DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}

  # support for linked mysql, orchardup/mysql and enturylink/mysql image
  DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
  DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
  DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
fi

if [ -z "${DB_HOST}" ]; then
  echo "ERROR: "
  echo "  Please configure the database connection."
  echo "  Cannot continue without a database. Aborting..."
  exit 1
fi

# install nginx configuration, if not exists
if [ -d /etc/nginx/sites-enabled -a ! -f /etc/nginx/sites-enabled/${INVOICE_PLANE_FQDN}.conf ]; then
  cp /var/cache/invoice-plane/conf/nginx/InvoicePlane.conf /etc/nginx/sites-enabled/${INVOICE_PLANE_FQDN}.conf
  sed -i 's,{{INVOICE_PLANE_FQDN}},'"${INVOICE_PLANE_FQDN}"',' /etc/nginx/sites-enabled/${INVOICE_PLANE_FQDN}.conf
  sed -i 's,{{INVOICE_PLANE_INSTALL_DIR}},'"${INVOICE_PLANE_INSTALL_DIR}"',' /etc/nginx/sites-enabled/${INVOICE_PLANE_FQDN}.conf
fi

# due to the nature of docker and its use cases, we allow some time
# for the database server to come online before continuing
timeout=60
echo -n "Waiting for database server to accept connections"
while ! mysqladmin -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASS:+-p$DB_PASS} status >/dev/null 2>&1
do
  timeout=$(expr $timeout - 1)
  if [ $timeout -eq 0 ]; then
    echo
    echo "Could not connect to database server. Aborting..."
    exit 1
  fi
  echo -n "."
  sleep 1
done
echo

# create uploads directory
if [ ! -d ${INVOICE_PLANE_DATA_DIR}/uploads ]; then
  cp -a ${INVOICE_PLANE_INSTALL_DIR}/uploads ${INVOICE_PLANE_DATA_DIR}/uploads
fi
rm -rf ${INVOICE_PLANE_INSTALL_DIR}/uploads
ln -sf ${INVOICE_PLANE_DATA_DIR}/uploads ${INVOICE_PLANE_INSTALL_DIR}/uploads

# finalize ownership of the INVOICE_PLANE_DATA_DIR
chown -R ${INVOICE_PLANE_USER}:${INVOICE_PLANE_USER} ${INVOICE_PLANE_DATA_DIR}/

# apply database configuration
cp /var/cache/invoice-plane/conf/invoice-plane/database.php ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_HOST}}/'"${DB_HOST}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_USER}}/'"${DB_USER}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_PASS}}/'"${DB_PASS}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_NAME}}/'"${DB_NAME}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php

# create VERSION file, not used at the moment but might be required in the future
CURRENT_VERSION=
[ -f ${INVOICE_PLANE_DATA_DIR}/VERSION ] && CURRENT_VERSION=$(cat ${INVOICE_PLANE_DATA_DIR}/VERSION)
[ "${INVOICE_PLANE_VERSION}" != "${CURRENT_VERSION}" ] && echo -n "${INVOICE_PLANE_VERSION}" > ${INVOICE_PLANE_DATA_DIR}/VERSION

exec $@
