#!/bin/sh

: "${NSSDB:=$HOME/.pki/nssdb}"

test -d "$NSSDB" || mkdir -p "$NSSDB"

test -e "$NSSDB/pkcs11.txt" && grep -q opensc-pkcs11.so "$NSSDB/pkcs11.txt" ||
  modutil -force -dbdir "sql:$NSSDB" -add opensc-pkcs11 -libfile onepin-opensc-pkcs11.so -mechanisms FRIENDLY
