#!/bin/bash

# Nastavení proměnných
PYTHON_VERSION="3.10.7"
PYTHON_URL="https://www.python.org/ftp/python/3.10.7/Python-3.10.7.tgz"
AGENT_TOOLS_DIR="/home/azureagent/_work/_tool"
PYTHON_INSTALL_DIR="${AGENT_TOOLS_DIR}/Python/${PYTHON_VERSION}/x64"

# Kontrola, zda adresář existuje
if [ ! -d "$AGENT_TOOLS_DIR" ]; then
    echo "Error: Agent Tools Directory ($AGENT_TOOLS_DIR) does not exist. Please ensure the Azure DevOps agent is installed correctly."
    exit 1
fi

# Vytvoření pracovního adresáře pro instalaci
WORK_DIR=$(mktemp -d)
cd "$WORK_DIR" || exit 1
echo "Working in temporary directory: $WORK_DIR"

# Instalace závislostí
echo "Installing build dependencies (skip if already installed)..."
sudo yum install -y gcc make libffi-devel openssl-devel
echo "Dependencies installed. Current versions:"
gcc --version
make --version

# Stažení Pythonu
echo "Downloading Python $PYTHON_VERSION from $PYTHON_URL..."
wget -O "Python-${PYTHON_VERSION}.tgz" "$PYTHON_URL"
ls -la "Python-${PYTHON_VERSION}.tgz"

# Rozbalení archivu
echo "Extracting Python source..."
tar -xvzf "Python-${PYTHON_VERSION}.tgz"
cd "Python-${PYTHON_VERSION}" || exit 1

# Konfigurace Pythonu
echo "Configuring Python with prefix=$PYTHON_INSTALL_DIR..."
./configure \
    --prefix="$PYTHON_INSTALL_DIR" \
    --enable-shared \
    --enable-optimizations \
    --enable-ipv6 \
    LDFLAGS=-Wl,-rpath="$PYTHON_INSTALL_DIR"/lib,--disable-new-dtags

# Kompilace Pythonu
echo "Building Python..."
make

# Instalace Pythonu
echo "Installing Python to $PYTHON_INSTALL_DIR..."
make install

# Ověření instalace
echo "Verifying Python installation..."
"$PYTHON_INSTALL_DIR/bin/python3" --version

# Úklid
echo "Cleaning up temporary directory..."
cd ..
rm -rf "$WORK_DIR"

echo "Python $PYTHON_VERSION successfully installed to $PYTHON_INSTALL_DIR"
echo "You can now use this Python in your Azure Pipelines without rebuilding it."
