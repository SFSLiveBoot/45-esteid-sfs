#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

dpkg_status="$dpkg_status_save" "$lbu/scripts/apt-sfs.sh" "$DESTDIR" $install_pkgs
