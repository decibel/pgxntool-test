#!/bin/bash

trap 'echo "ERROR: $BASH_SOURCE: line $LINENO" >&2' ERR
set -o errexit -o errtrace -o pipefail
#set -o xtrace -o verbose

if [ "$1" == "-v" ]; then
  verboseout=1
  shift
fi
BASEDIR=`cd ${0%/*}; pwd`

. $BASEDIR/.env
#wc $LOG
. $BASEDIR/lib.sh
#wc $LOG >&8

PGXNBRANCH=${PGXNBRANCH:-${1:-master}}
PGXNREPO=${PGXNREPO:-${2:-$BASEDIR/../pgxntool}}

DISTRIBUTION_NAME=distribution_test
EXTENSION_NAME=pgxntool-test # TODO: rename to something less likely to conflict

PG_LOCATION=`pg_config --bindir | sed 's#/bin##'`

PGXNREPO=`find_repo $PGXNREPO`


# Need to do this so that make dist isn't cluttering up a higher level directory
TEST_DIR=$TEST_DIR/repo

#./clone.sh "$PGXNBRANCH" "$PGXNREPO"

cd $TEST_DIR

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

out git commit
git commit -am "Test setup"

out Verify changing META.in.json works
# Need to sleep 1 second otherwise make won't pickup new timestamp
sleep 1
sed -i '' -e "s/DISTRIBUTION_NAME/$DISTRIBUTION_NAME/" -e "s/EXTENSION_NAME/$EXTENSION_NAME/" META.in.json
out -v This make will produce a bogus '"already up to date"' message for some reason
make
git commit -am "Change META"

# Note: It's easier to do this now than when the checkout is all cluttered
out Test creating a release
make dist
unzip -l ../$DISTRIBUTION_NAME-0.1.0.zip | grep .asc | awk '{print $4}'
# grep exits with 1 if it can't find anything
out Making sure ONLY TEST_DOC.asc is in the distribution
unzip -l ../$DISTRIBUTION_NAME-0.1.0.zip | grep TEST_DOC.asc | awk '{print $4}'
[ `unzip -l ../$DISTRIBUTION_NAME-0.1.0.zip | grep -c .asc` -eq 1 ] || exit 1

out "Run setup.sh again to verify it doesn't over-write things"
pgxntool/setup.sh
git diff --exit-code

out Copy stuff from template to where it normally lives
cp -R t/* .

out Add extension to deps.sql
quote='"'
sed -i '' -e "s/CREATE EXTENSION \.\.\..*/CREATE EXTENSION ${quote}$EXTENSION_NAME${quote};/" test/deps.sql

out Make certain test/output gets created
[ ! -e $TEST_DIR/test/output ] || (out "ERROR! test/output directory should not exist!"; exit 1)
make test # TODO: ensure this exits non-zero
[ -e $TEST_DIR/test/output ] || (out "ERROR! test/output directory does not exist!"; exit 1)
[ -d $TEST_DIR/test/output ] || (out "ERROR! test/output is not a directory!"; exit 1)

out And copy expected output file to output dir that should now exist
cp $BASEDIR/pgxntool-test.source test/output

out Run make test again
make test || exit 1
out -v ^^^ Should be clean output ^^^

out Remove input and output directories, make sure output is not recreated
rm -rf $TEST_DIR/test/input $TEST_DIR/test/output
make test
[ ! -e $TEST_DIR/test/output ] || (out "ERROR! test/output directory exists!"; exit 1)

# Mess with output to test make results
echo >> $TEST_DIR/test/expected/pgxntool-test.out

out Test make results
make test
out -v ^^^ Should have a diff ^^^
make results
make test
out -v ^^^ Should be clean output, BUT NOTE THERE WILL BE A FAILURE DIRECTLY ABOVE! ^^^

# Restore stdout and close FD #8. Ditto with stderr
exec >&8 8>&-
#exec 2>&9 9>&-

cp $BASEDIR/expected.sed $TEST_DIR/
if [ `psql -qtc "SELECT current_setting('server_version_num')::int < 90200"` == t ]; then
  echo "s!rm -f  sql/pgxntool-test--0.1.0.sql!rm -rf  sql/pgxntool-test--0.1.0.sql!" >> $TEST_DIR/expected.sed
  echo "s!rm -f ../distribution_test!rm -rf ../distribution_test!" >> $TEST_DIR/expected.sed
fi
# Need to strip out temporary path and git hashes out of the log file. The
# (/private) bit is to filter out some crap OS X adds.
sed -i .bak -E \
  -e "s#(/private)\\\\?$TEST_DIR#@TEST_DIR@#g" \
  -e "s#^git fetch $PGXNREPO $PGXNBRANCH#git fetch @PGXNREPO@ @PGXNBRANCH@#" \
  -e "s#$PG_LOCATION#@PG_LOCATION@#g" \
  -f $TEST_DIR/expected.sed \
  $LOG

# Since diff will exit non-zero if there's a delta, change our error trap
trap "echo 'Unexpected output. Re-run with $0 -v or run'; echo 'cat $LOG.diff'; echo 'to see it.'; echo" ERR
diff -u $BASEDIR/expected.out $LOG > $LOG.diff

echo 
echo All tests successful!
echo

# vi: expandtab sw=2 ts=2
