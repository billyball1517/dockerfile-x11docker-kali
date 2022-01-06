#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}
GROUP_ID=${LOCAL_GROUP_ID:-9001}

echo "Starting with UID : $USER_ID"
adduser -D -u $USER_ID kali
export HOME=/home/kali

addgroup kali qemu

service postgresql start

exec /usr/bin/gosu kali "$@"
