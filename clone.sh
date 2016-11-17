#!/bin/bash

trap 'echo "$BASH_SOURCE: line $LINENO" >&2' ERR
set -o errexit -o errtrace -o pipefail

BASEDIR=`cd ${0%/*}; pwd`

. $BASEDIR/.env
. $BASEDIR/lib.sh

PGXNBRANCH=${PGXNBRANCH:-${1:-master}}
PGXNREPO=${PGXNREPO:-${2:-$BASEDIR/../pgxntool}}
TEST_TEMPLATE=${TEST_TEMPLATE:-${0%/*}/../pgxntool-test-template}

PGXNREPO=`find_repo $PGXNREPO`
TEST_TEMPLATE=`find_repo $TEST_TEMPLATE`

# Need to do this so that make dist isn't cluttering up a higher level directory
TEST_DIR=$TEST_DIR/repo
mkdir $TEST_DIR || exit 1

out Cloning tree
git clone $TEST_TEMPLATE $TEST_DIR 2>&9 # Need to redirect this to avoid cruft in log
cd $TEST_DIR

{
  # Before we do anything else, change origin to something BS so we don't accidentally screw up the real test repo
  git init --bare ../fake_repo > /dev/null
  git remote remove origin
  git remote add origin ../fake_repo
  git push --set-upstream origin master
} 2>&1 # Git is damn chatty...

out Doing subtree add
git subtree add -P pgxntool --squash $PGXNREPO $PGXNBRANCH 2>&1

# If we don't turn this off we get cruft in the log
trap - EXIT

#head_log after setup

# vi: expandtab sw=2 ts=2
