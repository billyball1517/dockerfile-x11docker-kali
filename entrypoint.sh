#!/bin/bash

export DEBIAN_FRONTEND=readline

# this is to reconfigure wireshark
wget https://raw.githubusercontent.com/billyball1517/dockerfile-x11docker-lxde/master/wireshark-expect && \
chmod +x wireshark-expect && \
./wireshark-expect && \
rm -f ./wireshark-expect \

useradd -m -G wireshark,sudo -s /bin/bash kali

service postgresql start

exec /usr/sbin/gosu kali "$@"
