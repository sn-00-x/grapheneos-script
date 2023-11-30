#!/bin/bash

set -o errexit -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

[[ $# -eq 2 ]] || user_error "Usage: ${BASH_SOURCE[0]} <package-name> <cert-hash>"

PACKAGE_NAME=$1
CERT_HASH=${2^^}

case $PACKAGE_NAME in
  ("" | *[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_.]*)
    user_error "package-name contains invalid characters.";;
esac

case $CERT_HASH in
  ("" | *[!0123456789abcdefABCDEF]*)
    user_error "cert-hash contains invalid characters.";;
esac

[ ${#CERT_HASH} -eq 64 ] || user_error "length of cert-hash must be 64"

sed -i -E 's/(private static final String PACKAGE_SCREEN2AUTO = ).*(;)/\1"'$PACKAGE_NAME'"\2/' $(dirname ${BASH_SOURCE[0]})/../frameworks/base/core/java/android/app/compat/sn00x/AndroidAutoHelper.java
sed -i -E 's/(private static final String SIGNATURE_SCREEN2AUTO = ).*(;)/\1"'$CERT_HASH'"\2/' $(dirname ${BASH_SOURCE[0]})/../frameworks/base/core/java/android/app/compat/sn00x/AndroidAutoHelper.java
