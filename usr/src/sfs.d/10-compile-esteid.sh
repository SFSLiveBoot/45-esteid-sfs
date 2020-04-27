#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

for eid_repo in $eid_repos;do
  case "$eid_repo" in
    TeRa)
      git clone --depth=1 --recursive "$eid_repo_base/$eid_repo" "$deb_build_dir/$eid_repo"
      grep -qw "libzip-dev" "$deb_build_dir/$eid_repo/debian/control" ||
        sed -e '/^Build-Depends:/a\ libzip-dev,' -i "$deb_build_dir/$eid_repo/debian/control"
    ;;
    *) dl_gh_rel_dsc "$deb_build_dir" "$eid_repo" ;;
  esac
  apt-get -y build-dep "$deb_build_dir/$eid_repo"
  (cd "$deb_build_dir/$eid_repo"; dpkg-buildpackage -b -uc)
  (cd "$deb_build_dir"; dpkg-scanpackages . > Packages)
done
