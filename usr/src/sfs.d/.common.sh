#!/bin/sh

set -e

: "${lbu:=/opt/LiveBootUtils}"
. "$lbu/scripts/common.func"

: "${eid_repo_base:=https://github.com/open-eid}"
: "${eid_repos:=linux-installer qesteidutil qdigidoc TeRa chrome-token-signing firefox-pkcs11-loader}"

: "${wd:=$(dirname "$0")}"
: "${deb_cache:=$dl_cache_dir/../deb}"
: "${dpkg_status_save:=$deb_cache/.dpkg-status}"

install_pkgs() {
  local fname=""
  case "$1" in
    -r)
      fname="$2"
      shift 2
    ;;
  esac
  test -z "$fname" -o ! -s "$fname" || {
    set -- "$@" $(grep -v -e '^#' -e '^$' "$fname")
  }
  test -z "$1" || apt-get -y install "$@"
}

dq='"'
: "${dl_list_jq:=map(select(.prerelease|not))|map(select(any(.assets[];.name|endswith(${dq}.dsc${dq}))))[0].assets[].browser_download_url}"
: "${gh_api_base:=https://api.github.com/repos/open-eid}"

ghrel_to_deb() {
  local deb_src="$1" rel_url="$2" rel_json dsc_url dsc_file build_dir files_idx
  mkdir -p "$deb_src"
  
  rel_json="$(dl_file "$rel_url")"
  
  if dsc_url="$(jq -r -c "$dl_list_jq" $rel_json | grep '\.dsc$')";then
    dsc_file="$deb_src/${dsc_url##*/}"
    
    cp "$(dl_file "$dsc_url")" "$dsc_file"
    files_idx="$(grep -n "^Files:" "$dsc_file" | cut -f1 -d:)"
    for deb_src_file in $(tail -n+$files_idx "$dsc_file" | awk '/^ /{print $3}');do
      cp "$(dl_file "${dsc_url%/*}/$deb_src_file")" "$deb_src/${deb_src_file##*/}"
    done
    
    build_dir="$deb_src/$(grep "^Source: " "$dsc_file" | cut -f2 -d" ")-$(sed -ne '/^Version: /{s/.*://;s/^[[:space:]]*//;p}' "$dsc_file")"
    test -d "$build_dir" || dpkg-source -x "$deb_src/${dsc_url##*/}" "$build_dir"
  else
    tarball_url="$(jq -r -c 'map(select(.prerelease|not))[0].tarball_url' "$rel_json")"
    rel_tag="$(jq -r -c 'map(select(.prerelease|not))[0].tag_name' "$rel_json")"
    build_dir="${rel_url%/releases}"
    build_dir="${deb_src}/${build_dir##*/}-$rel_tag"
    mkdir -p "$build_dir"
    tar xfz "$(dl_file "$tarball_url")" --strip-components=1 -C "$build_dir"
  fi
  for patch in $(find "$wd/.patches" -name "${build_dir##*/}_[0-9][0-9]-*.patch" | sort);do
    (cd "$build_dir"; patch -p1 < "$patch")
  done
  (cd "$build_dir"; dpkg-buildpackage -us -uc -b)
}
