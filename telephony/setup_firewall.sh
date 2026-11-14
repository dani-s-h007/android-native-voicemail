#!/usr/bin/env bash
# File: telephony/setup_firewall.sh
set -euo pipefail

sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow RTP Media Ports (Audio streams)
sudo ufw allow 10000:20000/udp

# Restrict SIP Signalling (5060 UDP) to Carrier IP ranges
CARRIER_IPS=(
    "182.76.0.0/16"
    "115.112.0.0/16"
    "122.160.0.0/16"
)

for ip in "${CARRIER_IPS[@]}"; do
    sudo ufw allow from "$ip" to any port 5060 proto udp comment "Carrier SIP Inbound"
done

sudo ufw --force enable
sudo ufw status verbose

