#!/bin/bash

set -o errexit -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

cd $(dirname ${BASH_SOURCE[0]})/..

[[ ! -z "$TARGET_PRODUCT" ]] || user_error "TARGET_PRODUCT not set. Please prepare env."

PROP_FILE=vendor/google_devices/$TARGET_PRODUCT/proprietary/Android.bp

[[ -f "$PROP_FILE" ]] || user_error "Please download proprietary files for $TARGET_PRODUCT first."

LINE_NUMBER=$(grep -n "name: \"liboemcrypto" vendor/google_devices/$TARGET_PRODUCT/proprietary/Android.bp | awk -F: '{print $1}')

TMPFILE_PRE=$(mktemp)
TMPFILE_POST=$(mktemp)
TMPFILE_NEW=$(mktemp)
trap 'rm -- "$TMPFILE_PRE" "$TMPFILE_POST" "$TMPFILE_NEW"' EXIT

head -n $LINE_NUMBER $PROP_FILE > $TMPFILE_PRE
tail -n +$((LINE_NUMBER+1)) $PROP_FILE > $TMPFILE_POST

LAST_EMPTY_LINE=$(grep -E --line-number --with-filename '^$' $TMPFILE_PRE | tail -n1 | awk -F: '{print $2}')
FIRST_EMPTY_LINE=$(grep -E --line-number --with-filename '^$' $TMPFILE_POST | head -n1 | awk -F: '{print $2}')

if [ "$(tail -n +$((LAST_EMPTY_LINE+1)) $TMPFILE_PRE | head -n1)" = "/*" ] ; then
    echo "Already disabled"
    exit
fi

head $TMPFILE_PRE -n $LAST_EMPTY_LINE > $TMPFILE_NEW
echo "/*" >> $TMPFILE_NEW
tail -n +$((LAST_EMPTY_LINE+1)) $TMPFILE_PRE >> $TMPFILE_NEW

head $TMPFILE_POST -n $((FIRST_EMPTY_LINE-1)) >> $TMPFILE_NEW
echo "*/" >> $TMPFILE_NEW
tail -n +$FIRST_EMPTY_LINE $TMPFILE_POST >> $TMPFILE_NEW

cat $TMPFILE_NEW > $PROP_FILE

echo "Successfully disabled"
