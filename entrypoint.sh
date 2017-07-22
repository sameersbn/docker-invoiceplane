#!/bin/bash
set -e
source ${INVOICEPLANE_RUNTIME_DIR}/functions

[[ $DEBUG == true ]] && set -x

case ${1} in
  app:invoiceplane|app:nginx|app:backup:create|app:backup:restore)

    initialize_system

    case ${1} in
      app:invoiceplane)
        configure_invoiceplane
        echo "Starting InvoicePlane php"${PHP_VERSION}"-fpm..." 
        exec $(which php-fpm${PHP_VERSION}) -F		
        ;;
      app:nginx)
        configure_nginx
        echo "Starting nginx..."
        exec $(which nginx) -c /etc/nginx/nginx.conf -g "daemon off;"
        ;;
      app:backup:create)
        shift 1
        backup_create
        ;;
      app:backup:restore)
        shift 1
        backup_restore $@
        ;;
    esac
    ;;
  app:help)
    echo "Available options:"
    echo " app:invoiceplane     - Starts the InvoicePlane php5-fpm server (default)"
    echo " app:nginx            - Starts the nginx server"
    echo " app:backup:create    - Create a backup"
    echo " app:backup:restore   - Restore an existing backup"
    echo " app:help             - Displays the help"
    echo " [command]            - Execute the specified command, eg. bash."
    ;;
  *)
    exec "$@"
    ;;
esac
