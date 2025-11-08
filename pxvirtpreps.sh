#!/bin/bash
set -euo pipefail

# Get the IP address of the default network interface
IP_ADDR=$(hostname -I | awk '{print $1}')

# Backup the hosts file first
sudo cp /etc/hosts /etc/hosts.bak

# Replace the IP for raspberrypi (use hostname -s to keep current host name)
HOSTNAME_SHORT=$(hostname -s)
sudo sed -i "s/^127\.0\.1\.1[[:space:]]\+[[:alnum:]-]\+/${IP_ADDR} ${HOSTNAME_SHORT}/" /etc/hosts

echo "Updated /etc/hosts: ${HOSTNAME_SHORT} now points to $IP_ADDR"

# Download GPG key (create dir if missing)
sudo mkdir -p /etc/apt/trusted.gpg.d
curl -fsSL https://mirrors.lierfang.com/pxcloud/lierfang.gpg -o /tmp/lierfang.gpg
sudo mv /tmp/lierfang.gpg /etc/apt/trusted.gpg.d/lierfang.gpg
sudo chmod 644 /etc/apt/trusted.gpg.d/lierfang.gpg

# Add the repository to the sources list
# Load release info once
source /etc/os-release

# Auto-detect architecture (dpkg prints 'arm64', 'armhf', 'amd64', etc.)
ARCH=$(dpkg --print-architecture)

# Build the repository line and write it with sudo tee to avoid redirection permission issues
REPO_LINE="deb [arch=${ARCH}] https://mirrors.lierfang.com/pxcloud/pxvirt ${VERSION_CODENAME} main"
echo "$REPO_LINE" | sudo tee /etc/apt/sources.list.d/pxvirt-sources.list >/dev/null

echo "Added repo: $REPO_LINE"

# Disable NetworkManager (if present)
if systemctl list-unit-files | grep -q NetworkManager; then
  sudo systemctl disable --now NetworkManager || true
fi

# Install ifupdown2 and remove interfaces.new if exists
sudo apt update
sudo apt install -y ifupdown2
[ -f /etc/network/interfaces.new ] && sudo rm -f /etc/network/interfaces.new

# Detect the primary active interface that is not loopback, state UP and carrier detected
INTERFACE=$(ip -o link show up | awk -F': ' '{print $2}' | grep -v lo | head -n1)

if [ -z "$INTERFACE" ]; then
    echo "No active network interface found."
    exit 1
fi

echo "Detected active interface: $INTERFACE"

# Auto detect default gateway
GATEWAY=$(ip route | awk '/^default/ {print $3; exit}')
if [ -z "$GATEWAY" ]; then
    echo "No default gateway found."
    exit 1
fi
echo "Detected default gateway: $GATEWAY"

# Detect ip address with subnet mask
IP_CIDR=$(ip -o -f inet addr show "$INTERFACE" | awk '{print $4}' | head -n1)

INTERFACES_FILE="/etc/network/interfaces"

# Backup the original interfaces file
sudo cp "$INTERFACES_FILE" "${INTERFACES_FILE}.bak.$(date +%F-%T)"

# Remove any existing configuration for the detected interface (simple approach)
sudo sed -i "/auto $INTERFACE/,/^\s*$/d" "$INTERFACES_FILE"
sudo sed -i "/iface $INTERFACE inet /,/^\s*$/d" "$INTERFACES_FILE"
sudo sed -i "/auto vmbr0/,/^\s*$/d" "$INTERFACES_FILE"
sudo sed -i "/iface vmbr0 inet /,/^\s*$/d" "$INTERFACES_FILE"

# Append new static IP config for the detected interface
sudo bash -c "cat >> $INTERFACES_FILE" <<EOF

auto $INTERFACE
iface $INTERFACE inet manual

auto vmbr0
iface vmbr0 inet manual
    address $IP_CIDR
    gateway $GATEWAY
    bridge-ports $INTERFACE
    bridge-stp off
    bridge-fd 0
EOF

echo "Static IP configuration for interfaces $INTERFACE and vmbr0 added to $INTERFACES_FILE"
