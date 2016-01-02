#!/bin/bash
set -e
source ${INVOICEPLANE_RUNTIME_DIR}/functions

case ${1} in
  app:invoiceplane)

    initialize_system
    configure_nginx

    case ${1} in
      app:invoiceplane)
        configure_invoiceplane
        echo "Starting InvoicePlane php5-fpm..."
        exec $(which php5-fpm)
        ;;
    esac
    ;;
  app:help)
    echo "Available options:"
    echo " app:invoiceplane     - Starts the InvoicePlane php5-fpm server (default)"
    echo " app:help             - Displays the help"
    echo " [command]            - Execute the specified command, eg. bash."
    ;;
  *)
    exec "$@"
    ;;
esac
