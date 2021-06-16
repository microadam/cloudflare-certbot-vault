#!/bin/sh
set -e

echo "Renewing..."
/bin/sh /usr/local/bin/initialize.sh
certbot renew