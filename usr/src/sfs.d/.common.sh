#!/bin/sh

set -e

: ${lbu:=/opt/LiveBootUtils}
. "$lbu/scripts/common.func"
: ${esteid_repo:=https://github.com/open-eid}
: ${deb_cache_dir:=$HOME/.cache/lbu/deb}
: ${dpkg_status_save:=$deb_cache_dir/.dpkg-status}
