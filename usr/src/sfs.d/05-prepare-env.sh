#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

mkdir -p "$(dirname "$dpkg_status_save")"
cp /var/lib/dpkg/status "$dpkg_status_save"
install_pkgs -r "$wd/.pkgs"
