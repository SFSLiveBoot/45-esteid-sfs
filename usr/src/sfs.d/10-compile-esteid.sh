#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"

cd "$deb_build_dir"

test -z "$preinst_pkgs" || (set -x; apt-get -y install $preinst_pkgs)

echo "Using eid_repos=$eid_repos"
for eid_repo in $eid_repos;do
  echo "Getting sources for '$eid_repo'"

  # sets $pkg_{source,binaries}
  download_github_released_source . "$eid_repo" || {
    echo "ERROR: Downloading '$eid_repo' failed.">&2
    echo "Maybe adding specific version with $eid_repo=**tag** to \$eid_repos (=$eid_repos) will help?" >&2
    exit 1
  }

  need_compile=""
  for pkg_bin in $pkg_binaries;do
    if apt-cache show "$pkg_bin" >/dev/null;then
      echo "Already have binary package for '$pkg_bin'"
    else
      echo "Did not find binary package for '$pkg_bin', compiling '$pkg_source'"
      need_compile=1
      break
    fi
  done
  test -n "$need_compile" || continue

  (set -x;
    apt-get -y build-dep "$pkg_source"
    apt-get -y source --compile "$pkg_source"
    dpkg-scanpackages -m . >Packages
  )
done
