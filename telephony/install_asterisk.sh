#!/usr/bin/env bash
# File: telephony/install_asterisk.sh
set -euo pipefail

echo ">>> [1/5] Updating system and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
    build-essential wget curl git subversion libxml2-dev libncurses5-dev \
    libsqlite3-dev libssl-dev libjansson-dev libedit-dev uuid-dev \
    libsrtp2-dev libedit-dev libcurl4-openssl-dev python3 python3-pip \
    sox libsox-fmt-all fail2ban ufw

echo ">>> [2/5] Downloading Asterisk 20 LTS..."
cd /usr/src
sudo rm -rf asterisk-20*
sudo wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
sudo tar -zxvf asterisk-20-current.tar.gz
cd asterisk-20.*/

echo ">>> [3/5] Installing MP3 and prerequisites..."
sudo contrib/scripts/get_mp3_source.sh || true
sudo contrib/scripts/install_prereq install

echo ">>> [4/5] Configuring and compiling Asterisk with PJSIP and SRTP..."
sudo ./configure --with-jansson --with-ssl --with-srtp --with-pjproject-bundled
sudo make menuselect.makeopts
sudo menuselect/menuselect --enable format_wav --enable format_pcm \
    --enable res_pjsip --enable res_pjsip_session --enable res_pjsip_header_funcs \
    --enable res_srtp --enable app_record --enable CORE-SOUNDS-EN-WAV \
    menuselect.makeopts

sudo make -j$(nproc)
sudo make install
sudo make samples
sudo make config
sudo ldconfig

echo ">>> [5/5] Creating dedicated directories and system user..."
sudo groupadd -r asterisk || true
sudo useradd -r -d /var/lib/asterisk -g asterisk asterisk || true
sudo usermod -aG audio asterisk

sudo mkdir -p /var/spool/asterisk/voicemail/recordings
sudo mkdir -p /var/log/asterisk
sudo chown -R asterisk:asterisk /var/spool/asterisk /var/lib/asterisk \
    /var/log/asterisk /var/run/asterisk /etc/asterisk

echo "Asterisk 20 installation completed successfully."

