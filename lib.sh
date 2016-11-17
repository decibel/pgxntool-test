#!/bin/bash

head_log() {
    echo "$@" 1>&2
    echo $0: head $LOG 1>&2
    head $LOG >&2
    echo $0: END LOG 1>&2
    echo '' 1>&2
}

find_repo () {
  if ! echo $1 | egrep -q '^(git|https?):'; then
    cd $1
    pwd
  fi
}
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
  [ -n "$verbose" -a -z "$verboseout" ] || echo '#' $* >&8
  [ -z "$verbose" ] || echo '######################################'
}

# See http://unix.stackexchange.com/questions/206786/testing-if-a-file-descriptor-is-valid
if ! { true >&8; } 2>&-; then
  # Save stdout & stderr
  exec 8>&1
  exec 9>&2
  if [ -z "$verboseout" ]; then
#wc $LOG
    exec >> $LOG
#wc $LOG >&8
  else
    # Redirect STDOUT to a subproc http://stackoverflow.com/questions/3173131/redirect-copy-of-stdout-to-log-file-from-within-bash-script-itself
    exec > >(tee -ai $LOG)
  fi

  # Always have errors go to both places
  exec 2> >(tee -ai $LOG >&9)
fi

trap "echo PTD='$TEST_DIR' >&2; echo LOG='$LOG' >&2" EXIT

#head_log 'from lib.sh'

# vi: expandtab sw=2 ts=2
