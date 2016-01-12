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

out () {
  echo '######################################'
  echo $*
  echo '######################################'
}

TMPDIR=${TMPDIR:-${TEMP:-$TMP}}
TEST_DIR=`mktemp -d -t pgxntool-test.XXXXXX`
[ $? -eq 0 ] || exit 1
trap "echo PTD='$TEST_DIR'" EXIT

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

# Copy stuff from template to where it normally lives
cp -R t/* .

# Add extension as a dep
echo 'CREATE EXTENSION "pgxntool-test";' >> test/deps.sql

make || exit 1

make test || exit 1
out Should be clean output

# Mess with output to test make results
echo >> $TEST_DIR/test/expected/pgxntool-test.out
# Need to remove this so the regression test doesn't overwrite expected/pgxntool-test.out
rm -rf $TEST_DIR/test/output

make test
out Should have a diff
make results
make test
out Should be clean output

# vi: expandtab sw=2 ts=2
