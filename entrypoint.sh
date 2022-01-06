#!/bin/bash

useradd -m -G wireshark,sudo -s /bin/bash kali

service postgresql start

exec gosu kali "$@"
