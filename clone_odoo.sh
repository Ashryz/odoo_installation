#! /bin/bash

#Usage ./clone_odoo <odoo_version>
ODOO_VERSION="$1"

if [[ -z "$ODOO_VERSION" ]]; then
	echo "Usage : $0 <odoo_version>"
	exit 1 
fi

echo "Cloning Odoo version ${ODOO_VERSION}..."
git clone https://github.com/odoo/odoo.git --depth=1 --branch=${ODOO_VERSION} ./odoo/odoo${ODOO_VERSION}

if [[ $? -eq 0 ]]; then
	echo "Successfully cloned odoo ${ODOO_VERSION}"
else 
	echo "Failed to clone odoo"
    	exit 2
fi
