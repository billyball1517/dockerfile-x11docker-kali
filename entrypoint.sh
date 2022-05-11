#!/bin/bash

# Either use the LOCAL_USER_ID if passed in at runtime or fallback

USER_ID=${LOCAL_USER_ID:-9001}

RUN useradd -u $USER_ID -m -s /bin/bash kali

#echo "$KALI_PASS" | passwd --stdin kali

addgroup kali sudo
addgroup kali wireshark

#exec /usr/sbin/gosu kali "$@"
