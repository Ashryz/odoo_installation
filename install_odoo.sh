#! /bin/bash

# Usage:   sudo ./install_odoo.sh <user> <version>
# Example: sudo ./install_odoo.sh odoo16 16.0

ODOO_USER="$1"
ODOO_VERSION="$2"

# exports red color for invalid operation, reset for main color
export red='\033[1;31m'
export reset='\033[0m'


# Exit script on error
set -e

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}Please run as root (sudo).${reset}"
    exit 1
fi


# Python package installation and system dependencies
sudo apt update
sudo apt install -y git python3-pip build-essential wget python3-dev python3-venv \
    python3-wheel python3-setuptools libfreetype6-dev libxml2-dev libxslt1-dev \
    zlib1g-dev libsasl2-dev libldap2-dev libjpeg-dev libjpeg8-dev libtiff5-dev \
    libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev \
    libxcb1-dev libpq-dev libzip-dev node-less npm libffi-dev libssl-dev
sudo ln -s /usr/bin/nodejs /usr/bin/node || true
sudo npm install -g less less-plugin-clean-css

# Create Odoo user
id -u ${ODOO_USER} &>/dev/null || useradd -m -d /opt/${ODOO_USER} -U -r -s /bin/bash ${ODOO_USER}

# Setup PostgreSQL
if ! dpkg -l postgresql | grep ^ii &>/dev/null; then
    	 echo "installing PostgreSQL ...."
    	 sudo apt install postgresql
    	 sudo su - postgres -c "createuser -s ${ODOO_USER}"
    else
    	echo "PostgreSQL is already installed."
    	sudo su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${ODOO_USER}'\"" | grep -q 1 || \
	sudo su - postgres -c "createuser -s ${ODOO_USER}"

fi	

# Install wkhtmltopdf 
if ! dpkg -l wkhtmltopdf| grep ^ii &>/dev/null; then
    	 echo "installing Wkhtmltopdf ...."
    	 apt install -y wkhtmltopdf
    else
    	echo "Wkhtmltopdf is already installed."
fi	

# Directory structure
echo "Creating directory structure..."
mkdir -p /opt/${ODOO_USER}
mkdir -p /var/log/${ODOO_USER}
chown -R ${ODOO_USER}:${ODOO_USER} /opt/${ODOO_USER}
chown -R ${ODOO_USER}:${ODOO_USER} /var/log/${ODOO_USER}


# Clone Odoo
echo "Cloning Odoo ${ODOO_VERSION}..."
if [ -d "/opt/${ODOO_USER}/odoo${ODOO_VERSION}" ]; then
    echo "Updating existing Odoo installation..."
    su - ${ODOO_USER} -c "cd /opt/${ODOO_USER}/odoo${ODOO_VERSION} && git pull"
else
    su - ${ODOO_USER} -c "git clone --depth 1 --branch ${ODOO_VERSION} https://github.com/odoo/odoo /opt/${ODOO_USER}/odoo${ODOO_VERSION}"
fi

# Setup virtual environment
echo "Setting up Python virtual environment..."
su - ${ODOO_USER} -c "python3 -m venv /opt/${ODOO_USER}/odoo${ODOO_VERSION}-venv"
VENV_PATH="/opt/${ODOO_USER}/odoo${ODOO_VERSION}-venv"
VENV_PYTHON="${VENV_PATH}/bin/python3"
VENV_PIP="${VENV_PATH}/bin/pip"

# Install Python dependencies
echo "Installing Python packages in virtual environment..."
su - ${ODOO_USER} -c "${VENV_PIP} install wheel"
su - ${ODOO_USER} -c "cd /opt/${ODOO_USER}/odoo${ODOO_VERSION} && ${VENV_PIP} install -r requirements.txt"

# Create Odoo config
echo "Creating Odoo configuration..."
cat > /etc/odoo${ODOO_VERSION}.conf << EOF
[options]
admin_passwd = PCPower@2025
db_host = False
db_port = False
db_user = ${ODOO_USER}
db_password = False
addons_path = /opt/${ODOO_USER}/odoo${ODOO_VERSION}/addons
logfile = /var/log/${ODOO_USER}/odoo${ODOO_VERSION}.log
http_port = 8069
EOF

chown ${ODOO_USER}:${ODOO_USER} /etc/odoo${ODOO_VERSION}.conf
chmod 640 /etc/odoo${ODOO_VERSION}.conf

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/odoo${ODOO_VERSION}.service << EOF
[Unit]
Description=Odoo${ODOO_VERSION}
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo${ODOO_VERSION}
PermissionsStartOnly=true
User=${ODOO_USER}
Group=${ODOO_USER}
ExecStart=${VENV_PYTHON} /opt/${ODOO_USER}/odoo${ODOO_VERSION}/odoo-bin -c /etc/odoo${ODOO_VERSION}.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

chmod 755 /etc/systemd/system/odoo${ODOO_VERSION}.service
systemctl daemon-reload
systemctl enable --now odoo${ODOO_VERSION}
systemctl status odoo${ODOO_VERSION}

echo "Installation complete !"

