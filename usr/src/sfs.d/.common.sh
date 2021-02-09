#!/bin/sh

set -e

: "${lbu:=/opt/LiveBootUtils}"
. "$lbu/scripts/common.func"

: "${eid_repos:=libdigidocpp DigiDoc4-Client libdigidoc chrome-token-signing firefox-pkcs11-loader linux-installer}"
: "${install_pkgs:=open-eid libdigidocpp-tools}"

: "${deb_build_dir:=$dl_cache_dir/../deb}"
: "${dpkg_status_save:=$deb_build_dir/.dpkg-status}"

: "${gh_api_base:=https://api.github.com/repos/open-eid}"

asset_list_jq() {
  local ver_cond=".prerelease|not"
  test -z "$1" || ver_cond=".tag_name==\"$1\""
  echo 'map(select('"$ver_cond"'))|map(select(any(.assets[];.name|endswith(".dsc"))))[0].assets[].browser_download_url'
}

download_github_released_source() {
  local dst="$1"
  shift
  for pkg; do
    case "$pkg" in *=*) pkg_ver="${pkg#*=}"; pkg="${pkg%=*}";; *) pkg_ver="";;esac
    local rel_json="$(dl_file "$gh_api_base/$pkg/releases")"
    local dsc_url="$(jq -r -c "$(asset_list_jq $pkg_ver)" "$rel_json" | grep '\.dsc$')"
    test -n "$dsc_url" || {
      echo "Could not find .dsc file for version ${pkg_ver:-(latest)}" >&2
      return 100
    }
    local dsc_file="$dst/${dsc_url##*/}"
    cp "$(dl_file "$dsc_url")" "$dsc_file"
    pkg_source="$(awk '/^Source: /{print $2}' "$dsc_file")"
    pkg_binaries="$(sed -ne '/^Binary: /{s/^Binary: //;s/, / /g;p;q}' "$dsc_file")"
    for deb_src_file in $(awk '/^Files:/{inFiles=1};/^ /{if (inFiles) print $3}' "$dsc_file");do
      deb_src_file_url="$(jq -r -c "$(asset_list_jq $pkg_ver)" "$rel_json" | grep -wF "$deb_src_file")"
      if test -n "$deb_src_file_url";then
        cp "$(dl_file "$deb_src_file_url")" "$dst/${deb_src_file##*/}"
      else
        echo "Could not find required file '$deb_src_file' for '$pkg' in asset list at '$gh_api_base/$pkg/releases'" >&2
        return 100
      fi
    done
    (cd "$dst"; dpkg-scansources . >Sources)
  done
}
