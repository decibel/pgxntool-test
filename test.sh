#!/bin/bash

trap 'echo "$BASH_SOURCE: line $LINENO" >&2' ERR
set -o errexit -o errtrace -o pipefail
#set -o xtrace -o verbose

if [ "$1" == "-v" ]; then
  verboseout=1
  shift
fi
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
  if [ "$1" == "-v" ]; then
    local verbose=1
    shift
  fi

  # NOTE: Thes MUST be error condition tests (|| instead of &&) or else our ERR trap will fire and we'll exit
  [ -z "$verbose" ] || echo '######################################'
  echo '#' $*

  # If we were passed verbose output then don't output unless in verbose mode.
  # Remember we need to invert everything because of ||
  [ -n "$verbose" -a -z "$verboseout" ] || echo '#' $* >&6
  [ -z "$verbose" ] || echo '######################################'
}

TMPDIR=${TMPDIR:-${TEMP:-$TMP}}
LOG=`mktemp -t pgxntool-test.XXXXXX.log`
[ $? -eq 0 ] || exit 1
TEST_DIR=`mktemp -d -t pgxntool-test.XXXXXX`
[ $? -eq 0 ] || exit 1
trap "echo PTD='$TEST_DIR' >&2; echo LOG='$LOG' >&2" EXIT

# Save stdout
exec 6>&1
if [ -z "$verboseout" ]; then
  exec > $LOG
else
  # Redirect STDOUT to a subproc http://stackoverflow.com/questions/3173131/redirect-copy-of-stdout-to-log-file-from-within-bash-script-itself
  exec > >(tee -i $LOG)
fi

out Cloning tree
git clone $TEST_TEMPLATE $TEST_DIR
cd $TEST_DIR
out Doing subtree add
git subtree add -P pgxntool --squash $PGXNREPO $PGXNBRANCH

out Making checkout dirty
touch garbage
git add garbage
out Verify setup.sh errors out
if pgxntool/setup.sh; then
  echo "setup.sh should have exited non-zero" >&2
  exit 1
fi
git reset HEAD garbage
rm garbage

out Running setup.sh
pgxntool/setup.sh

out -v Status
ls
git status
git diff

# TODO: remove once makefile properly handles META.in
out Initial make produces error for now
# Need to sleep 1 second otherwise make won't pickup new timestamp
sleep 1
sed -i .bak -f $BASEDIR/META.in.json.sed META.in.json
make META.json
# END TODO

out git commit
git commit -am "Test setup"

out "Run setup.sh again to verify it doesn't over-write things"
pgxntool/setup.sh
git diff --exit-code

out Try pulling in pgtap
make pgtap || exit 1

out Copy stuff from template to where it normally lives
cp -R t/* .

out Plain make
make || exit 1

out First make test should fail due to not installing
make test
out -v ^^^ Should FAIL! ^^^

out Add extension to deps.sql
echo 'CREATE EXTENSION "pgxntool-test";' >> test/deps.sql

out Run make test again
make test || exit 1
out -v ^^^ Should be clean output ^^^

# Mess with output to test make results
echo >> $TEST_DIR/test/expected/pgxntool-test.out
# Need to remove this so the regression test doesn't overwrite expected/pgxntool-test.out
rm -rf $TEST_DIR/test/output

out Test make results
make test
out -v ^^^ Should have a diff ^^^
make results
make test
out -v ^^^ Should be clean output, BUT NOTE THERE WILL BE A FAILURE DIRECTLY ABOVE! ^^^

# Restore stdout and close FD #6
exec >&6 6>&-

# Need to strip out temporary path and git hashes out of the log file. The
# (/private) bit is to filter out some crap OS X adds. The last expression
# strips timestamps from the diff header.
sed -i .bak -E -e "s#(/private)\\\\?$TEST_DIR#@TEST_DIR@#g" \
  -e 's/^[master [0-9a-f]+] Test setup/@GIT COMMIT@/' \
  -e 's/(@TEST_DIR@[^[:space:]]*).*:.*:.*/\1/' \
  -e "s#^git fetch $PGXNREPO $PGXNBRANCH#git fetch @PGXNREPO@ @PGXNBRANCH@#" \
  $LOG

# Since diff will exit non-zero if there's a delta, change our error trap
trap "echo 'Unexpected output. Re-run with $0 -v or run'; echo 'cat $LOG.diff'; echo 'to see it.'; echo" ERR
diff -u $BASEDIR/expected.out $LOG > $LOG.diff

echo 
echo All tests successful!
echo

# vi: expandtab sw=2 ts=2
