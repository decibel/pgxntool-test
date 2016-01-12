#!/bin/bash

trap 'echo "$BASH_SOURCE: line $LINENO" >&2' ERR
set -o errexit -o errtrace -o pipefail
#set -o xtrace -o verbose

BASEDIR=`cd ${0%/*}; pwd`
PGXNBRANCH=${PGXNBRANCH:-${1:-master}}
PGXNREPO=${PGXNREPO:-${2:-$BASEDIR/../pgxntool}}
TEST_TEMPLATE=${TEST_TEMPLATE:-${0%/*}/../pgxntool-test-template}

find_repo () {
  if ! echo $1 | egrep -q '^(git|https?):'; then
    cd $1
    pwd
  fi
}

TEST_TEMPLATE=`find_repo $TEST_TEMPLATE`
PGXNREPO=`find_repo $PGXNREPO`

TMPDIR=${TMPDIR:-${TEMP:-$TMP}}
TEST_DIR=`mktemp -d -t pgxntool-test.XXXXXX`
[ $? -eq 0 ] || exit 1
trap "echo PTD='$PTD'" EXIT

git clone $TEST_TEMPLATE $TEST_DIR
cd $TEST_DIR
git subtree add -P pgxntool --squash $PGXNREPO $PGXNBRANCH

pgxntool/setup.sh

# Run setup.sh again to verify it doesn't over-write things
pgxntool/setup.sh

ls
git status
git diff

# Need to sleep 1 second otherwise make won't pickup new timestamp
sleep 1
sed -i .bak -f $BASEDIR/META.in.json.sed META.in.json
# TODO: remove once makefile properly handles META.in
make META.json

git commit -am "Test setup"

make pgtap || exit 1

make || exit 1

# vi: expandtab sw=2 ts=2
