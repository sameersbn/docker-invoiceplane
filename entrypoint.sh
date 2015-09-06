#!/bin/bash
set -e

INVOICE_PLANE_FQDN=${INVOICE_PLANE_FQDN:-localhost}
INVOICE_PLANE_TIMEZONE=${INVOICE_PLANE_TIMEZONE:-UTC}

DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}
DB_NAME=${DB_NAME:-}

create_data_dir() {
  mkdir -p ${INVOICE_PLANE_DATA_DIR}
  chmod -R 0755 ${INVOICE_PLANE_DATA_DIR}

  if [[ ! -d ${INVOICE_PLANE_DATA_DIR}/uploads ]]; then
    cp -a ${INVOICE_PLANE_INSTALL_DIR}/uploads ${INVOICE_PLANE_DATA_DIR}/uploads
  fi

  rm -rf ${INVOICE_PLANE_INSTALL_DIR}/uploads
  ln -sf ${INVOICE_PLANE_DATA_DIR}/uploads ${INVOICE_PLANE_INSTALL_DIR}/uploads
  chown -R ${INVOICE_PLANE_USER}:${INVOICE_PLANE_USER} ${INVOICE_PLANE_DATA_DIR}
}

create_vhost_configuration() {
  # install nginx configuration, if not exists
  if [[ -d /etc/nginx/sites-enabled && ! -f /etc/nginx/sites-enabled/${INVOICE_PLANE_FQDN}.conf ]]; then
    cp /var/cache/invoiceplane/conf/nginx/InvoicePlane.conf /etc/nginx/sites-enabled/${INVOICE_PLANE_FQDN}.conf
    sed -i 's,{{INVOICE_PLANE_FQDN}},'"${INVOICE_PLANE_FQDN}"',' /etc/nginx/sites-enabled/${INVOICE_PLANE_FQDN}.conf
    sed -i 's,{{INVOICE_PLANE_INSTALL_DIR}},'"${INVOICE_PLANE_INSTALL_DIR}"',' /etc/nginx/sites-enabled/${INVOICE_PLANE_FQDN}.conf
  fi
}

autodetect_database_connection_parameters() {
  # is a mysql container linked?
  if [[ -n ${MYSQL_PORT_3306_TCP_ADDR} ]]; then
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

  DB_PORT=${DB_PORT:-3306}
  if [[ -z ${DB_HOST} ]]; then
    echo "ERROR: "
    echo "  Please configure the database connection."
    echo "  Cannot continue without a database. Aborting..."
    exit 1
  fi

  # due to the nature of docker and its use cases, we allow some time
  # for the database server to come online before continuing
  timeout=60
  echo -n "Waiting for database server to accept connections"
  while ! mysqladmin -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASS:+-p$DB_PASS} status >/dev/null 2>&1
  do
    timeout=$(expr $timeout - 1)
    if [[ $timeout -eq 0 ]]; then
      echo
      echo "Could not connect to database server. Aborting..."
      exit 1
    fi
    echo -n "."
    sleep 1
  done
  echo
}

apply_database_settings() {
  cp /var/cache/invoiceplane/conf/invoiceplane/database.php ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
  sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_HOST}}/'"${DB_HOST}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
  sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_PORT}}/'"${DB_PORT}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
  sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_USER}}/'"${DB_USER}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
  sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_PASS}}/'"${DB_PASS}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
  sudo -HEu ${INVOICE_PLANE_USER} sed -i 's/{{DB_NAME}}/'"${DB_NAME}"'/' ${INVOICE_PLANE_INSTALL_DIR}/application/config/database.php
}

configure_timezone() {
  sudo -HEu ${INVOICE_PLANE_USER} sed -i 's,{{INVOICE_PLANE_TIMEZONE}},'"${INVOICE_PLANE_TIMEZONE}"','  ${INVOICE_PLANE_INSTALL_DIR}/.user.ini
}

create_version_file() {
  CURRENT_VERSION=
  [[ -f ${INVOICE_PLANE_DATA_DIR}/VERSION ]] && CURRENT_VERSION=$(cat ${INVOICE_PLANE_DATA_DIR}/VERSION)
  if [[ ${INVOICE_PLANE_VERSION} != ${CURRENT_VERSION} ]]; then
    echo -n "${INVOICE_PLANE_VERSION}" > ${INVOICE_PLANE_DATA_DIR}/VERSION
  fi
}

# allow arguments to be passed to php5-fpm
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == php5-fpm || ${1} == $(which php5-fpm) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

create_data_dir
create_vhost_configuration
autodetect_database_connection_parameters
apply_database_settings
configure_timezone
create_version_file

# default behaviour is to launch php5-fpm
if [[ -z ${1} ]]; then
  exec start-stop-daemon --start --chuid root:root --exec $(which php5-fpm) -- ${EXTRA_ARGS}
else
  exec "$@"
fi
