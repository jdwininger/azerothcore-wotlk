#!/usr/bin/env bash

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set SUDO variable - one liner
SUDO=$([ "$EUID" -ne 0 ] && echo "sudo" || echo "")

# Try to install lsb_release if missing
if ! command -v lsb_release &>/dev/null ; then
    # package name may vary, try common package
    $SUDO dnf -y install redhat-lsb-core || true
fi

FEDORA_VERSION=$(lsb_release -sr 2>/dev/null || cat /etc/fedora-release 2>/dev/null | sed -E 's/[^0-9]*([0-9]+).*/\1/')

# Do a system update
$SUDO dnf -y makecache
$SUDO dnf -y upgrade

# Shared deps (mapped from Debian/Ubuntu names)
$SUDO dnf -y install ccache clang cmake curl gperftools gperftools-devel mariadb-devel make unzip jq screen tmux readline-devel ncurses-devel bzip2-devel git gcc gcc-c++ openssl-devel boost-devel gdb expect

VAR_PATH="$CURRENT_PATH/../../../../var"

# Do not install DB server if we are in docker (It will be used a docker container instead)
# or we are explicitly skipping it.
# By default we don't install Oracle MySQL server on Fedora; the installer will install
# MariaDB unless you explicitly request MySQL by setting INSTALL_MYSQL=1.
if [[ $DOCKER != 1 && $SKIP_MYSQL_INSTALL != 1 ]]; then
  if [[ "$INSTALL_MYSQL" == "1" || "$INSTALL_MYSQL" == "true" ]]; then
    echo "INSTALL_MYSQL requested: attempting to install Oracle MySQL server..."

    # Try to add the official MySQL YUM repo for this Fedora version and install mysql-community-server
    MYSQL_RPM="mysql80-community-release-fc${FEDORA_VERSION}-x86_64.rpm"
    MYSQL_RPM_URL="https://dev.mysql.com/get/${MYSQL_RPM}"

    echo "Downloading MySQL repo package: $MYSQL_RPM_URL"
    if wget -q -O "$VAR_PATH/$MYSQL_RPM" "$MYSQL_RPM_URL"; then
      $SUDO dnf -y install "$VAR_PATH/$MYSQL_RPM" || true
      # Install mysql server from the newly-enabled repo
      if $SUDO dnf -y install mysql-community-server; then
        echo "MySQL server installed successfully."
        if [[ $CONTINUOUS_INTEGRATION ]]; then
          $SUDO systemctl enable mysqld.service
          $SUDO systemctl start mysqld.service
        fi
      else
        echo "Failed to install mysql-community-server from MySQL repo. Falling back to MariaDB."
        $SUDO dnf -y install mariadb-server
        if [[ $CONTINUOUS_INTEGRATION ]]; then
          $SUDO systemctl enable mariadb.service
          $SUDO systemctl start mariadb.service
        fi
      fi
    else
      echo "Could not download MySQL repo package for Fedora ${FEDORA_VERSION}. Falling back to MariaDB."
      $SUDO dnf -y install mariadb-server
      if [[ $CONTINUOUS_INTEGRATION ]]; then
        $SUDO systemctl enable mariadb.service
        $SUDO systemctl start mariadb.service
      fi
    fi

  else
    echo "Installing MariaDB server (default on Fedora). If you want Oracle MySQL instead, set INSTALL_MYSQL=1 before running the installer."
    $SUDO dnf -y install mariadb-server
    # enable and start the service
    if [[ $CONTINUOUS_INTEGRATION ]]; then
      $SUDO systemctl enable mariadb.service
      $SUDO systemctl start mariadb.service
    fi
  fi
fi

# Note: If you require Oracle MySQL server instead of MariaDB you can set INSTALL_MYSQL=1
# in your environment or config. The installer will attempt to add the MySQL YUM repo and
# install "mysql-community-server"; if that fails it falls back to MariaDB.
