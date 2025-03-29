#!/bin/bash

PYTHON_VERSION="3.10.7"
PYTHON_URL="https://www.python.org/ftp/python/3.10.7/Python-3.10.7.tgz"
AGENT_TOOLS_DIR="/home/azureagent/_work/_tool"
PYTHON_INSTALL_DIR="${AGENT_TOOLS_DIR}/Python/${PYTHON_VERSION}/x64"

if [ ! -d "$AGENT_TOOLS_DIR" ]; then
    echo "Error: Agent Tools Directory ($AGENT_TOOLS_DIR) does not exist."
    exit 1
fi

WORK_DIR=$(mktemp -d)
cd "$WORK_DIR" || exit 1
echo "Working in temporary directory: $WORK_DIR"

# Instalace všech potřebných závislostí včetně zlib-devel
echo "Installing build dependencies..."
sudo yum install -y gcc make libffi-devel openssl-devel zlib-devel
echo "Dependencies installed. Current versions:"
gcc --version
make --version
rpm -q zlib-devel

echo "Downloading Python $PYTHON_VERSION from $PYTHON_URL..."
wget -O "Python-${PYTHON_VERSION}.tgz" "$PYTHON_URL"
ls -la "Python-${PYTHON_VERSION}.tgz"

echo "Extracting Python source..."
tar -xvzf "Python-${PYTHON_VERSION}.tgz"
cd "Python-${PYTHON_VERSION}" || exit 1

echo "Configuring Python with prefix=$PYTHON_INSTALL_DIR..."
./configure \
    --prefix="$PYTHON_INSTALL_DIR" \
    --enable-shared \
    --enable-optimizations \
    --enable-ipv6 \
    LDFLAGS=-Wl,-rpath="$PYTHON_INSTALL_DIR"/lib,--disable-new-dtags

echo "Building Python..."
make

echo "Installing Python to $PYTHON_INSTALL_DIR..."
make install

echo "Verifying Python installation..."
"$PYTHON_INSTALL_DIR/bin/python3" --version

# Instalace pip
echo "Installing pip..."
wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py
"$PYTHON_INSTALL_DIR/bin/python3" get-pip.py
echo "Pip version:"
"$PYTHON_INSTALL_DIR/bin/pip3" --version

echo "Cleaning up temporary directory..."
cd ..
rm -rf "$WORK_DIR"

echo "Python $PYTHON_VERSION and pip successfully installed to $PYTHON_INSTALL_DIR"
