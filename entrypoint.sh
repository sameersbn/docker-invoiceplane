#!/bin/bash
set -e
source ${INVOICEPLANE_RUNTIME_DIR}/functions

# allow arguments to be passed to php5-fpm
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == php5-fpm || ${1} == $(which php5-fpm) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

initialize_system
nginx_configure_virtualhost
invoiceplane_configure_database
invoiceplane_configure_timezone

# default behaviour is to launch php5-fpm
if [[ -z ${1} ]]; then
  exec start-stop-daemon --start --chuid root:root --exec $(which php5-fpm) -- ${EXTRA_ARGS}
else
  exec "$@"
fi
