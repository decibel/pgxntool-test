#!/bin/sh

TMPDIR=${TMPDIR:-${TEMP:-$TMP}}
LOG=`mktemp -t pgxntool-test.XXXXXX.log`
[ $? -eq 0 ] || exit 1
TEST_DIR=`mktemp -d -t pgxntool-test.XXXXXX`
[ $? -eq 0 ] || exit 1

echo "LOG='$LOG'"
echo "TEST_DIR='$TEST_DIR'"
