#!/bin/bash

service postgresql start

exec /usr/bin/gosu kali "$@"
