#!/bin/sh

set -e

: "${lbu:=/opt/LiveBootUtils}"
. "$lbu/scripts/common.func"

: "${eid_repo_base:=https://github.com/open-eid}"
: "${eid_repos:=libdigidocpp DigiDoc4-Client libdigidoc chrome-token-signing firefox-pkcs11-loader TeRa linux-installer}"

: "${wd:=$(dirname "$0")}"
: "${deb_build_dir:=$dl_cache_dir/../deb}"
: "${dpkg_status_save:=$deb_build_dir/.dpkg-status}"

dq='"'
: "${dl_list_jq:=map(select(.prerelease|not))|map(select(any(.assets[];.name|endswith(${dq}.dsc${dq}))))[0].assets[].browser_download_url}"
: "${gh_api_base:=https://api.github.com/repos/open-eid}"

dl_gh_rel_dsc() {
  local dst="$1"
  shift
  for pkg; do
    local rel_json="$(dl_file "$gh_api_base/$pkg/releases")"
    local dsc_url="$(jq -r -c "$dl_list_jq" "$rel_json" | grep '\.dsc$')"
    local dsc_file="$dst/${dsc_url##*/}"
    cp "$(dl_file "$dsc_url")" "$dsc_file"
    for deb_src_file in $(awk '/^Files:/{inFiles=1};/^ /{if (inFiles) print $3}' "$dsc_file");do
      deb_src_file_url="$(jq -r -c "$dl_list_jq" "$rel_json" | grep -wF "$deb_src_file")"
      cp "$(dl_file "$deb_src_file_url")" "$dst/${deb_src_file##*/}"
    done
    (cd "$dst"; dpkg-source -x "$dsc_file" "$pkg")
  done
}
