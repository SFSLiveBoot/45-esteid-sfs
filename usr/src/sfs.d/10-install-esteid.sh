#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

for repo in libdigidoc libdigidocpp;do
  ghrel_to_deb "$deb_cache" "$gh_api_base/$repo/releases"
done

(cd "$deb_cache"; dpkg-scanpackages . > Packages)
echo "deb file://$deb_cache ./" > /etc/apt/sources.list.d/lbu-deb.list

apt-get update

apt-get install --allow-unauthenticated -y libdigidocpp-dev

for repo in $eid_repos;do
  ghrel_to_deb "$deb_cache" "$gh_api_base/$repo/releases"
done

(cd "$deb_cache"; dpkg-scanpackages . >Packages)
echo "deb file://$deb_cache ./" > /etc/apt/sources.list.d/lbu-deb.list

apt-get update

dpkg_status="$dpkg_status_save" "$lbu/scripts/apt-sfs.sh" "$DESTDIR" --allow-unauthenticated open-eid 
