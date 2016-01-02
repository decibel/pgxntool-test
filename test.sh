#!/bin/bash

trap 'echo "$BASH_SOURCE: line $LINENO" >&2' ERR
set -o errexit -o errtrace -o pipefail


TEST_TEMPLATE=${TEST_TEMPLATE:-../pgxntool-test-template}
PGXNREPO=${PGXNREPO:-${0%/*}../pgxntool}
if ! echo $PGXNREPO | egrep -q '^(git|https?):'; then
  cd $PGXNREPO
  PGXNREPO=`pwd`
fi

cd ${0%/*} || exit 1 # Make damn certain we know where we're at before rm'ing
rm -rf test

git clone $TEST_TEMPLATE test
cd test
git subtree pull -P pgxntool $PGXNREPO $PGXNBRANCH
pgxntool/setup.sh
git diff
git commit -am "Test setup"



# vi: expandtab sw=2 ts=2
