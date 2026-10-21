#!/bin/sh
set -e
/usr/sbin/nginx -t
systemctl reload nginx