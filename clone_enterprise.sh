#! /bin/bash

# Usage ./clone_enterprise  <username> <token> <odoo_version>

USERNAME="$1"
TOKEN="$2"
ODOO_VERSION="$3"

if [[ -z "$USERNAME" || -z "$TOKEN" || -z "$ODOO_VERSION" ]]; then
	echo "Usage : $0 <username> <token> <odoo_version>"
	exit 1
fi

echo "Cloning Odoo Enterprise version ${ODOO_VERSION}..."
git clone https://${USERNAME}:${TOKEN}@github.com/odoo/enterprise.git --depth=1 --branch=${ODOO_VERSION} ./odoo/enterprise

if [[ $? -eq 0 ]]; then
    echo "Successfully cloned enterprise ${ODOO_VERSION}"
else
    echo "Failed to clone enterprise repository. Please check your credentials or token access."
    exit 2
fi
