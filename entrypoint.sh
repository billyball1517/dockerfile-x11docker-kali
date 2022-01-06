#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}
GROUP_ID=${LOCAL_GROUP_ID:-9001}

echo "Starting with UID : $USER_ID"
adduser -D -u $USER_ID user
export HOME=/home/user

addgroup docker
chown -R root:docker /run/docker*

addgroup -g $GROUP_ID external-kvm

addgroup user docker
addgroup user external-kvm
addgroup user libvirt
addgroup user qemu

dockerd > /dev/null &
libvirtd > /dev/null &

exec /usr/bin/gosu user "$@"
