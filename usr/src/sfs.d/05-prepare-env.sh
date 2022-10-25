#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

mkdir -p "/usr/share/keyrings"
echo "$RIA_KEY" | gpg --dearmor >"$ria_apt_key"

echo "deb [signed-by=$ria_apt_key] $ria_repo $inst_dist main" >"$apt_list"

apt-get update
