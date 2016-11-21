#!/bin/sh

TOPDIR=`cd ${0%/*}; pwd`

TMPDIR=${TMPDIR:-${TEMP:-$TMP}}
TEST_DIR=`mktemp -d -t pgxntool-test.XXXXXX`
[ $? -eq 0 ] || exit 1

echo "TOPDIR='$TOPDIR'"
echo "TEST_DIR='$TEST_DIR'"
