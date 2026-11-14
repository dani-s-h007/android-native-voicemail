#!/usr/bin/env bash
# File: telephony/setup_ephemeral_storage.sh
# Sets up volatile RAM disk (tmpfs) for Zero-Cloud-Storage ephemeral audio
set -euo pipefail

BASE_RAM_DIR="/var/spool/voicemail_relay"
RECORDINGS_DIR="${BASE_RAM_DIR}/ephemeral"
GREETINGS_DIR="${BASE_RAM_DIR}/greetings"

echo ">>> Creating volatile RAM disk for ephemeral voicemail & DND greetings..."
sudo mkdir -p "${BASE_RAM_DIR}"

if ! mount | grep -q "${BASE_RAM_DIR}"; then
    sudo mount -t tmpfs -o size=512m,mode=0770,uid=asterisk,gid=asterisk tmpfs "${BASE_RAM_DIR}"
    echo "Mounted 512MB tmpfs at ${BASE_RAM_DIR}"
fi

if ! grep -q "${BASE_RAM_DIR}" /etc/fstab; then
    echo "tmpfs ${BASE_RAM_DIR} tmpfs size=512m,mode=0770,uid=asterisk,gid=asterisk 0 0" | sudo tee -a /etc/fstab
fi

sudo mkdir -p "${RECORDINGS_DIR}" "${GREETINGS_DIR}"
sudo chown -R asterisk:asterisk "${BASE_RAM_DIR}"
sudo chmod -R 770 "${BASE_RAM_DIR}"

echo "Ephemeral RAM storage initialized: Zero permanent disk storage guaranteed."
